import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/profile/profile_bloc.dart';
import '../../blocs/profile/profile_event.dart';
import '../../blocs/profile/profile_state.dart';
import '../../services/auth_service.dart';
import '../../services/talent_profile_pdf_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/brand_card.dart';
import '../auth/set_new_password_screen.dart';
import '../onboarding/welcome_screen.dart';

/// Account settings + the consent ledger — `marketplace_users` fields
/// plus a read-out of `marketplace_consents` rows the candidate has on
/// file. Includes the optional-password affordance from PLAN.md A2.
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _downloading = false;

  Future<void> _downloadData() async {
    final profile = context.read<ProfileBloc>().state.profile;
    if (profile == null || _downloading) return;
    setState(() => _downloading = true);
    try {
      await TalentProfilePdfService.downloadAndShare(profile, email: AuthService.currentUser?.email);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Couldn\'t build that PDF. $e')),
      );
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        final profile = state.profile!;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          children: [
            Text('Account', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 24)),
            const SizedBox(height: 18),
            BrandCard(
              child: Column(
                children: [
                  _row(
                    icon: Icons.mail_outline,
                    title: 'Email',
                    value: AuthService.currentUser?.email ?? 'Not signed in',
                  ),
                  const Divider(height: 22),
                  _row(
                    icon: Icons.lock_outline,
                    title: 'Password',
                    value: '••••••••',
                    trailing: TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SetNewPasswordScreen()),
                      ),
                      child: const Text('Change'),
                    ),
                  ),
                  const Divider(height: 22),
                  _row(icon: Icons.translate, title: 'Language', value: 'English'),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text('Consent & privacy', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 10),
            BrandCard(
              child: Column(
                children: [
                  _consentRow(
                    'Profile publication',
                    profile.consentToPublish,
                    'Lets COS publish your public fields to the open web',
                  ),
                  const Divider(height: 22),
                  _consentRow(
                    'Employer introduction',
                    true,
                    'Lets COS share your full profile with a vetted employer',
                  ),
                  const Divider(height: 22),
                  _consentRow(
                    'Cross-border transfer',
                    true,
                    'Required to process your data outside Colombia (Ley 1581 Art. 26)',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            BrandCard(
              onTap: _downloading ? null : _downloadData,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Row(
                children: [
                  const Icon(Icons.download_outlined, color: AppColors.navyLight, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Download my data', style: TextStyle(fontWeight: FontWeight.w600))),
                  if (_downloading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    const Icon(Icons.chevron_right, color: AppColors.muted),
                ],
              ),
            ),
            const SizedBox(height: 10),
            BrandCard(
              onTap: () {},
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: const Row(
                children: [
                  Icon(Icons.delete_outline, color: AppColors.statusRejected, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Delete my account',
                      style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.statusRejected),
                    ),
                  ),
                  Icon(Icons.chevron_right, color: AppColors.muted),
                ],
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => _signOut(context),
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Sign out'),
            ),
          ],
        );
      },
    );
  }

  void _signOut(BuildContext context) {
    context.read<AuthBloc>().add(const AuthSignOutRequested());
    context.read<ProfileBloc>().add(const ProfileReset());
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  Widget _row({required IconData icon, required String title, required String value, Widget? trailing}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.navyLight),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _consentRow(String title, bool granted, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          granted ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 18,
          color: granted ? AppColors.teal : AppColors.border,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 11.5, height: 1.3)),
            ],
          ),
        ),
      ],
    );
  }
}
