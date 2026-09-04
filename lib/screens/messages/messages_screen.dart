import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/chat_message.dart';
import '../../models/direct_message_thread_summary.dart';
import '../../models/message_thread_summary.dart';
import '../../services/direct_message_service.dart';
import '../../services/message_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/brand_card.dart';
import 'application_thread_screen.dart';
import 'direct_message_thread_screen.dart';

/// One row of the merged inbox this screen renders — either an
/// application-scoped thread (041) or a direct one (042). The two are
/// backed by different tables with no shared row shape, so this is a thin
/// display-only wrapper built fresh each load rather than a change to
/// either underlying model.
class _InboxItem {
  final String title;
  final String subtitle;
  final ChatMessage lastMessage;
  final Future<void> Function(BuildContext) openThread;

  const _InboxItem({
    required this.title,
    required this.subtitle,
    required this.lastMessage,
    required this.openThread,
  });

  factory _InboxItem.fromApplication(MessageThreadSummary t) => _InboxItem(
    title: t.companyName,
    subtitle: 'Re: ${t.jobTitle}',
    lastMessage: t.lastMessage!,
    openThread: (context) => Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ApplicationThreadScreen(jobApplicationId: t.jobApplicationId, companyName: t.companyName),
      ),
    ),
  );

  factory _InboxItem.fromDirect(DirectMessageThreadSummary t) => _InboxItem(
    title: t.companyName,
    subtitle: 'Direct message',
    lastMessage: t.lastMessage!,
    openThread: (context) => Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DirectMessageThreadScreen(employerCompanyId: t.employerCompanyId, companyName: t.companyName),
      ),
    ),
  );
}

/// Real conversations with employers — application-scoped threads
/// (`message_threads`, 041) merged with direct ones (`direct_message_threads`,
/// 042), most-recently-active first, scoped to this candidate's own account.
/// Replaces the earlier single hardcoded "COS staff" thread, which had
/// nothing real behind it.
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  late Future<List<_InboxItem>> _future;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _future = _load();
    // Neither table's joined summary shape is expressible through
    // `.stream()` (company names, job titles) -- this is just a "something
    // changed" ping, RLS narrows to rows this account could already SELECT.
    // Requires 043 (enables replication on both tables).
    _channel = Supabase.instance.client
        .channel('talent-inbox')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (_) => _reload(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'direct_messages',
          callback: (_) => _reload(),
        )
        .subscribe();
  }

  Future<List<_InboxItem>> _load() async {
    final applicationThreads = await MessageService.fetchMyThreads();
    final directThreads = await DirectMessageService.fetchMyThreads();
    final items = [
      ...applicationThreads.map(_InboxItem.fromApplication),
      ...directThreads.map(_InboxItem.fromDirect),
    ];
    items.sort((a, b) => b.lastMessage.time.compareTo(a.lastMessage.time));
    return items;
  }

  void _reload() => setState(() {
    _future = _load();
  });

  @override
  void dispose() {
    final channel = _channel;
    if (channel != null) unawaited(Supabase.instance.client.removeChannel(channel));
    super.dispose();
  }

  String _relativeTime(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inDays >= 1) return '${diff.inDays}d';
    if (diff.inHours >= 1) return '${diff.inHours}h';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m';
    return 'now';
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: AppColors.offWhite,
          surfaceTintColor: Colors.transparent,
          pinned: true,
          title: const Text('Messages'),
        ),
        FutureBuilder<List<_InboxItem>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'Couldn\'t load your messages. ${snapshot.error}',
                      style: const TextStyle(color: AppColors.statusRejected),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }
            final items = snapshot.data ?? const [];
            if (items.isEmpty) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: AppColors.navy.withValues(alpha: 0.06),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.chat_bubble_outline, size: 32, color: AppColors.muted),
                        ),
                        const SizedBox(height: 18),
                        Text('No conversations yet', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        const Text(
                          'When an employer messages you, or messages you about an application, it shows up here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.muted, fontSize: 13.5, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, i) {
                  final item = items[i];
                  final last = item.lastMessage;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: BrandCard(
                      onTap: () async {
                        await item.openThread(context);
                        _reload();
                      },
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: const BoxDecoration(
                              color: AppColors.offWhite,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.apartment_outlined, color: AppColors.muted),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                                ),
                                Text(
                                  item.subtitle,
                                  style: const TextStyle(color: AppColors.muted, fontSize: 11.5),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  // Always non-null here: MessageThreadSummary/
                                  // DirectMessageThreadSummary synthesize a
                                  // preview string (e.g. "📷 Photo") for an
                                  // attachment-only row, so this is never the
                                  // model's raw nullable `body`.
                                  last.fromMe ? 'You: ${last.text!}' : last.text!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13, color: AppColors.ink),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(_relativeTime(last.time), style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                        ],
                      ),
                    ),
                  );
                }, childCount: items.length),
              ),
            );
          },
        ),
      ],
    );
  }
}
