import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_message.dart';
import '../models/direct_message_thread_summary.dart';
import 'storage_service.dart';

/// Reads and writes `public.direct_message_threads` / `public.direct_messages`
/// (042) — direct employer<->candidate messaging, independent of any job
/// application. Unlike [MessageService], the employer side can open one of
/// these with any published, staff-approved candidate from Browse Talent,
/// not just someone who applied to a posting. See 042's header for why
/// that's a deliberate, informed reversal of the staff-brokered contact
/// model, not an accident.
class DirectMessageService {
  DirectMessageService._();
  static final _client = Supabase.instance.client;

  static Future<int> _getOrCreateThreadId({
    required int employerCompanyId,
    required int talentProfileId,
  }) async {
    final existing = await _client
        .from('direct_message_threads')
        .select('id')
        .eq('employer_company_id', employerCompanyId)
        .eq('talent_profile_id', talentProfileId)
        .maybeSingle();
    if (existing != null) return existing['id'] as int;
    final created = await _client
        .from('direct_message_threads')
        .insert({'employer_company_id': employerCompanyId, 'talent_profile_id': talentProfileId})
        .select('id')
        .single();
    return created['id'] as int;
  }

  /// `null` when nobody has sent a first message yet — there is no thread
  /// row to find. Read-only, unlike [_getOrCreateThreadId]: for a screen
  /// that needs to know whether a live stream can start yet, without
  /// creating a thread just by looking.
  static Future<int?> findThreadId({required int employerCompanyId, required int talentProfileId}) async {
    final thread = await _client
        .from('direct_message_threads')
        .select('id')
        .eq('employer_company_id', employerCompanyId)
        .eq('talent_profile_id', talentProfileId)
        .maybeSingle();
    return thread == null ? null : thread['id'] as int;
  }

  /// Empty list, not an error, when nobody has sent a first message yet —
  /// there is no thread row to find.
  static Future<List<ChatMessage>> fetchMessages({
    required int employerCompanyId,
    required int talentProfileId,
  }) async {
    final threadId = await findThreadId(employerCompanyId: employerCompanyId, talentProfileId: talentProfileId);
    if (threadId == null) return [];
    final rows = await _client
        .from('direct_messages')
        .select()
        .eq('thread_id', threadId)
        .order('created_at', ascending: true);
    return (rows as List).cast<Map<String, dynamic>>().map(_messageFromRow).toList();
  }

  /// Live view of one thread's messages — re-emits the full ordered list on
  /// every insert Realtime delivers (043 enables replication on
  /// `direct_messages`; RLS still scopes which rows actually reach this
  /// subscriber). `.order()` on the stream builder defaults to `ascending:
  /// false`, the opposite of the plain query above -- `ascending: true` is
  /// explicit here for the same "oldest at top" reason.
  static Stream<List<ChatMessage>> streamMessages(int threadId) {
    return _client
        .from('direct_messages')
        .stream(primaryKey: ['id'])
        .eq('thread_id', threadId)
        .order('created_at', ascending: true)
        .map((rows) => rows.map(_messageFromRow).toList());
  }

  static ChatMessage _messageFromRow(Map<String, dynamic> r) {
    final attachmentPath = r['attachment_storage_path'] as String?;
    return ChatMessage(
      id: r['id'] as int,
      text: r['body'] as String?,
      attachment: attachmentPath == null
          ? null
          : ChatAttachment(
              storagePath: attachmentPath,
              kind: r['attachment_kind'] == 'image' ? ChatAttachmentKind.image : ChatAttachmentKind.file,
              fileName: r['attachment_file_name'] as String,
              mimeType: r['attachment_mime_type'] as String,
              sizeBytes: r['attachment_size_bytes'] as int,
            ),
      fromMe: r['sender_kind'] == 'candidate',
      time: DateTime.parse(r['created_at'] as String),
      editedAt: r['edited_at'] == null ? null : DateTime.parse(r['edited_at'] as String),
      deletedAt: r['deleted_at'] == null ? null : DateTime.parse(r['deleted_at'] as String),
    );
  }

