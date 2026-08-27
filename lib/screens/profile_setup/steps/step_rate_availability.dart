import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../blocs/profile/profile_bloc.dart';
import '../../../blocs/profile/profile_event.dart';
import '../../../blocs/profile/profile_state.dart';
import '../../../data/mock_data.dart';
import '../../../models/talent_profile.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/pill_chip.dart';

class StepRateAvailability extends StatefulWidget {
  const StepRateAvailability({super.key});

  @override
  State<StepRateAvailability> createState() => _StepRateAvailabilityState();
}

class _StepRateAvailabilityState extends State<StepRateAvailability> {
  late final _initial = context.read<ProfileBloc>().state.profile!;
  late final _amount = TextEditingController(
    text: _initial.desiredAmount > 0 ? _initial.desiredAmount.toStringAsFixed(0) : '',
  );

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        final p = state.profile!;
        final bloc = context.read<ProfileBloc>();
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          children: [
            _sectionLabel('Your rate', 'In USD — every employer on the platform is a US business'),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _amount,
                    keyboardType: TextInputType.number,
                    onChanged: (v) =>
                        bloc.add(ProfileRateChanged(desiredAmount: double.tryParse(v) ?? 0)),
                    decoration: const InputDecoration(
                      prefixText: '\$  ',
                      labelText: 'Amount',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<DesiredPeriod>(
                    initialValue: p.desiredPeriod,
                    decoration: const InputDecoration(labelText: 'Per'),
                    items: const [
                      DropdownMenuItem(
                        value: DesiredPeriod.hourly,
                        child: Text('Hour'),
                      ),
                      DropdownMenuItem(
                        value: DesiredPeriod.monthly,
                        child: Text('Month'),
                      ),
                    ],
                    onChanged: (v) => bloc.add(ProfileRateChanged(desiredPeriod: v)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '≈ \$${p.desiredMonthlyUsd.toStringAsFixed(0)}/month full-time — '
              'this is what employers filter by',
              style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
            ),
            const SizedBox(height: 22),
            _sectionLabel('Engagement types', 'Select all you\'re open to'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kEngagementTypeLabels.entries.map((e) {
                final selected = p.engagementTypes.contains(e.key);
                return PillChip(
                  label: e.value,
                  selected: selected,
                  onTap: () => bloc.add(ProfileEngagementTypeToggled(e.key)),
                );
              }).toList(),
            ),
            const SizedBox(height: 22),
            _sectionLabel('Availability', null),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: Availability.values.map((a) {
                final selected = p.availability == a;
                return PillChip(
                  label: a.label,
                  selected: selected,
                  onTap: () => bloc.add(ProfileAvailabilityChanged(a)),
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
