import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/profile/profile_bloc.dart';
import '../blocs/profile/profile_event.dart';
import '../blocs/profile/profile_state.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'home/home_shell.dart';
import 'onboarding/welcome_screen.dart';
import 'profile_setup/profile_setup_flow.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  /// True once we've asked [ProfileBloc] to resolve a persisted session —
  /// gates the [BlocListener] below so it only reacts to a load *this*
  /// screen kicked off, not some earlier, unrelated bloc state.
  bool _resolvingSession = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1100), _proceed);
  }

  /// Supabase's own local storage already persisted the session (access +
  /// refresh token) across restarts — no SharedPreferences of our own
  /// needed for that part. What was missing is this check: without it, the
  /// app always lands on [WelcomeScreen] and makes a signed-in user log in
  /// again on every launch, even though [AuthService.isSignedIn] is
  /// already true by the time this runs (`Supabase.initialize()` in
  /// `main.dart` awaits session recovery before `runApp`).
  void _proceed() {
    if (!mounted) return;
    if (AuthService.isSignedIn) {
      setState(() => _resolvingSession = true);
      context.read<ProfileBloc>().add(const ProfileLoadCurrentRequested());
    } else {
      _goTo(const WelcomeScreen());
    }
  }

  void _goTo(Widget screen) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, anim, __) => FadeTransition(opacity: anim, child: screen),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileBloc, ProfileState>(
      listenWhen: (previous, current) =>
          _resolvingSession &&
          previous.status != current.status &&
          (current.status == ProfileBlocStatus.loaded || current.status == ProfileBlocStatus.failure),
      listener: (context, state) {
        if (state.status == ProfileBlocStatus.failure) {
          // Expired/invalid session, or a transient load error — either
          // way, fall back to Welcome rather than getting stuck here.
          _goTo(const WelcomeScreen());
          return;
        }
        _goTo(state.profile != null ? const HomeShell() : const ProfileSetupFlow());
      },
      child: Scaffold(
        backgroundColor: AppColors.navy,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 92,
                height: 92,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: brandShadow(strength: 1.4),
                ),
                child: Image.asset('assets/images/logo_mark.png'),
              ),
              const SizedBox(height: 20),
              const Text(
                'Talent',
                style: TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'by Complete Office Solutions',
                style: TextStyle(
                  color: AppColors.white.withValues(alpha: 0.65),
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
