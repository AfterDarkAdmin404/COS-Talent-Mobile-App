import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/profile/profile_bloc.dart';
import '../../models/job_posting.dart';
import '../../services/job_application_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/pill_chip.dart';
import '../messages/application_thread_screen.dart';

/// Full posting details plus the apply action. Returns `true` via
/// `Navigator.pop` when an application was actually submitted, so
/// JobsBrowseScreen knows to refresh its "already applied" state.
class JobDetailScreen extends StatefulWidget {
  final JobPosting posting;
  /// Null when she hasn't applied yet; the real `job_applications.id`
  /// when she has — needed to open "Message employer" for an
  /// already-applied posting, not just one applied to in this same screen
  /// instance.
  final int? existingApplicationId;
  const JobDetailScreen({super.key, required this.posting, this.existingApplicationId});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  final _coverNote = TextEditingController();
  bool _applying = false;
  bool _applied = false;
  int? _jobApplicationId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _jobApplicationId = widget.existingApplicationId;
    _applied = _jobApplicationId != null;
  }

  @override
  void dispose() {
    _coverNote.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    final talentProfileId = context.read<ProfileBloc>().state.profile?.id;
    if (talentProfileId == null) return;
    setState(() {
      _applying = true;
      _error = null;
    });
    try {
      final application = await JobApplicationService.apply(
        jobPostingId: widget.posting.id,
        talentProfileId: talentProfileId,
        coverNote: _coverNote.text,
      );
      if (!mounted) return;
      setState(() {
        _applying = false;
        _applied = true;
        _jobApplicationId = application.id;
      });
      // Pops on the next frame so the "Application submitted" state is
      // visible for a beat before returning to the list.
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) Navigator.of(context).pop(true);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _applying = false;
        _error = 'Couldn\'t submit that. $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.posting;
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(title: const Text('Role details')),
      body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            children: [
              Text(p.title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 22)),
              const SizedBox(height: 4),
              Text(p.companyName, style: const TextStyle(color: AppColors.muted, fontSize: 14)),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  PillChip(icon: Icons.payments_outlined, label: p.budgetLabel),
                  if (p.categoryName != null) PillChip(label: p.categoryName!),
                  for (final type in p.engagementTypes)
                    PillChip(label: engagementTypeLabels[type] ?? type),
                ],
              ),
              if (p.description.trim().isNotEmpty) ...[
                const SizedBox(height: 20),
                Text('About this role', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(p.description, style: const TextStyle(fontSize: 14, height: 1.5)),
              ],
              const SizedBox(height: 24),
              if (_applied) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.card),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, color: AppColors.teal, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Application submitted. The employer will follow up through COS.',
                          style: TextStyle(fontSize: 13, color: AppColors.navy),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_jobApplicationId != null) ...[
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ApplicationThreadScreen(
                          jobApplicationId: _jobApplicationId!,
                          companyName: p.companyName,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    label: Text('Message ${p.companyName}'),
                  ),
                ],
              ] else ...[
                Text(
                  'Add a note (optional)',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _coverNote,
                  enabled: !_applying,
                  maxLines: 4,
                  decoration: const InputDecoration(hintText: 'Why you\'re a fit for this role'),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(_error!, style: const TextStyle(color: AppColors.statusRejected, fontSize: 12.5)),
                ],
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _applying ? null : _apply,
                  child: _applying
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.white),
                        )
                      : const Text('Submit application'),
                ),
              ],
            ],
          ),
        ),
    );
  }
}
