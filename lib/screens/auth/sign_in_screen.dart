import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/profile/profile_bloc.dart';
import '../../blocs/profile/profile_event.dart';
import '../../blocs/profile/profile_state.dart';
import '../../theme/app_theme.dart';
import '../home/home_shell.dart';
import '../profile_setup/profile_setup_flow.dart';
import 'forgot_password_screen.dart';
import 'sign_up_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  bool _canSubmit(bool submitting) =>
      _email.text.contains('@') && _password.text.isNotEmpty && !submitting;

  void _submit() {
    context.read<AuthBloc>().add(
      AuthSignInRequested(email: _email.text.trim(), password: _password.text),
    );
  }

  String _friendlyError(String msg) {
    if (msg.contains('Invalid login credentials')) {
      return 'That email or password is incorrect.';
    }
    if (msg.contains('Email not confirmed')) {
      return 'Confirm your email first — check your inbox for the code.';
    }
    if (msg.contains('SocketException') || msg.contains('Network')) {
      return 'Couldn\'t reach Supabase — check your connection and try again.';
    }
    return 'Something went wrong signing in. $msg';
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listenWhen: (previous, current) =>
              previous.status != current.status && current.status == AuthStatus.signedIn,
          listener: (context, state) {
            // Idempotent — covers both "never had a marketplace_users row
            // yet" and "had one already," since there's no DB trigger
            // creating it. Handled inside ProfileLoadCurrentRequested's
            // own MarketplaceUserService call chain via ProfileBloc.
            context.read<ProfileBloc>().add(const ProfileLoadCurrentRequested());
          },
        ),
        BlocListener<ProfileBloc, ProfileState>(
          listenWhen: (previous, current) =>
              previous.status != current.status &&
              (current.status == ProfileBlocStatus.loaded ||
                  current.status == ProfileBlocStatus.failure),
          listener: (context, state) {
            if (state.status == ProfileBlocStatus.failure) return;
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => state.profile != null ? const HomeShell() : const ProfileSetupFlow(),
              ),
              (route) => false,
            );
          },
        ),
      ],
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          return BlocBuilder<ProfileBloc, ProfileState>(
            builder: (context, profileState) {
              final submitting =
                  authState.status == AuthStatus.inProgress ||
                  (authState.status == AuthStatus.signedIn &&
                      profileState.status == ProfileBlocStatus.loading);
              final error = authState.status == AuthStatus.failure
                  ? _friendlyError(authState.errorMessage ?? '')
                  : profileState.status == ProfileBlocStatus.failure
                  ? 'Signed in, but couldn\'t load your profile. ${profileState.errorMessage ?? ''}'
                  : null;

              return Scaffold(
                backgroundColor: AppColors.offWhite,
                appBar: AppBar(title: const Text('Sign in')),
                body: SafeArea(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    children: [
                      Text('Welcome back', style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in with the email and password you set when you joined.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 15),
                      ),
                      const SizedBox(height: 28),
                      TextField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        autofocus: true,
                        enabled: !submitting,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Email address',
                          hintText: 'you@example.com',
                          prefixIcon: Icon(Icons.mail_outline, color: AppColors.muted),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _password,
                        obscureText: _obscure,
                        enabled: !submitting,
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (_) => _canSubmit(submitting) ? _submit() : null,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline, color: AppColors.muted),
                          suffixIcon: IconButton(
                            icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                            color: AppColors.muted,
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: submitting
                              ? null
                              : () => Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                                  ),
                          child: const Text('Forgot password?'),
                        ),
                      ),
                      if (error != null) ...[
                        Text(error, style: const TextStyle(color: AppColors.statusRejected, fontSize: 12.5)),
                        const SizedBox(height: 6),
                      ],
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _canSubmit(submitting) ? _submit : null,
                        child: submitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.white),
                              )
                            : const Text('Sign in'),
                      ),
                      const SizedBox(height: 14),
                      Center(
                        child: TextButton(
                          onPressed: submitting
                              ? null
                              : () => Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(builder: (_) => const SignUpScreen()),
                                  ),
                          child: const Text('New here? Create an account'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
