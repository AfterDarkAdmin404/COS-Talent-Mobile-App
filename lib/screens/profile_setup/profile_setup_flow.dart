import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/profile/profile_bloc.dart';
import '../../blocs/profile/profile_event.dart';
import '../../blocs/profile/profile_state.dart';
import '../../models/talent_profile.dart';
import '../../theme/app_theme.dart';
import '../../widgets/step_progress.dart';
import '../home/home_shell.dart';
import 'steps/step_basics.dart';
import 'steps/step_experience.dart';
import 'steps/step_rate_availability.dart';
import 'steps/step_summary_links.dart';
import 'steps/step_review_publish.dart';

/// The candidate-facing profile creation wizard — the entire supply-side
/// product surface for M3 Phase 1 per `docs/04-talent-marketplace/PLAN.md`:
/// no employer accounts, no job posts, no messaging. Just a profile,
/// staff review, and candidate-controlled publication.
class ProfileSetupFlow extends StatefulWidget {
  /// Pass the candidate's current profile to edit it in place — the same
  /// wizard steps, but the final step updates that row instead of
  /// inserting a new one. Omit for the original signup wizard.
  final TalentProfile? existingProfile;
  const ProfileSetupFlow({super.key, this.existingProfile});

  @override
  State<ProfileSetupFlow> createState() => _ProfileSetupFlowState();
}

class _ProfileSetupFlowState extends State<ProfileSetupFlow> {
  final _controller = PageController();
  int _index = 0;

  @override
  void initState() {
    super.initState();
    final bloc = context.read<ProfileBloc>();
    if (widget.existingProfile != null) {
      bloc.add(ProfileEditStarted(widget.existingProfile!));
    } else {
      bloc.add(const ProfileStarted());
    }
    bloc.add(const ProfileReferenceDataRequested());
  }

  static const _labels = [
    'The basics',
    'Experience & skills',
    'Rate & availability',
    'Summary & documents',
    'Review & publish',
  ];

  bool get _isLastStep => _index == _labels.length - 1;

  bool _canAdvance(ProfileState state) {
    final p = state.profile;
    if (p == null) return false;
    if (state.status == ProfileBlocStatus.submitting) return false;
    if (_index == 0 && (p.firstName.trim().isEmpty || p.lastName.trim().isEmpty)) return false;
    if (_index == 1 && (p.categories.isEmpty || p.skills.isEmpty)) return false;
    if (_index == 2 && p.desiredAmount <= 0) return false;
    if (_isLastStep && !state.isEditing) return p.consentToPublish;
    return true;
  }

  void _next(ProfileState state) {
    if (_isLastStep) {
      final bloc = context.read<ProfileBloc>();
      if (state.isEditing) {
        bloc.add(const ProfileUpdateRequested());
      } else {
        bloc.add(const ProfileSubmitRequested());
      }
      return;
    }
    setState(() => _index++);
    _controller.animateToPage(
      _index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _back() {
    if (_index == 0) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _index--);
    _controller.animateToPage(
      _index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileBloc, ProfileState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status != ProfileBlocStatus.success) return;
        if (state.isEditing) {
          Navigator.of(context).pop();
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomeShell()),
            (route) => false,
          );
        }
      },
      builder: (context, state) {
        if (state.status == ProfileBlocStatus.loading || state.status == ProfileBlocStatus.initial) {
          return const Scaffold(
            backgroundColor: AppColors.offWhite,
            body: Center(child: CircularProgressIndicator(color: AppColors.teal)),
          );
        }
        if (state.status == ProfileBlocStatus.failure && state.profile == null) {
          return Scaffold(
            backgroundColor: AppColors.offWhite,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.statusRejected, size: 40),
                    const SizedBox(height: 16),
                    Text(state.errorMessage ?? 'Couldn\'t load your account.', textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => context.read<ProfileBloc>().add(
                        widget.existingProfile != null
                            ? ProfileEditStarted(widget.existingProfile!)
                            : const ProfileStarted(),
                      ),
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final submitting = state.status == ProfileBlocStatus.submitting;
        return Scaffold(
          backgroundColor: AppColors.offWhite,
          appBar: AppBar(
            leading: IconButton(
              onPressed: _back,
              icon: const Icon(Icons.arrow_back),
            ),
            title: Text(state.isEditing ? 'Edit your profile' : 'Build your profile'),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  child: StepProgress(
                    stepCount: _labels.length,
                    currentIndex: _index,
                    labels: _labels,
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _controller,
                    physics: const NeverScrollableScrollPhysics(),
                    children: const [
                      StepBasics(),
                      StepExperience(),
                      StepRateAvailability(),
                      StepSummaryLinks(),
                      StepReviewPublish(),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (state.status == ProfileBlocStatus.failure && state.profile != null) ...[
                        Text(
                          'Couldn\'t submit your profile. ${state.errorMessage ?? ''}',
                          style: const TextStyle(color: AppColors.statusRejected, fontSize: 12.5),
                        ),
                        const SizedBox(height: 8),
                      ],
                      ElevatedButton(
                        onPressed: _canAdvance(state) ? () => _next(state) : null,
                        child: submitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.white),
                              )
                            : Text(_isLastStep ? 'Submit for review' : 'Continue'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
