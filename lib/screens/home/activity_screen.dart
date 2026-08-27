import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/profile/profile_bloc.dart';
import '../../blocs/profile/profile_state.dart';
import '../../data/mock_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/brand_card.dart';

/// Reads from `talent_access_events` (PLAN.md A4: "build the meter, not
/// the engine") — per-actor view/download counters. This is the whole
/// entitlement system in Phase 1: a meter, not a paywall.
class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        if (!state.profile!.isPublic) {
          return _emptyState(context);
        }
        return _content(context);
      },
    );
  }

  Widget _content(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        Text('Activity', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 24)),
        const SizedBox(height: 4),
        const Text('Last 30 days', style: TextStyle(color: AppColors.muted)),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _metric(
                icon: Icons.visibility_outlined,
                value: '${kDemoActivity.profileViews30d}',
                label: 'Profile views',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _metric(
                icon: Icons.search,
                value: '${kDemoActivity.searchAppearances30d}',
                label: 'Search appearances',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _metric(
          icon: Icons.download_outlined,
          value: '${kDemoActivity.resumeDownloads30d}',
          label: 'Resume downloads by staff-verified employers',
          wide: true,
        ),
        const SizedBox(height: 22),
        BrandCard(
          color: AppColors.navy.withValues(alpha: 0.03),
          child: const Row(
            children: [
              Icon(Icons.verified_user_outlined, color: AppColors.navyLight, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Every staff read of your full profile or resume is logged, '
                  'not just counted here.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.navyLight, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _metric({required IconData icon, required String value, required String label, bool wide = false}) {
    return BrandCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.tealDark, size: 22),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.navy)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
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
              child: const Icon(Icons.insights_outlined, size: 32, color: AppColors.muted),
            ),
            const SizedBox(height: 18),
            Text(
              'Nothing to show yet',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Activity appears here once your profile is approved and published.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 13.5, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
