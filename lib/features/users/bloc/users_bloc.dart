import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/ui_message.dart';
import '../../../data/models/app_user.dart';
import '../../../data/repositories/user_repository.dart';

part 'users_event.dart';
part 'users_state.dart';

class UsersBloc extends Bloc<UsersEvent, UsersState> {
  UsersBloc(this._repository) : super(const UsersState()) {
    on<UsersRequested>(_onRequested);
    on<UserCreated>(_onCreated);
    on<UserUpdated>(_onUpdated);
    on<UserDeleted>(_onDeleted);
  }

  final UserRepository _repository;

  /// Newest first.
  List<AppUser> _loadUsers() =>
      _repository.getAll()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  void _onRequested(UsersRequested event, Emitter<UsersState> emit) {
    emit(state.copyWith(status: UsersStatus.ready, users: _loadUsers()));
  }

  Future<void> _onCreated(UserCreated event, Emitter<UsersState> emit) async {
    try {
      final user = await _repository.create(
        name: event.name,
        email: event.email,
        password: event.password,
      );
      emit(
        state.copyWith(
          users: _loadUsers(),
          message: UiMessage('${user.name} was added'),
        ),
      );
    } on AppException catch (error) {
      emit(state.copyWith(message: UiMessage(error.message, isError: true)));
    }
  }

  Future<void> _onUpdated(UserUpdated event, Emitter<UsersState> emit) async {
    try {
      final user = await _repository.update(
        event.id,
        name: event.name,
        email: event.email,
        newPassword: event.newPassword,
      );
      emit(
        state.copyWith(
          users: _loadUsers(),
          message: UiMessage('Changes to ${user.name} saved'),
        ),
      );
    } on AppException catch (error) {
      emit(state.copyWith(message: UiMessage(error.message, isError: true)));
    }
  }

  Future<void> _onDeleted(UserDeleted event, Emitter<UsersState> emit) async {
    try {
      await _repository.delete(event.user.id);
      emit(
        state.copyWith(
          users: _loadUsers(),
          message: UiMessage('${event.user.name} was removed'),
        ),
      );
    } on AppException catch (error) {
      emit(state.copyWith(message: UiMessage(error.message, isError: true)));
    }
  }
}
