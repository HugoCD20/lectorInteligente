import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

enum AuthStatus { unknown, unauthenticated, authenticated }

/// Estado de autenticación de la aplicación.
class AuthState {
  const AuthState._({required this.status, this.user});

  const AuthState.unknown() : this._(status: AuthStatus.unknown);

  const AuthState.unauthenticated() : this._(status: AuthStatus.unauthenticated);

  const AuthState.authenticated(User user)
      : this._(status: AuthStatus.authenticated, user: user);

  final AuthStatus status;
  final User? user;

  bool get isAuthenticated => status == AuthStatus.authenticated;
}

/// Controlador de la sesión de autenticación.
class AuthController extends StateNotifier<AuthState> {
  AuthController({required this._authRepository})
      : super(const AuthState.unknown());

  final AuthRepository _authRepository;

  Future<void> restoreSession() async {
    final user = await _authRepository.restoreSession();
    state = user == null
        ? const AuthState.unauthenticated()
        : AuthState.authenticated(user);
  }

  Future<void> login({required String email, required String password}) async {
    final session = await _authRepository.login(email: email, password: password);
    state = AuthState.authenticated(session.user);
  }

  Future<void> register({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    final session = await _authRepository.register(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
    );
    state = AuthState.authenticated(session.user);
  }

  Future<void> logout() async {
    await _authRepository.logout();
    state = const AuthState.unauthenticated();
  }

  Future<void> updateProfile({String? firstName, String? lastName}) async {
    final user = await _authRepository.updateProfile(
      firstName: firstName,
      lastName: lastName,
    );
    state = AuthState.authenticated(user);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return _authRepository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  Future<void> deleteAccount() async {
    await _authRepository.deleteAccount();
    state = const AuthState.unauthenticated();
  }
}
