import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/auth_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(const AuthState()) {
    on<AuthSignUpRequested>(_onSignUp);
    on<AuthSignInRequested>(_onSignIn);
    on<AuthSignOutRequested>(_onSignOut);
    on<AuthPasswordResetRequested>(_onPasswordReset);
    on<AuthPasswordUpdateRequested>(_onPasswordUpdate);
  }

  Future<void> _onSignUp(AuthSignUpRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.inProgress));
    try {
      final res = await AuthService.signUpWithPassword(email: event.email, password: event.password);
      if (res.session != null) {
        emit(state.copyWith(status: AuthStatus.signedIn, user: res.user));
      } else {
        emit(state.copyWith(status: AuthStatus.awaitingEmailConfirmation, pendingEmail: event.email));
      }
    } catch (e) {
      emit(state.copyWith(status: AuthStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _onSignIn(AuthSignInRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.inProgress));
    try {
      final res = await AuthService.signInWithPassword(email: event.email, password: event.password);
      if (res.session == null) throw Exception('No session returned');
      emit(state.copyWith(status: AuthStatus.signedIn, user: res.user));
    } catch (e) {
      emit(state.copyWith(status: AuthStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _onSignOut(AuthSignOutRequested event, Emitter<AuthState> emit) async {
    await AuthService.signOut();
    emit(const AuthState(status: AuthStatus.signedOut));
  }

  Future<void> _onPasswordReset(AuthPasswordResetRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.inProgress));
    try {
      await AuthService.sendPasswordResetEmail(event.email);
      emit(state.copyWith(status: AuthStatus.passwordResetSent, pendingEmail: event.email));
    } catch (e) {
      emit(state.copyWith(status: AuthStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _onPasswordUpdate(
    AuthPasswordUpdateRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.inProgress));
    try {
      await AuthService.updatePassword(event.newPassword);
      emit(state.copyWith(status: AuthStatus.passwordUpdated));
    } catch (e) {
      emit(state.copyWith(status: AuthStatus.failure, errorMessage: e.toString()));
    }
  }
}
