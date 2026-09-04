import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_message.dart';
import '../models/message_thread_summary.dart';
import 'storage_service.dart';

/// Reads and writes `public.message_threads` / `public.messages`
/// (bookkeeping/database/migrations/041_create_application_messaging.sql) —
/// messaging scoped to one job application, not a general employer↔candidate
/// DM system. See that migration's header for why this is a bounded
/// exception to the brokered-contact model this app otherwise follows
/// (threat-model.md:245) rather than a reversal of it: a candidate can only
/// have a real conversation with an employer she has actually applied to.
class MessageService {
  MessageService._();
  static final _client = Supabase.instance.client;

  static Future<int> _getOrCreateThreadId(int jobApplicationId) async {
    final existing = await _client
        .from('message_threads')
        .select('id')
        .eq('job_application_id', jobApplicationId)
        .maybeSingle();
    if (existing != null) return existing['id'] as int;
    final created = await _client
        .from('message_threads')
        .insert({'job_application_id': jobApplicationId})
        .select('id')
        .single();
    return created['id'] as int;
  }

  /// `null` when nobody has sent a first message yet — there is no thread
  /// row to find. Read-only, unlike [_getOrCreateThreadId]: for a screen
  /// that needs to know whether a live stream can start yet, without
  /// creating a thread just by looking.
  static Future<int?> findThreadId(int jobApplicationId) async {
    final thread = await _client
        .from('message_threads')
        .select('id')
        .eq('job_application_id', jobApplicationId)
        .maybeSingle();
    return thread == null ? null : thread['id'] as int;
  }

  /// Empty list, not an error, when nobody has sent a first message yet.
  static Future<List<ChatMessage>> fetchMessages(int jobApplicationId) async {
    final threadId = await findThreadId(jobApplicationId);
    if (threadId == null) return [];
    final rows = await _client
        .from('messages')
        .select()
        .eq('thread_id', threadId)
        // postgrest's .order() defaults to ascending: false (newest
        // first) -- explicit here so the oldest message renders at the
        // top of the list and the newest at the bottom, like a real chat.
        .order('created_at', ascending: true);
    return (rows as List).cast<Map<String, dynamic>>().map(_messageFromRow).toList();
  }

  /// Live view of one thread's messages — re-emits the full ordered list on
  /// every insert Realtime delivers (043 enables replication on `messages`;
  /// RLS still scopes which rows actually reach this subscriber). `.order()`
  /// on the stream builder defaults to `ascending: false`, the opposite of
  /// the plain query above -- `ascending: true` is explicit here for the
  /// same "oldest at top" reason.
  static Stream<List<ChatMessage>> streamMessages(int threadId) {
    return _client
        .from('messages')
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

  /// Returns the thread id — lets the caller start (or confirm) a live
  /// [streamMessages] subscription right after the first send, instead of
  /// re-fetching.
  static Future<int> sendAsCandidate({required int jobApplicationId, required String body}) async {
    final trimmed = body.trim();
    if (trimmed.isEmpty) throw ArgumentError('body must not be empty');
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('Not signed in.');
    final threadId = await _getOrCreateThreadId(jobApplicationId);
    await _client.from('messages').insert({
      'thread_id': threadId,
      'sender_kind': 'candidate',
      'sender_marketplace_user_id': userId,
      'body': trimmed,
    });
    return threadId;
  }

  /// Same shape as [sendAsCandidate] but for a message that is an
  /// attachment instead of text (046). Resolves/creates the thread first
  /// (the storage path needs a real thread id -- see
  /// `StorageService.uploadMessageAttachment`), then uploads, then inserts.
  /// On an insert failure after a successful upload, this best-effort
  /// deletes the now-orphaned object before rethrowing, same posture as
  /// this app's other best-effort writes (e.g. `job_application_events`
  /// audit rows).
  static Future<int> sendAttachmentAsCandidate({
    required int jobApplicationId,
    required File file,
    required ChatAttachmentKind kind,
    required String fileName,
    required String mimeType,
    required int sizeBytes,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('Not signed in.');
    final threadId = await _getOrCreateThreadId(jobApplicationId);
    final storagePath = await StorageService.uploadMessageAttachment(
      threadKind: 'application',
      threadId: threadId,
      file: file,
    );
    try {
      await _client.from('messages').insert({
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

  /// Changes [messageId]'s text -- 048's `messages_update_own` RLS scopes
  /// this to the caller's own messages, and `set_messages_edited_at`
  /// server-stamps `edited_at`. Only ever called on a text message; the
  /// screen only offers Edit when `message.attachment == null`.
  static Future<void> editMessage({required int messageId, required String body}) async {
    final trimmed = body.trim();
    if (trimmed.isEmpty) throw ArgumentError('body must not be empty');
    await _client.from('messages').update({'body': trimmed}).eq('id', messageId);
  }

  /// Soft-deletes [message] -- see 048's header for why this is a
  /// tombstone (clears content, sets `deleted_at`) rather than a real row
  /// DELETE. If it was an attachment, best-effort removes the now-orphaned
  /// Storage object too; a failure there is logged, not surfaced, same
  /// posture as [sendAttachmentAsCandidate]'s upload-cleanup.
  static Future<void> deleteMessage(ChatMessage message) async {
    await _client
        .from('messages')
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

  /// Every thread `message_threads_select_candidate` (041) lets this
  /// account see — every application thread of hers that has at least one
  /// message. Most-recently-active first.
  static Future<List<MessageThreadSummary>> fetchMyThreads() async {
    final rows = await _client
        .from('message_threads')
        .select('''
          id, job_application_id,
          job_applications(
            job_postings(title, employer_companies(company_name))
          ),
          messages(id, body, sender_kind, created_at, deleted_at, attachment_kind, attachment_file_name)
        ''')
        .order('created_at', referencedTable: 'messages', ascending: false)
        .limit(1, referencedTable: 'messages');
    final summaries = (rows as List)
        .map((r) => MessageThreadSummary.fromRow(r as Map<String, dynamic>))
        .where((s) => s.lastMessage != null)
        .toList();
    summaries.sort((a, b) => b.lastMessage!.time.compareTo(a.lastMessage!.time));
    return summaries;
  }
}
