import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/app_exception.dart';
import '../../../data/models/app_user.dart';
import '../../../data/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._repository) : super(const AuthInitial()) {
    on<AuthStarted>(_onStarted);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthUserRefreshed>(_onUserRefreshed);
  }

  final AuthRepository _repository;

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    final user = await _repository.currentUser();
    emit(user == null ? const Unauthenticated() : Authenticated(user));
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _repository.login(
        email: event.email,
        password: event.password,
      );
      emit(Authenticated(user));
    } on AppException catch (error) {
      emit(AuthFailure(error.message));
    }
  }

  /// Registration does not log the user in — they are sent back to the
  /// login page (spec 3.1.1).
  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _repository.register(
        name: event.name,
        email: event.email,
        password: event.password,
      );
      emit(AuthRegistered(user.email));
    } on AppException catch (error) {
      emit(AuthFailure(error.message));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _repository.logout();
    emit(const Unauthenticated());
  }

  /// Re-reads the logged-in user after the dashboard edits users, so the
  /// app bar reflects a changed name/email.
  Future<void> _onUserRefreshed(
    AuthUserRefreshed event,
    Emitter<AuthState> emit,
  ) async {
    if (state is! Authenticated) return;
    final user = await _repository.currentUser();
    emit(user == null ? const Unauthenticated() : Authenticated(user));
  }
}
