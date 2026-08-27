import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/profile/profile_bloc.dart';
import '../../blocs/profile/profile_state.dart';
import '../../models/talent_profile.dart';
import '../../theme/app_theme.dart';
import '../../widgets/brand_card.dart';
import '../../services/storage_service.dart';
import '../../widgets/pill_chip.dart';
import '../profile_setup/profile_setup_flow.dart';

/// The candidate's view of their own profile — annotated with the tier
/// each section belongs to (PLAN.md A3): Tier 1 public, Tier 2
/// authenticated/brokered, Tier 3 staff-only. Nothing here is what an
/// employer sees; it's what the candidate sees about her own visibility.
///
/// Plain `StatelessWidget` on purpose — `BlocBuilder` rebuilds this
/// automatically whenever the shared `ProfileBloc` state changes (e.g.
/// after editing), so there's no manual "await push then setState" needed.
class ProfileViewScreen extends StatelessWidget {
  const ProfileViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        final profile = state.profile!;
        final canPublish = profile.status == ProfileStatus.approved;
        return CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: AppColors.offWhite,
              surfaceTintColor: Colors.transparent,
              pinned: true,
              title: const Text('Your profile'),
              actions: [
                IconButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProfileSetupFlow(existingProfile: profile),
                    ),
                  ),
                  icon: const Icon(Icons.edit_outlined, color: AppColors.navy),
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (canPublish) _publishBanner(context, profile),
                  BrandCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: AppColors.navy.withValues(alpha: 0.06),
                                shape: BoxShape.circle,
                                image: profile.photoPath != null
                                    ? DecorationImage(
                                        image: NetworkImage(
                                          StorageService.photoPublicUrl(profile.photoPath!),
                                        ),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: profile.photoPath == null
                                  ? const Icon(Icons.person_outline, color: AppColors.muted)
                                  : null,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    profile.displayName.isEmpty ? 'Your name' : profile.displayName,
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                                  ),
                                  Text(
                                    profile.professionalTitle.isEmpty
                                        ? 'Add your professional title'
                                        : profile.professionalTitle,
                                    style: const TextStyle(color: AppColors.muted, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            PillChip(
                              icon: Icons.place_outlined,
                              label: profile.city?.isNotEmpty == true
                                  ? '${profile.city}, ${profile.countryName}'
                                  : profile.countryName,
                            ),
                            PillChip(icon: Icons.payments_outlined, label: profile.rateLabel),
                            PillChip(icon: Icons.schedule, label: profile.availability.label),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _tierSection(
                    tier: 1,
                    title: 'Public profile',
                    subtitle: 'Visible to anyone once approved and published',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (profile.summary?.isNotEmpty == true) ...[
                          Text(profile.summary!, style: const TextStyle(fontSize: 13.5, height: 1.5)),
                          const SizedBox(height: 12),
                        ],
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: profile.categories
                              .map((c) => PillChip(label: c.name))
                              .toList(),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: profile.skills
                              .map((s) => PillChip(label: s.name, icon: Icons.bolt))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _tierSection(
                    tier: 2,
                    title: 'Shared through a brokered introduction',
                    subtitle: 'Work history, education, exact rate, resume',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final job in profile.workHistory)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.work_outline, size: 16, color: AppColors.navyLight),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('${job.jobTitle} · ${job.companyName}',
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                      Text(
                                        '${job.started} – ${job.isCurrent ? 'Present' : job.ended}',
                                        style: const TextStyle(color: AppColors.muted, fontSize: 11.5),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (profile.hasResume)
                          Row(
                            children: [
                              const Icon(Icons.description_outlined, size: 16, color: AppColors.navyLight),
                              const SizedBox(width: 8),
                              const Text('Resume on file', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _tierSection(
                    tier: 3,
                    title: 'Staff only',
                    subtitle: 'Email, phone, consent records — every read is logged',
                    child: const Text(
                      'Contact details are never shown to employers directly. '
                      'COS staff make the introduction.',
                      style: TextStyle(fontSize: 12.5, color: AppColors.muted, height: 1.4),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _publishBanner(BuildContext context, TalentProfile profile) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: BrandCard(
        color: AppColors.teal.withValues(alpha: 0.08),
        child: Row(
          children: [
            const Icon(Icons.rocket_launch_outlined, color: AppColors.tealDark),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                profile.isPublic
                    ? 'Your profile is published and visible to Tier 1 viewers.'
                    : 'You\'re approved. Publish when you\'re ready to go live.',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
            if (!profile.isPublic)
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.tealDark),
                onPressed: () {},
                child: const Text('Publish'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _tierSection({
    required int tier,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    final tierColor = switch (tier) {
      1 => AppColors.teal,
      2 => AppColors.navyLight,
      _ => AppColors.muted,
    };
    return BrandCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: tierColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'TIER $tier',
                  style: TextStyle(color: tierColor, fontWeight: FontWeight.w800, fontSize: 10.5),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.only(left: 0, bottom: 10),
            child: Text(subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 11.5)),
          ),
          const Divider(height: 20),
          child,
        ],
      ),
    );
  }
}
