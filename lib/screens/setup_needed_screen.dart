import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Shown instead of crashing when `.env` hasn't been filled in yet.
class SetupNeededScreen extends StatelessWidget {
  final String? errorDetail;
  const SetupNeededScreen({super.key, this.errorDetail});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.settings_outlined, color: AppColors.tealLight, size: 40),
              const SizedBox(height: 20),
              const Text(
                'Supabase isn\'t configured yet',
                style: TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Fill in talent_app/.env with your project\'s values, '
                'then rebuild:',
                style: TextStyle(
                  color: AppColors.white.withValues(alpha: 0.8),
                  fontSize: 14.5,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'SUPABASE_URL=https://<project-ref>.supabase.co\n'
                  'SUPABASE_ANON_KEY=<anon-public-key>',
                  style: TextStyle(
                    color: AppColors.tealLight,
                    fontFamily: 'monospace',
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Both values are under Project Settings -> API in the '
                'Supabase dashboard.',
                style: TextStyle(
                  color: AppColors.white.withValues(alpha: 0.6),
                  fontSize: 12.5,
                ),
              ),
              if (errorDetail != null) ...[
                const SizedBox(height: 24),
                Text(
                  'Details: $errorDetail',
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.45),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
