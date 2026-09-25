part of 'users_bloc.dart';

enum UsersStatus { loading, ready }

final class UsersState extends Equatable {
  const UsersState({
    this.status = UsersStatus.loading,
    this.users = const [],
    this.message,
  });

  final UsersStatus status;
  final List<AppUser> users;
  final UiMessage? message;

  UsersState copyWith({
    UsersStatus? status,
    List<AppUser>? users,
    UiMessage? message,
  }) => UsersState(
    status: status ?? this.status,
    users: users ?? this.users,
    message: message ?? this.message,
  );

  @override
  List<Object?> get props => [status, users, message];
}
