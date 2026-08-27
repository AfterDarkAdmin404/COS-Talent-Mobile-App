import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'onboarding/welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1100), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (_, anim, __) =>
              FadeTransition(opacity: anim, child: const WelcomeScreen()),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
    );
  }
}
