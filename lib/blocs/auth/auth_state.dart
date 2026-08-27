import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum AuthStatus {
  initial,
  inProgress,
  signedIn,
  awaitingEmailConfirmation,
  signedOut,
  passwordResetSent,
  passwordUpdated,
  failure,
}

class AuthState extends Equatable {
  final AuthStatus status;
  final User? user;

  /// The address a "check your inbox" screen should display — set for
  /// [AuthStatus.awaitingEmailConfirmation] and [AuthStatus.passwordResetSent].
  final String? pendingEmail;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.pendingEmail,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? pendingEmail,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      pendingEmail: pendingEmail ?? this.pendingEmail,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, user?.id, pendingEmail, errorMessage];
}
