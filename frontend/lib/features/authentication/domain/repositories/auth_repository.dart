import '../entities/auth_session.dart';
import '../entities/user.dart';

/// Contrato del repositorio de autenticación.
abstract interface class AuthRepository {
  Future<AuthSession> login({required String email, required String password});

  Future<AuthSession> register({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  });

  Future<void> logout();

  /// Restaura la sesión guardada. Devuelve `null` si no existe o es inválida.
  Future<User?> restoreSession();

  Future<User> updateProfile({String? firstName, String? lastName});

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<void> deleteAccount();
}
