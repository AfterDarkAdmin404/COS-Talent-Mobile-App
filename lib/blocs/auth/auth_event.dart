import 'package:equatable/equatable.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthSignUpRequested extends AuthEvent {
  final String email;
  final String password;
  const AuthSignUpRequested({required this.email, required this.password});
  @override
  List<Object?> get props => [email, password];
}

class AuthSignInRequested extends AuthEvent {
  final String email;
  final String password;
  const AuthSignInRequested({required this.email, required this.password});
  @override
  List<Object?> get props => [email, password];
}

class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

class AuthPasswordResetRequested extends AuthEvent {
  final String email;
  const AuthPasswordResetRequested(this.email);
  @override
  List<Object?> get props => [email];
}

class AuthPasswordUpdateRequested extends AuthEvent {
  final String newPassword;
  const AuthPasswordUpdateRequested(this.newPassword);
  @override
  List<Object?> get props => [newPassword];
}
