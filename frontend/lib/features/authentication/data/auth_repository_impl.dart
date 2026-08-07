import '../../../core/errors/app_exception.dart';
import '../../../core/storage/token_storage.dart';
import '../domain/entities/auth_session.dart';
import '../domain/entities/user.dart';
import '../domain/repositories/auth_repository.dart';
import 'datasources/auth_remote_datasource.dart';

/// Implementación del repositorio de autenticación.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required this._datasource,
    required this._tokenStorage,
  });

  final AuthRemoteDatasource _datasource;
  final TokenStorage _tokenStorage;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final session = await _datasource.login(email: email, password: password);
    await _persist(session);
    return session;
  }

  @override
  Future<AuthSession> register({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    final session = await _datasource.register(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
    );
    await _persist(session);
    return session;
  }

  @override
  Future<void> logout() async {
    final refresh = await _tokenStorage.readRefreshToken();
    if (refresh != null && refresh.isNotEmpty) {
      try {
        await _datasource.logout(refresh);
      } on AppException {
        // Se continúa con el cierre local aunque el servidor no esté disponible.
      }
    }
    await _tokenStorage.clear();
  }

  @override
  Future<User?> restoreSession() async {
    final access = await _tokenStorage.readAccessToken();
    if (access == null || access.isEmpty) {
      return null;
    }
    try {
      return await _datasource.getCurrentUser();
    } on AppException {
      await _tokenStorage.clear();
      return null;
    }
  }

  @override
  Future<User> updateProfile({String? firstName, String? lastName}) {
    return _datasource.updateProfile(firstName: firstName, lastName: lastName);
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return _datasource.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  @override
  Future<void> deleteAccount() async {
    await _datasource.deleteAccount();
    await _tokenStorage.clear();
  }

  Future<void> _persist(AuthSession session) {
    return _tokenStorage.writeTokens(
      access: session.accessToken,
      refresh: session.refreshToken,
    );
  }
}
