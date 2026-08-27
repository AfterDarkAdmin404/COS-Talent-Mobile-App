import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/profile/profile_bloc.dart';
import '../../blocs/profile/profile_event.dart';
import '../../data/mock_data.dart';
import '../../models/talent_profile.dart';
import '../../theme/app_theme.dart';
import '../auth/sign_in_screen.dart';
import '../auth/sign_up_screen.dart';
import '../home/home_shell.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Image.asset('assets/images/logo_mark.png'),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: const Text(
                  'TALENT · COLOMBIA',
                  style: TextStyle(
                    color: AppColors.tealDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Get discovered by\nUS businesses that\nneed your skills.',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontSize: 34,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Build one profile, get staff-vetted, and let Complete '
                'Office Solutions broker the introduction — no cold '
                'applications, no job-board noise.',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.muted),
              ),
              const Spacer(flex: 2),
              _bullet(context, 'One profile, reviewed by a real person before it goes live'),
              const SizedBox(height: 10),
              _bullet(context, 'You control what\'s public — surname, exact rate, resume'),
              const SizedBox(height: 10),
              _bullet(context, 'Introductions are brokered by COS staff, not cold outreach'),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SignUpScreen()),
                ),
                child: const Text('Get started'),
              ),
              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SignInScreen()),
                  ),
                  child: const Text('I already have a profile'),
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: () {
                    final demo = buildDemoProfile().copyWith(
                      status: ProfileStatus.approved,
                      isPublic: true,
                      consentToPublish: true,
                    );
                    context.read<ProfileBloc>().add(ProfileEditStarted(demo));
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const HomeShell()),
                    );
                  },
                  style: TextButton.styleFrom(foregroundColor: AppColors.muted),
                  child: const Text('Preview a completed profile (design demo)'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bullet(BuildContext context, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 5),
          width: 18,
          height: 18,
          decoration: const BoxDecoration(
            color: AppColors.teal,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, size: 12, color: AppColors.white),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
