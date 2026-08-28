import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../blocs/profile/profile_bloc.dart';
import '../../../blocs/profile/profile_event.dart';
import '../../../blocs/profile/profile_state.dart';
import '../../../models/talent_profile.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/brand_card.dart';

class StepSummaryLinks extends StatefulWidget {
  const StepSummaryLinks({super.key});

  @override
  State<StepSummaryLinks> createState() => _StepSummaryLinksState();
}

class _StepSummaryLinksState extends State<StepSummaryLinks> {
  late final _summary = TextEditingController(
    text: context.read<ProfileBloc>().state.profile!.summary ?? '',
  );

  Future<void> _pickResume() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );
    final picked = result?.files.single;
    if (picked?.path == null) return;
    if (!mounted) return;
    context.read<ProfileBloc>().add(
      ProfileResumeUploadRequested(File(picked!.path!), picked.name),
    );
  }

  Future<void> _addCertification() async {
    final nameController = TextEditingController();
    final issuerController = TextEditingController();
    final urlController = TextEditingController();
    DateTime? issuedOn;
    String? urlError;

    final result = await showDialog<CertificationEntry>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add certification'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Certification name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: issuerController,
                  decoration: const InputDecoration(labelText: 'Issuer (optional)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: urlController,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    labelText: 'Credential URL (optional)',
                    hintText: 'https://...',
                    errorText: urlError,
                  ),
                ),
                const SizedBox(height: 4),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    issuedOn == null
                        ? 'Issue date (optional)'
                        : '${issuedOn!.year}-${issuedOn!.month.toString().padLeft(2, '0')}-${issuedOn!.day.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: issuedOn == null ? AppColors.muted : AppColors.ink,
                      fontSize: 13,
                    ),
                  ),
                  trailing: const Icon(Icons.calendar_today_outlined, size: 18),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: issuedOn ?? DateTime.now(),
                      firstDate: DateTime(1950),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setDialogState(() => issuedOn = picked);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                final url = urlController.text.trim();
                if (url.isNotEmpty && !RegExp(r'^https?://', caseSensitive: false).hasMatch(url)) {
                  setDialogState(() => urlError = 'Must start with http:// or https://');
                  return;
                }
                final issuer = issuerController.text.trim();
                Navigator.of(dialogContext).pop(
                  CertificationEntry(
                    name: name,
                    issuer: issuer.isEmpty ? null : issuer,
                    issuedOn: issuedOn,
                    credentialUrl: url.isEmpty ? null : url,
                  ),
                );
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
    if (result != null && mounted) {
      context.read<ProfileBloc>().add(ProfileCertificationAdded(result));
    }
  }

  Future<void> _addEducation() async {
    var level = EducationLevel.bachelors;
    final institutionController = TextEditingController();
    final fieldController = TextEditingController();
    final startedController = TextEditingController();
    final completedController = TextEditingController();
    String? institutionError;
    String? yearError;

    final result = await showDialog<TalentEducationEntry>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add education'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<EducationLevel>(
                  initialValue: level,
                  decoration: const InputDecoration(labelText: 'Level'),
                  items: EducationLevel.values
                      .map((lvl) => DropdownMenuItem(value: lvl, child: Text(lvl.label)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => level = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: institutionController,
                  autofocus: true,
                  decoration: InputDecoration(labelText: 'Institution', errorText: institutionError),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: fieldController,
                  decoration: const InputDecoration(labelText: 'Field of study (optional)'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: startedController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Started year'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: completedController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Completed year'),
                      ),
                    ),
                  ],
                ),
                if (yearError != null) ...[
                  const SizedBox(height: 6),
                  Text(yearError!, style: const TextStyle(color: AppColors.statusRejected, fontSize: 12)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final institution = institutionController.text.trim();
                if (institution.isEmpty) {
                  setDialogState(() => institutionError = 'Required');
                  return;
                }
                int? parseYear(String text) =>
                    text.trim().isEmpty ? null : int.tryParse(text.trim());
                final started = parseYear(startedController.text);
                final completed = parseYear(completedController.text);
                bool inRange(int? y) => y == null || (y >= 1950 && y <= 2100);
                if (!inRange(started) || !inRange(completed)) {
                  setDialogState(() => yearError = 'Years must be between 1950 and 2100');
                  return;
                }
                final field = fieldController.text.trim();
                Navigator.of(dialogContext).pop(
                  TalentEducationEntry(
                    level: level,
                    institution: institution,
                    fieldOfStudy: field.isEmpty ? null : field,
                    startedYear: started,
                    completedYear: completed,
                  ),
                );
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
    if (result != null && mounted) {
      context.read<ProfileBloc>().add(ProfileEducationAdded(result));
    }
  }

  Future<void> _addWorkHistory() async {
    final jobTitleController = TextEditingController();
    final companyController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime? startedOn;
    DateTime? endedOn;
    var isCurrent = false;
    String? jobTitleError;
    String? startedError;
    String? dateOrderError;

    final result = await showDialog<WorkHistoryEntry>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add work history'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: jobTitleController,
                  autofocus: true,
                  decoration: InputDecoration(labelText: 'Job title', errorText: jobTitleError),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: companyController,
                  decoration: const InputDecoration(labelText: 'Company name'),
                ),
                const SizedBox(height: 4),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    startedOn == null ? 'Started (required)' : formatMonthYear(startedOn!),
                    style: TextStyle(
                      color: startedOn == null ? AppColors.muted : AppColors.ink,
                      fontSize: 13,
                    ),
                  ),
                  subtitle: startedError != null
                      ? Text(startedError!, style: const TextStyle(color: AppColors.statusRejected, fontSize: 11.5))
                      : null,
                  trailing: const Icon(Icons.calendar_today_outlined, size: 18),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: startedOn ?? DateTime.now(),
                      firstDate: DateTime(1950),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setDialogState(() => startedOn = picked);
                  },
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: isCurrent,
                  activeThumbColor: AppColors.teal,
                  title: const Text('I currently work here', style: TextStyle(fontSize: 13)),
                  onChanged: (v) => setDialogState(() {
                    isCurrent = v;
                    if (v) endedOn = null;
                  }),
                ),
                if (!isCurrent) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      endedOn == null ? 'Ended (optional)' : formatMonthYear(endedOn!),
                      style: TextStyle(
                        color: endedOn == null ? AppColors.muted : AppColors.ink,
                        fontSize: 13,
                      ),
                    ),
                    subtitle: dateOrderError != null
                        ? Text(dateOrderError!, style: const TextStyle(color: AppColors.statusRejected, fontSize: 11.5))
                        : null,
                    trailing: const Icon(Icons.calendar_today_outlined, size: 18),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: endedOn ?? startedOn ?? DateTime.now(),
                        firstDate: DateTime(1950),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setDialogState(() => endedOn = picked);
                    },
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  maxLines: 4,
                  maxLength: 2000,
                  decoration: const InputDecoration(labelText: 'Description (optional)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final jobTitle = jobTitleController.text.trim();
                if (jobTitle.isEmpty) {
                  setDialogState(() => jobTitleError = 'Required');
                  return;
                }
                if (startedOn == null) {
                  setDialogState(() => startedError = 'Required');
                  return;
                }
                if (!isCurrent && endedOn != null && endedOn!.isBefore(startedOn!)) {
                  setDialogState(() => dateOrderError = 'Must be on or after the start date');
                  return;
                }
                final description = descriptionController.text.trim();
                Navigator.of(dialogContext).pop(
                  WorkHistoryEntry(
                    jobTitle: jobTitle,
                    companyName: companyController.text.trim(),
                    startedOn: startedOn!,
                    endedOn: isCurrent ? null : endedOn,
                    isCurrent: isCurrent,
                    description: description.isEmpty ? null : description,
                  ),
                );
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
    if (result != null && mounted) {
      context.read<ProfileBloc>().add(ProfileWorkHistoryAdded(result));
    }
  }

  IconData _iconForLinkKind(LinkKind kind) => switch (kind) {
    LinkKind.portfolio => Icons.brush_outlined,
    LinkKind.linkedin => Icons.business_center_outlined,
    LinkKind.website => Icons.language,
    LinkKind.github => Icons.code,
    LinkKind.behance => Icons.palette_outlined,
  };

  Future<void> _addLink() async {
    var kind = LinkKind.portfolio;
    var isPublic = false;
    final urlController = TextEditingController();
    String? urlError;

    final result = await showDialog<TalentProfileLink>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add link'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<LinkKind>(
                initialValue: kind,
                decoration: const InputDecoration(labelText: 'Type'),
                items: LinkKind.values
                    .map((k) => DropdownMenuItem(value: k, child: Text(k.label)))
                    .toList(),
                onChanged: (v) => setDialogState(() => kind = v!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: urlController,
                autofocus: true,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: 'URL',
                  hintText: 'https://...',
                  errorText: urlError,
                ),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: isPublic,
                activeThumbColor: AppColors.teal,
                title: const Text('Show on public profile', style: TextStyle(fontSize: 13)),
                onChanged: (v) => setDialogState(() => isPublic = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final url = urlController.text.trim();
                if (!RegExp(r'^https?://', caseSensitive: false).hasMatch(url)) {
                  setDialogState(() => urlError = 'Must start with http:// or https://');
                  return;
                }
                Navigator.of(dialogContext).pop(
                  TalentProfileLink(kind: kind, url: url, isPublic: isPublic),
                );
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
    if (result != null && mounted) {
      context.read<ProfileBloc>().add(ProfileLinkAdded(result));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        final p = state.profile!;
        final bloc = context.read<ProfileBloc>();
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          children: [
            _sectionLabel('Professional summary', 'A few sentences. Max 2000 characters.'),
            TextField(
              controller: _summary,
              onChanged: (v) => bloc.add(ProfileSummaryChanged(v)),
              maxLines: 5,
              maxLength: 2000,
              decoration: const InputDecoration(
                hintText: 'What you do best, and the kind of work you want more of...',
              ),
            ),
            const SizedBox(height: 8),
            _sectionLabel('Resume', 'PDF, DOC or DOCX — up to 10 MB'),
            BrandCard(
              onTap: state.uploadingResume ? null : _pickResume,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: p.hasResume
                          ? AppColors.teal.withValues(alpha: 0.12)
                          : AppColors.navy.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: state.uploadingResume
                        ? const Padding(
                            padding: EdgeInsets.all(11),
                            child: CircularProgressIndicator(strokeWidth: 2.4),
                          )
                        : Icon(
                            p.hasResume ? Icons.check_circle_outline : Icons.upload_file_outlined,
                            color: p.hasResume ? AppColors.tealDark : AppColors.navyLight,
                            size: 22,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      p.hasResume
                          ? (state.resumeFileName ?? 'Resume uploaded')
                          : 'Tap to upload your resume',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (!p.hasResume)
                    const Icon(Icons.chevron_right, color: AppColors.muted),
                ],
              ),
            ),
            if (state.resumeError != null) ...[
              const SizedBox(height: 6),
              Text(state.resumeError!, style: const TextStyle(color: AppColors.statusRejected, fontSize: 12.5)),
            ],
            const SizedBox(height: 22),
            _sectionLabel('Certifications', 'Optional — add anything relevant'),
            ...List.generate(p.certifications.length, (i) {
              final c = p.certifications[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: BrandCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.workspace_premium_outlined, color: AppColors.tealDark, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          c.issuer != null ? '${c.name} · ${c.issuer}' : c.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        onPressed: () => bloc.add(ProfileCertificationRemoved(i)),
                        icon: const Icon(Icons.close, size: 18, color: AppColors.muted),
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Remove',
                      ),
                    ],
                  ),
                ),
              );
            }),
            OutlinedButton.icon(
              onPressed: _addCertification,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add certification'),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            ),
            const SizedBox(height: 22),
            _sectionLabel('Links', 'Portfolio, LinkedIn, website — optional'),
            ...List.generate(p.links.length, (i) {
              final l = p.links[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: BrandCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Icon(_iconForLinkKind(l.kind), color: AppColors.tealDark, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l.kind.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text(
                              l.url,
                              style: const TextStyle(color: AppColors.muted, fontSize: 11.5),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (l.isPublic)
                        const Padding(
                          padding: EdgeInsets.only(right: 4),
                          child: Icon(Icons.public, size: 16, color: AppColors.muted),
                        ),
                      IconButton(
                        onPressed: () => bloc.add(ProfileLinkRemoved(i)),
                        icon: const Icon(Icons.close, size: 18, color: AppColors.muted),
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Remove',
                      ),
                    ],
                  ),
                ),
              );
            }),
            OutlinedButton.icon(
              onPressed: _addLink,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add link'),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            ),
            const SizedBox(height: 22),
            _sectionLabel('Education', 'Optional'),
            ...List.generate(p.education.length, (i) {
              final e = p.education[i];
              final years = e.startedYear != null || e.completedYear != null
                  ? ' · ${e.startedYear ?? '?'}–${e.completedYear ?? 'present'}'
                  : '';
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: BrandCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.school_outlined, color: AppColors.tealDark, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.fieldOfStudy != null
                                  ? '${e.level.label} · ${e.fieldOfStudy}'
                                  : e.level.label,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '${e.institution}$years',
                              style: const TextStyle(color: AppColors.muted, fontSize: 11.5),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => bloc.add(ProfileEducationRemoved(i)),
                        icon: const Icon(Icons.close, size: 18, color: AppColors.muted),
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Remove',
                      ),
                    ],
                  ),
                ),
              );
            }),
            OutlinedButton.icon(
              onPressed: _addEducation,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add education'),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            ),
            const SizedBox(height: 22),
            _sectionLabel('Work history', 'Optional'),
            ...List.generate(p.workHistory.length, (i) {
              final w = p.workHistory[i];
              final range =
                  '${formatMonthYear(w.startedOn)} – ${w.isCurrent ? 'Present' : formatMonthYear(w.endedOn!)}';
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: BrandCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.work_outline, color: AppColors.tealDark, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${w.jobTitle} · ${w.companyName}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(range, style: const TextStyle(color: AppColors.muted, fontSize: 11.5)),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => bloc.add(ProfileWorkHistoryRemoved(i)),
                        icon: const Icon(Icons.close, size: 18, color: AppColors.muted),
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Remove',
                      ),
                    ],
                  ),
                ),
              );
            }),
            OutlinedButton.icon(
              onPressed: _addWorkHistory,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add work history'),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            ),
          ],
        );
      },
    );
  }

  Widget _sectionLabel(String title, String? sub) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
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
