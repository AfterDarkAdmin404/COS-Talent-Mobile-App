import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/profile/profile_bloc.dart';
import '../../blocs/profile/profile_state.dart';
import '../../data/mock_data.dart';
import '../../models/talent_profile.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/brand_card.dart';
import '../../widgets/pill_chip.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  Color _statusColor(ProfileStatus s) => switch (s) {
    ProfileStatus.draft => AppColors.statusDraft,
    ProfileStatus.pendingReview => AppColors.statusPending,
    ProfileStatus.approved => AppColors.statusApproved,
    ProfileStatus.rejected => AppColors.statusRejected,
    ProfileStatus.suspended => AppColors.statusRejected,
  };

  String _statusBody(TalentProfile profile) => switch (profile.status) {
    ProfileStatus.draft => 'Finish your profile so a COS reviewer can take a look.',
    ProfileStatus.pendingReview =>
      'A COS staff member is reviewing your profile. This usually takes 1–2 business days.',
    ProfileStatus.approved => profile.isPublic
        ? 'Your profile is live. Employers COS introduces you to can see your full details.'
        : 'You\'re approved — publish your profile from the Profile tab to go live.',
    ProfileStatus.rejected => 'A reviewer left notes on your profile. Head to Profile to see what to update.',
    ProfileStatus.suspended => 'Your profile has been suspended. Contact the COS team for details.',
  };

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        final profile = state.profile!;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hi ${profile.firstName.isEmpty ? 'there' : profile.firstName} 👋',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 24),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Here\'s where things stand.',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.navy.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                    image: profile.photoPath != null
                        ? DecorationImage(
                            image: NetworkImage(StorageService.photoPublicUrl(profile.photoPath!)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: profile.photoPath == null
                      ? const Icon(Icons.person_outline, color: AppColors.navy)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 20),
            BrandCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      StatusBadge(
                        label: profile.status.label,
                        color: _statusColor(profile.status),
                      ),
                      const Spacer(),
                      if (profile.status == ProfileStatus.approved && profile.isPublic)
                        const StatusBadge(label: 'LIVE', color: AppColors.teal),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _statusBody(profile),
                    style: const TextStyle(fontSize: 13.5, height: 1.45, color: AppColors.ink),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: profile.profileCompleteness / 100,
                            minHeight: 8,
                            backgroundColor: AppColors.border,
                            color: AppColors.teal,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${profile.profileCompleteness}%',
                        style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Quick stats', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _statTile(
                    icon: Icons.visibility_outlined,
                    value: profile.isPublic ? '${kDemoActivity.profileViews30d}' : '—',
                    label: 'Profile views (30d)',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statTile(
                    icon: Icons.download_outlined,
                    value: profile.isPublic ? '${kDemoActivity.resumeDownloads30d}' : '—',
                    label: 'Resume downloads',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('What happens next', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 10),
            _timelineTile(
              done: true,
              title: 'Profile submitted',
              subtitle: 'You built your profile and sent it for review',
            ),
            _timelineTile(
              done: profile.status != ProfileStatus.draft && profile.status != ProfileStatus.pendingReview,
              active: profile.status == ProfileStatus.pendingReview,
              title: 'Staff review',
              subtitle: 'A COS team member checks your details and English level',
            ),
            _timelineTile(
              done: profile.isPublic,
              active: profile.status == ProfileStatus.approved && !profile.isPublic,
              title: 'You publish',
              subtitle: 'Your choice — nothing goes public without your say-so',
            ),
            _timelineTile(
              done: false,
              title: 'Introductions',
              subtitle: 'COS staff broker the conversation when there\'s a match',
              isLast: true,
            ),
          ],
        );
      },
    );
  }

  Widget _statTile({required IconData icon, required String value, required String label}) {
    return BrandCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.tealDark, size: 20),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.navy)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
        ],
      ),
    );
  }

  Widget _timelineTile({
    required bool done,
    bool active = false,
    required String title,
    required String subtitle,
    bool isLast = false,
  }) {
    final color = done ? AppColors.teal : (active ? AppColors.navy : AppColors.border);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Icon(
                  done ? Icons.check : (active ? Icons.more_horiz : Icons.circle),
                  size: done || active ? 14 : 8,
                  color: AppColors.white,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: AppColors.border),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
