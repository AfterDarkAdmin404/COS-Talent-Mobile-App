import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../profile_setup/profile_setup_flow.dart';
import 'check_inbox_screen.dart';
import 'sign_in_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure1 = true;
  bool _obscure2 = true;

  String? get _passwordMismatch =>
      _confirm.text.isNotEmpty && _confirm.text != _password.text
          ? 'Passwords don\'t match'
          : null;

  bool _canSubmit(bool submitting) =>
      _email.text.contains('@') &&
      _password.text.length >= 6 &&
      _confirm.text == _password.text &&
      !submitting;

  void _submit() {
    context.read<AuthBloc>().add(
      AuthSignUpRequested(email: _email.text.trim(), password: _password.text),
    );
  }

  String _friendlyError(String msg) {
    if (msg.contains('already registered') || msg.contains('User already registered')) {
      return 'An account with that email already exists — try signing in instead.';
    }
    if (msg.contains('Password should be')) {
      return 'Password needs to be at least 6 characters.';
    }
    if (msg.contains('SocketException') || msg.contains('Network')) {
      return 'Couldn\'t reach Supabase — check your connection and try again.';
    }
    return 'Something went wrong creating your account. $msg';
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.signedIn) {
          // marketplace_users has no auto-populating trigger; ProfileBloc's
          // load handles ensuring that row exists before the wizard relies on it.
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const ProfileSetupFlow()),
            (route) => false,
          );
        } else if (state.status == AuthStatus.awaitingEmailConfirmation) {
          final email = state.pendingEmail!;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CheckInboxScreen(
                email: email,
                title: 'Confirm your account',
                message: 'Click the confirmation link we sent to',
                onResend: () => AuthService.resendConfirmationEmail(email),
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        final submitting = state.status == AuthStatus.inProgress;
        return Scaffold(
          backgroundColor: AppColors.offWhite,
          appBar: AppBar(title: const Text('Create your account')),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              children: [
                Text(
                  'Let\'s find your fit',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Set a password now — you\'ll use it to sign back in.',
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
                  obscureText: _obscure1,
                  enabled: !submitting,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    helperText: 'At least 6 characters',
                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.muted),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure1 ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      color: AppColors.muted,
                      onPressed: () => setState(() => _obscure1 = !_obscure1),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _confirm,
                  obscureText: _obscure2,
                  enabled: !submitting,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _canSubmit(submitting) ? _submit() : null,
                  decoration: InputDecoration(
                    labelText: 'Confirm password',
                    errorText: _passwordMismatch,
                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.muted),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure2 ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      color: AppColors.muted,
                      onPressed: () => setState(() => _obscure2 = !_obscure2),
                    ),
                  ),
                ),
                if (state.status == AuthStatus.failure) ...[
                  const SizedBox(height: 10),
                  Text(
                    _friendlyError(state.errorMessage ?? ''),
                    style: const TextStyle(color: AppColors.statusRejected, fontSize: 12.5),
                  ),
                ],
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: _canSubmit(submitting) ? _submit : null,
                  child: submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.white),
                        )
                      : const Text('Create account'),
                ),
                const SizedBox(height: 14),
                Center(
                  child: TextButton(
                    onPressed: submitting
                        ? null
                        : () => Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => const SignInScreen()),
                            ),
                    child: const Text('Already have an account? Sign in'),
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
