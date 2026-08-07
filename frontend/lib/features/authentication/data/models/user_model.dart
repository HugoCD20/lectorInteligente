import '../../domain/entities/user.dart';

/// Modelo de datos del usuario (capa de datos).
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    super.firstName,
    super.lastName,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as int,
        email: json['email'] as String,
        firstName: (json['first_name'] as String?) ?? '',
        lastName: (json['last_name'] as String?) ?? '',
      );
}
