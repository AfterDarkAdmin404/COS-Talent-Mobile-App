import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../blocs/profile/profile_bloc.dart';
import '../../../blocs/profile/profile_event.dart';
import '../../../blocs/profile/profile_state.dart';
import '../../../models/talent_profile.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/brand_card.dart';
import '../../../widgets/pill_chip.dart';

/// PLAN.md A3: `is_public` defaults false. Staff approval only moves
/// `status` to `approved` — publication is a *separate* candidate act,
/// against a `profile_publication` consent row, because publishing to
/// the open web is a different purpose (and a different legal basis,
/// under Ley 1581 Art. 26(a)) from being visible to a vetted employer.
/// This screen is where that second, distinct action happens.
class StepReviewPublish extends StatelessWidget {
  const StepReviewPublish({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        final p = state.profile!;
        final bloc = context.read<ProfileBloc>();
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          children: [
            Text(
              'How you\'ll appear',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 10),
            _previewCard(p),
            const SizedBox(height: 24),
            Text(
              'What\'s public',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 2),
            const Text(
              'You control this. Nothing below is on by default.',
              style: TextStyle(color: AppColors.muted, fontSize: 12.5),
            ),
            const SizedBox(height: 12),
            _toggleRow(
              title: 'Show my full last name',
              subtitle: 'Off shows first name only',
              value: p.showFullName,
              onChanged: (v) => bloc.add(ProfileBasicsChanged(showFullName: v)),
            ),
            _toggleRow(
              title: 'Show my exact rate',
              subtitle: 'Off shows a range instead of "${p.rateLabel.split(' ').first}"',
              value: p.showExactRate,
              onChanged: (v) => bloc.add(ProfileVisibilityChanged(showExactRate: v)),
            ),
            _toggleRow(
              title: 'Make my resume publicly downloadable',
              subtitle: p.hasResume
                  ? 'Off keeps it visible only through a brokered introduction'
                  : 'Upload a resume in the previous step to enable this',
              value: p.showResumePublicly,
              enabled: p.hasResume,
              onChanged: (v) => bloc.add(ProfileVisibilityChanged(showResumePublicly: v)),
            ),
            if (!state.isEditing) ...[
              const SizedBox(height: 22),
              BrandCard(
                color: AppColors.navy.withValues(alpha: 0.03),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.fact_check_outlined, color: AppColors.navyLight, size: 20),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'One more thing before you\'re live',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'A COS staff member reviews every profile before it can '
                      'appear publicly. Submitting takes you to pending review — '
                      'this consent is what lets us publish it once approved.',
                      style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 14),
                    InkWell(
                      onTap: () => bloc.add(ProfileConsentToggled(!p.consentToPublish)),
                      borderRadius: BorderRadius.circular(10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: p.consentToPublish,
                            onChanged: (v) => bloc.add(ProfileConsentToggled(v ?? false)),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                'I authorize Complete Office Solutions to publish '
                                'my profile\'s public fields to the open web once '
                                'approved, and to share my full profile with '
                                'vetted employers it introduces me to.',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontSize: 12.8,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (!p.consentToPublish) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.info_outline, size: 14, color: AppColors.muted),
                    const SizedBox(width: 6),
                    Text(
                      'Checking this is required to submit for review',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ],
        );
      },
    );
  }

  Widget _previewCard(TalentProfile p) {
    final name = p.firstName.isEmpty ? 'Your name' : p.displayName;
    final title = p.professionalTitle.isEmpty
        ? 'Your professional title'
        : p.professionalTitle;
    return BrandCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.navy.withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_outline, color: AppColors.muted),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    Text(title, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
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
              PillChip(icon: Icons.place_outlined, label: p.city?.isNotEmpty == true ? '${p.city}, ${p.countryName}' : p.countryName),
              PillChip(icon: Icons.payments_outlined, label: p.rateLabel),
              PillChip(icon: Icons.schedule, label: p.availability.label),
            ],
          ),
        ],
      ),
    );
  }

  Widget _toggleRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool enabled = true,
  }) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: BrandCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                  ],
                ),
              ),
              Switch(value: value, onChanged: enabled ? onChanged : null),
            ],
          ),
        ),
      ),
    );
  }
}
