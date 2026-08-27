import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../blocs/profile/profile_bloc.dart';
import '../../../blocs/profile/profile_event.dart';
import '../../../blocs/profile/profile_state.dart';
import '../../../models/talent_profile.dart';
import '../../../services/storage_service.dart';
import '../../../theme/app_theme.dart';

class StepBasics extends StatefulWidget {
  const StepBasics({super.key});

  @override
  State<StepBasics> createState() => _StepBasicsState();
}

class _StepBasicsState extends State<StepBasics> {
  late final TalentProfile _initial = context.read<ProfileBloc>().state.profile!;
  late final _first = TextEditingController(text: _initial.firstName);
  late final _last = TextEditingController(text: _initial.lastName);
  late final _title = TextEditingController(text: _initial.professionalTitle);
  late final _city = TextEditingController(text: _initial.city ?? '');
  late bool _setHours = _initial.preferredHoursStart != null || _initial.preferredHoursEnd != null;

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (picked == null) return;
    if (!mounted) return;
    context.read<ProfileBloc>().add(ProfilePhotoUploadRequested(File(picked.path)));
  }

  String _hourLabel(int h) {
    final period = h < 12 ? 'AM' : 'PM';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:00 $period';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        final p = state.profile!;
        final uploadingPhoto = state.uploadingPhoto;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          children: [
            Center(
              child: GestureDetector(
                onTap: uploadingPhoto ? null : _pickPhoto,
                child: Stack(
                  children: [
                    Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        color: AppColors.navy.withValues(alpha: 0.06),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border),
                        image: p.photoPath != null
                            ? DecorationImage(
                                image: NetworkImage(StorageService.photoPublicUrl(p.photoPath!)),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: uploadingPhoto
                          ? const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2.4),
                              ),
                            )
                          : p.photoPath == null
                          ? const Icon(Icons.person_outline, size: 40, color: AppColors.muted)
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: const BoxDecoration(
                          color: AppColors.teal,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add_a_photo_outlined,
                          size: 15,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                state.photoError ?? 'Add a friendly, professional photo',
                style: TextStyle(
                  color: state.photoError != null ? AppColors.statusRejected : AppColors.muted,
                  fontSize: 12.5,
                ),
              ),
            ),
            const SizedBox(height: 26),
            TextField(
              controller: _first,
              onChanged: (v) =>
                  context.read<ProfileBloc>().add(ProfileBasicsChanged(firstName: v)),
              decoration: const InputDecoration(labelText: 'First name'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _last,
              onChanged: (v) =>
                  context.read<ProfileBloc>().add(ProfileBasicsChanged(lastName: v)),
              decoration: InputDecoration(
                labelText: 'Last name',
                helperText: 'Required, even if you don\'t show it publicly later.',
                helperMaxLines: 2,
                errorText: _last.text.trim().isEmpty ? 'Last name is required' : null,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _title,
              onChanged: (v) =>
                  context.read<ProfileBloc>().add(ProfileBasicsChanged(professionalTitle: v)),
              decoration: const InputDecoration(
                labelText: 'Professional title',
                hintText: 'e.g. Senior Virtual Assistant & Bookkeeper',
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<int>(
              initialValue: p.countryId,
              decoration: const InputDecoration(labelText: 'Country'),
              items: const [
                DropdownMenuItem(value: kColombiaCountryId, child: Text('Colombia')),
              ],
              onChanged: (v) => context.read<ProfileBloc>().add(
                ProfileBasicsChanged(countryId: v, utcOffset: kColombiaUtcOffsetHours),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _city,
              onChanged: (v) => context.read<ProfileBloc>().add(ProfileBasicsChanged(city: v)),
              decoration: const InputDecoration(labelText: 'City (optional)'),
            ),
            const SizedBox(height: 22),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _setHours,
              activeThumbColor: AppColors.teal,
              title: const Text('Set preferred working hours', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: const Text('Optional — in your own local time', style: TextStyle(fontSize: 12, color: AppColors.muted)),
              onChanged: (v) {
                setState(() => _setHours = v);
                if (!v) {
                  context.read<ProfileBloc>().add(
                    const ProfileBasicsChanged(clearPreferredHours: true),
                  );
                } else {
                  context.read<ProfileBloc>().add(
                    ProfileBasicsChanged(
                      preferredHoursStart: p.preferredHoursStart ?? 9,
                      preferredHoursEnd: p.preferredHoursEnd ?? 17,
                    ),
                  );
                }
              },
            ),
            if (_setHours) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: p.preferredHoursStart,
                      decoration: const InputDecoration(labelText: 'From'),
                      items: List.generate(
                        24,
                        (h) => DropdownMenuItem(value: h, child: Text(_hourLabel(h))),
                      ),
                      onChanged: (v) => context.read<ProfileBloc>().add(
                        ProfileBasicsChanged(preferredHoursStart: v),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: p.preferredHoursEnd,
                      decoration: const InputDecoration(labelText: 'To'),
                      items: List.generate(
                        24,
                        (h) => DropdownMenuItem(value: h, child: Text(_hourLabel(h))),
                      ),
                      onChanged: (v) => context.read<ProfileBloc>().add(
                        ProfileBasicsChanged(preferredHoursEnd: v),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}
