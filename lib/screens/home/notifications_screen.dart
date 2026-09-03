import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/notification_item.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/brand_card.dart';
import '../messages/application_thread_screen.dart';
import '../messages/direct_message_thread_screen.dart';

/// The bell-icon feed: every notification (044), most recent first.
/// Tapping one opens the underlying conversation, which is what actually
/// clears it (each thread screen's own `markThreadRead` call, not this
/// screen) — same division of labor as the Messages tab's inbox list.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<NotificationItem>> _future;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _future = NotificationService.fetchAll();
    // The joined counterpart name isn't expressible through `.stream()` --
    // this is just a "something changed" ping, same posture as the
    // Messages inbox's own channel.
    _channel = Supabase.instance.client
        .channel('talent-notifications')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          callback: (_) => _reload(),
        )
        .subscribe();
  }

  void _reload() => setState(() {
    _future = NotificationService.fetchAll();
  });

  @override
  void dispose() {
    final channel = _channel;
    if (channel != null) unawaited(Supabase.instance.client.removeChannel(channel));
    super.dispose();
  }

  Future<void> _open(NotificationItem n) async {
    if (n.threadKind == 'application') {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ApplicationThreadScreen(jobApplicationId: n.jobApplicationId!, companyName: n.companyName),
        ),
      );
    } else {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DirectMessageThreadScreen(
            employerCompanyId: n.employerCompanyId!,
            companyName: n.companyName,
          ),
        ),
      );
    }
    if (!mounted) return;
    _reload();
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
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(title: const Text('Notifications')),
      body: SafeArea(
        child: FutureBuilder<List<NotificationItem>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'Couldn\'t load notifications. ${snapshot.error}',
                    style: const TextStyle(color: AppColors.statusRejected),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            final items = snapshot.data ?? const [];
            if (items.isEmpty) {
              return Center(
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
                        child: const Icon(Icons.notifications_none, size: 32, color: AppColors.muted),
                      ),
                      const SizedBox(height: 18),
                      Text('No notifications yet', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      const Text(
                        'When an employer messages you, it shows up here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.muted, fontSize: 13.5, height: 1.4),
                      ),
                    ],
                  ),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final n = items[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: BrandCard(
                    onTap: () => _open(n),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!n.isRead)
                          Padding(
                            padding: const EdgeInsets.only(top: 5, right: 10),
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(color: AppColors.teal, shape: BoxShape.circle),
                            ),
                          ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      n.companyName,
                                      style: TextStyle(
                                        fontWeight: n.isRead ? FontWeight.w600 : FontWeight.w800,
                                        fontSize: 14.5,
                                      ),
                                    ),
                                  ),
                                  Text(_relativeTime(n.createdAt), style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                n.bodyPreview,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13, color: AppColors.ink),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
