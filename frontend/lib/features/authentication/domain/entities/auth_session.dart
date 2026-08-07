import 'user.dart';

/// Sesión de autenticación con los tokens emitidos por el backend.
class AuthSession {
  const AuthSession({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  final User user;
  final String accessToken;
  final String refreshToken;
}
