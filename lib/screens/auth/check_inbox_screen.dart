import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Shown after a confirmation or password-reset link email goes out.
/// There's nothing to enter here — the user clicks the link in their
/// inbox and comes back on their own, so this is just a status screen
/// with a resend option.
class CheckInboxScreen extends StatefulWidget {
  final String email;
  final String title;
  final String message;
  final Future<void> Function() onResend;

  const CheckInboxScreen({
    super.key,
    required this.email,
    required this.title,
    required this.message,
    required this.onResend,
  });

  @override
  State<CheckInboxScreen> createState() => _CheckInboxScreenState();
}

class _CheckInboxScreenState extends State<CheckInboxScreen> {
  bool _resending = false;

  Future<void> _resend() async {
    setState(() => _resending = true);
    try {
      await widget.onResend();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email sent again.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Couldn\'t resend — try again shortly.')),
      );
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_read_outlined,
                  color: AppColors.tealDark,
                  size: 38,
                ),
              ),
              const SizedBox(height: 24),
              Text(widget.title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 10),
              Text(
                widget.message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                widget.email,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 28),
              OutlinedButton(
                onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                child: const Text('Back to sign in'),
              ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: _resending ? null : _resend,
                child: Text(_resending ? 'Sending…' : 'Resend email'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
