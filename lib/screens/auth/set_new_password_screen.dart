import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../theme/app_theme.dart';

/// Reached from Account -> Change password. The user is already
/// signed in, so this only needs `updateUser`, no re-authentication.
class SetNewPasswordScreen extends StatefulWidget {
  const SetNewPasswordScreen({super.key});

  @override
  State<SetNewPasswordScreen> createState() => _SetNewPasswordScreenState();
}

class _SetNewPasswordScreenState extends State<SetNewPasswordScreen> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure1 = true;
  bool _obscure2 = true;

  bool _canSubmit(bool submitting) =>
      _password.text.length >= 6 && _confirm.text == _password.text && !submitting;

  void _submit() {
    context.read<AuthBloc>().add(AuthPasswordUpdateRequested(_password.text));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == AuthStatus.passwordUpdated) {
          final messenger = ScaffoldMessenger.of(context);
          Navigator.of(context).pop();
          messenger.showSnackBar(const SnackBar(content: Text('Password updated.')));
        }
      },
      builder: (context, state) {
        final submitting = state.status == AuthStatus.inProgress;
        return Scaffold(
          backgroundColor: AppColors.offWhite,
          appBar: AppBar(title: const Text('Set a new password')),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              children: [
                Text(
                  'Choose a new password',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _password,
                  obscureText: _obscure1,
                  autofocus: true,
                  enabled: !submitting,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'New password',
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
                    labelText: 'Confirm new password',
                    errorText: _confirm.text.isNotEmpty && _confirm.text != _password.text
                        ? 'Passwords don\'t match'
                        : null,
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
                    'Couldn\'t set that password. ${state.errorMessage ?? ''}',
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
                      : const Text('Save password'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