  /// Changes [messageId]'s text -- see `MessageService.editMessage` for
  /// the RLS/trigger rationale.
  static Future<void> editMessage({required int messageId, required String body}) async {
    final trimmed = body.trim();
    if (trimmed.isEmpty) throw ArgumentError('body must not be empty');
    await _client.from('direct_messages').update({'body': trimmed}).eq('id', messageId);
  }

  /// Soft-deletes [message] -- see `MessageService.deleteMessage` for the
  /// tombstone rationale.
  static Future<void> deleteMessage(ChatMessage message) async {
    await _client
        .from('direct_messages')
        .update({
          'body': null,
          'attachment_storage_path': null,
          'attachment_kind': null,
          'attachment_file_name': null,
          'attachment_mime_type': null,
          'attachment_size_bytes': null,
          'deleted_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', message.id);
    final path = message.attachment?.storagePath;
    if (path != null) {
      try {
        await _client.storage.from('message-attachments').remove([path]);
      } catch (e) {
        debugPrint('message-attachments remove($path) failed: $e');
      }
    }
  }

  /// Every direct thread `direct_message_threads_select_candidate` (042)
  /// lets this account see, that has at least one message. Most-recently-
  /// active first.
  static Future<List<DirectMessageThreadSummary>> fetchMyThreads() async {
    final rows = await _client
        .from('direct_message_threads')
        .select('''
          employer_company_id,
          employer_companies(company_name),
          direct_messages(id, body, sender_kind, created_at, deleted_at, attachment_kind, attachment_file_name)
        ''')
        .order('created_at', referencedTable: 'direct_messages', ascending: false)
        .limit(1, referencedTable: 'direct_messages');
    final summaries = (rows as List)
        .map((r) => DirectMessageThreadSummary.fromRow(r as Map<String, dynamic>))
        .where((s) => s.lastMessage != null)
        .toList();
    summaries.sort((a, b) => b.lastMessage!.time.compareTo(a.lastMessage!.time));
    return summaries;
  }

  /// Returns the thread id — lets the caller start (or confirm) a live
  /// [streamMessages] subscription right after the first send, instead of
  /// re-fetching.
  static Future<int> sendAsCandidate({
    required int employerCompanyId,
    required int talentProfileId,
    required String body,
  }) async {
    final trimmed = body.trim();
    if (trimmed.isEmpty) throw ArgumentError('body must not be empty');
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('Not signed in.');
    final threadId = await _getOrCreateThreadId(
      employerCompanyId: employerCompanyId,
      talentProfileId: talentProfileId,
    );
    await _client.from('direct_messages').insert({
      'thread_id': threadId,
      'sender_kind': 'candidate',
      'sender_marketplace_user_id': userId,
      'body': trimmed,
    });
    return threadId;
  }

  /// Same shape as [sendAsCandidate] but for a message that is an
  /// attachment instead of text (046) — see `MessageService`'s matching
  /// method for the thread-first-then-upload / best-effort-cleanup
  /// rationale.
  static Future<int> sendAttachmentAsCandidate({
    required int employerCompanyId,
    required int talentProfileId,
    required File file,
    required ChatAttachmentKind kind,
    required String fileName,
    required String mimeType,
    required int sizeBytes,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('Not signed in.');
    final threadId = await _getOrCreateThreadId(
      employerCompanyId: employerCompanyId,
      talentProfileId: talentProfileId,
    );
    final storagePath = await StorageService.uploadMessageAttachment(
      threadKind: 'direct',
      threadId: threadId,
      file: file,
    );
    try {
      await _client.from('direct_messages').insert({
        'thread_id': threadId,
        'sender_kind': 'candidate',
        'sender_marketplace_user_id': userId,
        'attachment_storage_path': storagePath,
        'attachment_kind': kind == ChatAttachmentKind.image ? 'image' : 'file',
        'attachment_file_name': fileName,
        'attachment_mime_type': mimeType,
        'attachment_size_bytes': sizeBytes,
      });
    } catch (_) {
      unawaited(_client.storage.from('message-attachments').remove([storagePath]));
      rethrow;
    }
    return threadId;
  }
}
