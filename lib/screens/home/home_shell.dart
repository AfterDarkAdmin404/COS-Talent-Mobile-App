import 'package:flutter/material.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'profile_view_screen.dart';
import 'jobs_browse_screen.dart';
import '../messages/messages_screen.dart';
import 'account_screen.dart';
import 'notifications_screen.dart';

/// Everything a candidate can reach post-login. The Jobs tab (published
/// postings, apply from there) is the one candidate-initiated contact this
/// app allows — Messages stays a single thread with COS staff, not a
/// per-employer inbox, since every OTHER employer contact stays
/// staff-brokered (threat-model.md:245). Applying to a specific posted role
/// is a different interaction than that brokered-introduction model, by
/// design of the job_applications table itself (038).
///
/// Every tab reads the profile from the shared `ProfileBloc` (provided at
/// app root in `main.dart`) instead of taking it as a constructor
/// parameter — that's what lets `ProfileViewScreen` pick up an edit made
/// in the wizard without any manual refresh plumbing.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;
  // Built once, not inline in build() -- `.stream()` opens a new realtime
  // channel every call, and build() reruns on every tab switch.
  late final Stream<int> _unreadCountStream;

  @override
  void initState() {
    super.initState();
    _unreadCountStream = NotificationService.streamUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    final screens = const [
      DashboardScreen(),
      ProfileViewScreen(),
      JobsBrowseScreen(),
      MessagesScreen(),
      AccountScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        backgroundColor: AppColors.offWhite,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('Cos Talent'),
        actions: [
          StreamBuilder<int>(
            stream: _unreadCountStream,
            builder: (context, snapshot) => IconButton(
              tooltip: 'Notifications',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              ),
              icon: Badge(
                isLabelVisible: (snapshot.data ?? 0) > 0,
                label: Text('${snapshot.data}'),
                backgroundColor: AppColors.teal,
                child: const Icon(Icons.notifications_outlined, color: AppColors.navy),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(bottom: false, child: screens[_tab]),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: AppColors.white,
          indicatorColor: AppColors.teal.withValues(alpha: 0.14),
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: states.contains(WidgetState.selected)
                  ? AppColors.navy
                  : AppColors.muted,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() => _tab = i),
          elevation: 0,
          height: 66,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.dashboard_outlined, color: AppColors.muted),
              selectedIcon: Icon(Icons.dashboard, color: AppColors.navy),
              label: 'Home',
            ),
            const NavigationDestination(
              icon: Icon(Icons.badge_outlined, color: AppColors.muted),
              selectedIcon: Icon(Icons.badge, color: AppColors.navy),
              label: 'Profile',
            ),
            const NavigationDestination(
              icon: Icon(Icons.work_outline, color: AppColors.muted),
              selectedIcon: Icon(Icons.work, color: AppColors.navy),
              label: 'Jobs',
            ),
            NavigationDestination(
              icon: StreamBuilder<int>(
                stream: _unreadCountStream,
                builder: (context, snapshot) => Badge(
                  isLabelVisible: (snapshot.data ?? 0) > 0,
                  label: Text('${snapshot.data}'),
                  backgroundColor: AppColors.teal,
                  child: const Icon(Icons.chat_bubble_outline, color: AppColors.muted),
                ),
              ),
              selectedIcon: const Icon(Icons.chat_bubble, color: AppColors.navy),
              label: 'Messages',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline, color: AppColors.muted),
              selectedIcon: Icon(Icons.person, color: AppColors.navy),
              label: 'Account',
            ),
          ],
        ),
      ),
    );
  }
}
