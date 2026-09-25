part of 'users_bloc.dart';

sealed class UsersEvent extends Equatable {
  const UsersEvent();

  @override
  List<Object?> get props => [];
}

final class UsersRequested extends UsersEvent {
  const UsersRequested();
}

final class UserCreated extends UsersEvent {
  const UserCreated({
    required this.name,
    required this.email,
    required this.password,
  });

  final String name;
  final String email;
  final String password;

  @override
  List<Object?> get props => [name, email, password];
}

final class UserUpdated extends UsersEvent {
  const UserUpdated({
    required this.id,
    required this.name,
    required this.email,
    this.newPassword,
  });

  final String id;
  final String name;
  final String email;

  /// Null/empty keeps the current password.
  final String? newPassword;

  @override
  List<Object?> get props => [id, name, email, newPassword];
}

final class UserDeleted extends UsersEvent {
  const UserDeleted(this.user);

  final AppUser user;

  @override
  List<Object?> get props => [user];
}
