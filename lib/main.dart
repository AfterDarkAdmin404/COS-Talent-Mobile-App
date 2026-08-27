import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'blocs/auth/auth_bloc.dart';
import 'blocs/profile/profile_bloc.dart';
import 'config/env.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/setup_needed_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // `.env` ships as an asset (empty by default — see .env.example) so the
  // app builds and runs before real Supabase credentials exist.
  await dotenv.load(fileName: '.env');

  String? initError;
  if (AppEnv.isConfigured) {
    try {
      await Supabase.initialize(
        url: AppEnv.supabaseUrl,
        anonKey: AppEnv.supabaseAnonKey,
      );
    } catch (e) {
      debugPrint('Supabase initialization failed: $e');
      initError = e.toString();
    }
  }

  runApp(CosTalentApp(isConfigured: AppEnv.isConfigured && initError == null, initError: initError));
}

class CosTalentApp extends StatelessWidget {
  final bool isConfigured;
  final String? initError;
  const CosTalentApp({super.key, required this.isConfigured, this.initError});

  @override
  Widget build(BuildContext context) {
    if (!isConfigured) {
      return MaterialApp(
        title: 'COS Talent',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: SetupNeededScreen(errorDetail: initError),
      );
    }
    // Both blocs live at the app root so they survive navigation between
    // screens — e.g. ProfileBloc's state outlives pushing into the edit
    // wizard and popping back out, which is what lets ProfileViewScreen
    // stay a plain StatelessWidget instead of manually refreshing itself.
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthBloc()),
        BlocProvider(create: (_) => ProfileBloc()),
      ],
      child: MaterialApp(
        title: 'COS Talent',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const SplashScreen(),
      ),
    );
  }
}
