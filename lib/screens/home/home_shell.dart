import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'profile_view_screen.dart';
import '../messages/messages_screen.dart';
import 'activity_screen.dart';
import 'account_screen.dart';

/// Everything a candidate can reach post-login. Still no "Jobs" tab —
/// PLAN.md defers employer accounts and job postings past Phase 1 — but
/// Messages is here as a single thread with COS staff, not a per-employer
/// inbox: every employer contact stays staff-brokered
/// (threat-model.md:245), so there is nothing here for the candidate to
/// browse or reply to directly.
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

  @override
  Widget build(BuildContext context) {
    final screens = const [
      DashboardScreen(),
      ProfileViewScreen(),
      MessagesScreen(),
      ActivityScreen(),
      AccountScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.offWhite,
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
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined, color: AppColors.muted),
              selectedIcon: Icon(Icons.dashboard, color: AppColors.navy),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.badge_outlined, color: AppColors.muted),
              selectedIcon: Icon(Icons.badge, color: AppColors.navy),
              label: 'Profile',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline, color: AppColors.muted),
              selectedIcon: Icon(Icons.chat_bubble, color: AppColors.navy),
              label: 'Messages',
            ),
            NavigationDestination(
              icon: Icon(Icons.insights_outlined, color: AppColors.muted),
              selectedIcon: Icon(Icons.insights, color: AppColors.navy),
              label: 'Activity',
            ),
            NavigationDestination(
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
