import 'package:supabase_flutter/supabase_flutter.dart';

/// Wraps Supabase Auth for the Talent app: password-based sign up / sign
/// in. Both signup confirmation and password reset go out as standard
/// Supabase confirmation-link emails — nothing to type in-app, the user
/// clicks the link and comes back. (No OTP/code path: this project isn't
/// sending 6-digit codes from the backend, just the default "Confirm
/// signup" / "Reset password" link templates.)
class AuthService {
  AuthService._();
  static final _client = Supabase.instance.client;

  static Session? get currentSession => _client.auth.currentSession;
  static User? get currentUser => _client.auth.currentUser;
  static bool get isSignedIn => currentSession != null;

  /// Creates the account. If the project has "Confirm email" enabled,
  /// `response.session` is null and the caller should tell the user to
  /// check their inbox and click the link before signing in.
  static Future<AuthResponse> signUpWithPassword({
    required String email,
    required String password,
  }) {
    return _client.auth.signUp(email: email.trim(), password: password);
  }

  static Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Re-sends the "Confirm signup" link email.
  static Future<void> resendConfirmationEmail(String email) {
    return _client.auth.resend(type: OtpType.signup, email: email.trim());
  }

  /// Sends the standard "Reset password" link email. Completing the reset
  /// happens wherever that link points (the Supabase project's configured
  /// redirect) — there's no in-app deep-link handling yet, so this app
  /// can't catch the click and show [updatePassword] automatically.
  static Future<void> sendPasswordResetEmail(String email) {
    return _client.auth.resetPasswordForEmail(email.trim());
  }

  /// Used by the "Change password" row in Account — the user is already
  /// signed in at that point, so this needs no email round-trip at all.
  static Future<UserResponse> updatePassword(String newPassword) {
    return _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  static Future<void> signOut() => _client.auth.signOut();
}
