import 'package:equatable/equatable.dart';

/// A locally registered admin user, persisted in shared_preferences.
class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    required this.salt,
    required this.createdAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
    passwordHash: json['passwordHash'] as String,
    salt: json['salt'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  final String id;
  final String name;
  final String email;
  final String passwordHash;
  final String salt;
  final DateTime createdAt;

  String get initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'passwordHash': passwordHash,
    'salt': salt,
    'createdAt': createdAt.toIso8601String(),
  };

  AppUser copyWith({
    String? name,
    String? email,
    String? passwordHash,
    String? salt,
  }) => AppUser(
    id: id,
    name: name ?? this.name,
    email: email ?? this.email,
    passwordHash: passwordHash ?? this.passwordHash,
    salt: salt ?? this.salt,
    createdAt: createdAt,
  );

  @override
  List<Object?> get props => [id, name, email, passwordHash, salt, createdAt];
}
