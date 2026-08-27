import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Reads Supabase config from `.env` (see `.env.example`). Values are
/// blank until the real project URL/anon key are filled in — [isConfigured]
/// tells the rest of the app whether it's safe to call
/// `Supabase.initialize`, so a missing `.env` shows a clear setup screen
/// instead of crashing.
class AppEnv {
  AppEnv._();

  static String get supabaseUrl => dotenv.env['SUPABASE_URL']?.trim() ?? '';
  static String get supabaseAnonKey =>
      dotenv.env['SUPABASE_ANON_KEY']?.trim() ?? '';

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
