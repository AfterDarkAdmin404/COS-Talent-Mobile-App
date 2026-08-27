import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import 'check_inbox_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();

  bool _canSubmit(bool sending) => _email.text.contains('@') && !sending;

  void _submit() {
    context.read<AuthBloc>().add(AuthPasswordResetRequested(_email.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == AuthStatus.passwordResetSent) {
          final email = state.pendingEmail!;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CheckInboxScreen(
                email: email,
                title: 'Check your email',
                message: 'Click the password reset link we sent to',
                onResend: () => AuthService.sendPasswordResetEmail(email),
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        final sending = state.status == AuthStatus.inProgress;
        return Scaffold(
          backgroundColor: AppColors.offWhite,
          appBar: AppBar(title: const Text('Reset password')),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Forgot your password?',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your email and we\'ll send a link to reset it.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofocus: true,
                    enabled: !sending,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _canSubmit(sending) ? _submit() : null,
                    decoration: const InputDecoration(
                      labelText: 'Email address',
                      hintText: 'you@example.com',
                      prefixIcon: Icon(Icons.mail_outline, color: AppColors.muted),
                    ),
                  ),
                  if (state.status == AuthStatus.failure) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Couldn\'t send that email. ${state.errorMessage ?? ''}',
                      style: const TextStyle(color: AppColors.statusRejected, fontSize: 12.5),
                    ),
                  ],
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: _canSubmit(sending) ? _submit : null,
                    child: sending
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.white),
                          )
                        : const Text('Send reset link'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
