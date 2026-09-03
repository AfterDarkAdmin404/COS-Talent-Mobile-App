import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_item.dart';

/// Reads `public.notifications` (044) — read/unread tracking for the two
/// messaging systems (041, 042). Rows are created only by a server-side
/// trigger on `messages`/`direct_messages`, never by this app; there is no
/// `create`/`send` method here on purpose. See 044's header for why.
class NotificationService {
  NotificationService._();
  static final _client = Supabase.instance.client;

  /// Live unread count for the signed-in account — re-emits on every
  /// realtime change (044 enables replication on `notifications`; RLS
  /// still scopes to this account's own rows). `Stream.value(0)` when
  /// signed out, matching how HomeShell is only ever reachable signed in.
  static Stream<int> streamUnreadCount() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return Stream.value(0);
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('recipient_marketplace_user_id', userId)
        .map((rows) => rows.where((r) => r['is_read'] == false).length);
  }

  /// The notification feed, most recent first. A plain one-time fetch (not
  /// `.stream()`, unlike [streamUnreadCount]) since the counterpart's name
  /// needs an embedded join `.stream()` can't express — the notifications
  /// screen pings a realtime channel itself to refetch instead, same
  /// "join-heavy list = plain fetch + channel ping" posture
  /// `MessagesScreen._load()`/`_reload()` already uses.
  static Future<List<NotificationItem>> fetchAll() async {
    final rows = await _client
        .from('notifications')
        .select('''
          id, thread_kind, body_preview, is_read, created_at,
          message_threads(
            job_application_id,
            job_applications(job_postings(employer_companies(company_name)))
          ),
          direct_message_threads(
            employer_company_id,
            employer_companies(company_name)
          )
        ''')
        .order('created_at', ascending: false)
        .limit(50);
    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map(NotificationItem.fromRow)
        .toList();
  }

  /// Best-effort: clears unread notifications for one thread once it's
  /// opened. RLS already scopes the update to the caller's own rows, same
  /// posture `fetchMyThreads()` already relies on for reads.
  static Future<void> markThreadRead({required String threadKind, required int threadId}) async {
    final column = threadKind == 'application' ? 'application_thread_id' : 'direct_thread_id';
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('thread_kind', threadKind)
        .eq(column, threadId)
        .eq('is_read', false);
  }
}
