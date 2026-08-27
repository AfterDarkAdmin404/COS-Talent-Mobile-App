import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../blocs/profile/profile_bloc.dart';
import '../../../blocs/profile/profile_event.dart';
import '../../../blocs/profile/profile_state.dart';
import '../../../models/talent_profile.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/pill_chip.dart';

class StepExperience extends StatelessWidget {
  const StepExperience({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        final p = state.profile!;
        final bloc = context.read<ProfileBloc>();
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          children: [
            _sectionLabel('Categories', 'Pick what best describes your work'),
            if (state.loadingReferenceData)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
              )
            else if (state.errorMessage != null && state.availableCategories.isEmpty)
              Text(state.errorMessage!, style: const TextStyle(color: AppColors.statusRejected, fontSize: 12.5))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: state.availableCategories.map((c) {
                  final selected = p.categories.contains(c);
                  return PillChip(
                    label: c.name,
                    selected: selected,
                    onTap: () => bloc.add(ProfileCategoryToggled(c)),
                  );
                }).toList(),
              ),
            const SizedBox(height: 24),
            _sectionLabel('Skills & tools', 'Tap all that apply'),
            if (state.loadingReferenceData)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
              )
            else if (state.errorMessage != null && state.availableSkills.isEmpty)
              Text(state.errorMessage!, style: const TextStyle(color: AppColors.statusRejected, fontSize: 12.5))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: state.availableSkills.map((s) {
                  final selected = p.skills.contains(s);
                  return PillChip(
                    label: s.name,
                    selected: selected,
                    onTap: () => bloc.add(ProfileSkillToggled(s)),
                  );
                }).toList(),
              ),
            const SizedBox(height: 24),
            _sectionLabel('Years of experience', null),
            Slider(
              value: p.yearsExperience.toDouble(),
              min: 0,
              max: 30,
              divisions: 30,
              activeColor: AppColors.teal,
              label: '${p.yearsExperience} yrs',
              onChanged: (v) => bloc.add(ProfileExperienceChanged(yearsExperience: v.round())),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${p.yearsExperience} year${p.yearsExperience == 1 ? '' : 's'}',
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy),
              ),
            ),
            const SizedBox(height: 12),
            _sectionLabel('English level', 'Self-declared now; COS staff confirm this during review'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: EnglishLevel.values.map((level) {
                final selected = p.englishLevel == level;
                return PillChip(
                  label: level.label,
                  selected: selected,
                  onTap: () => bloc.add(ProfileExperienceChanged(englishLevel: level)),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _sectionLabel(String title, String? sub) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppColors.ink,
            ),
          ),
          if (sub != null) ...[
            const SizedBox(height: 2),
            Text(
              sub,
              style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
            ),
          ],
        ],
      ),
    );
  }
}
