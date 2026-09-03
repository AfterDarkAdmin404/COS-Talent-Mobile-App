import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_message.dart';
import '../models/message_thread_summary.dart';

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

  static ChatMessage _messageFromRow(Map<String, dynamic> r) => ChatMessage(
    text: r['body'] as String,
    fromMe: r['sender_kind'] == 'candidate',
    time: DateTime.parse(r['created_at'] as String),
  );

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
          messages(body, sender_kind, created_at)
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
