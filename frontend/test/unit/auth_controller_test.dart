import 'package:flutter_test/flutter_test.dart';
import 'package:lector_inteligente/features/authentication/domain/entities/user.dart';
import 'package:lector_inteligente/features/authentication/presentation/controllers/auth_controller.dart';

import '../helpers/fakes.dart';

void main() {
  group('AuthController', () {
    test('estado inicial es desconocido', () {
      final controller = AuthController(authRepository: FakeAuthRepository());
      expect(controller.state.status, AuthStatus.unknown);
    });

    test('login autentica al usuario', () async {
      final controller = AuthController(authRepository: FakeAuthRepository());

      await controller.login(email: 'test@example.com', password: 'pass');

      expect(controller.state.status, AuthStatus.authenticated);
      expect(controller.state.user!.email, 'test@example.com');
      expect(controller.state.isAuthenticated, isTrue);
    });

    test('login fallido lanza y conserva el estado', () async {
      final controller = AuthController(
        authRepository: FakeAuthRepository(failOn: true),
      );

      await expectLater(
        controller.login(email: 'test@example.com', password: 'bad'),
        throwsA(isA<Exception>()),
      );
      expect(controller.state.status, AuthStatus.unknown);
    });

    test('register autentica al usuario', () async {
      final controller = AuthController(authRepository: FakeAuthRepository());

      await controller.register(
        email: 'test@example.com',
        password: 'pass',
        firstName: 'Ana',
      );

      expect(controller.state.status, AuthStatus.authenticated);
      expect(controller.state.user!.firstName, 'Ana');
    });

    test('restoreSession sin sesión queda sin autenticar', () async {
      final controller = AuthController(authRepository: FakeAuthRepository());

      await controller.restoreSession();

      expect(controller.state.status, AuthStatus.unauthenticated);
    });

    test('restoreSession con sesión autentica', () async {
      final repository = FakeAuthRepository()..sessionUser = fakeUser;
      final controller = AuthController(authRepository: repository);

      await controller.restoreSession();

      expect(controller.state.status, AuthStatus.authenticated);
      expect(controller.state.user!.id, fakeUser.id);
    });

    test('logout cierra la sesión', () async {
      final controller = AuthController(
        authRepository: FakeAuthRepository()..sessionUser = fakeUser,
      );
      await controller.restoreSession();
      expect(controller.state.isAuthenticated, isTrue);

      await controller.logout();

      expect(controller.state.status, AuthStatus.unauthenticated);
    });

    test('updateProfile actualiza el usuario', () async {
      final controller = AuthController(authRepository: FakeAuthRepository());
      await controller.login(email: 'test@example.com', password: 'pass');

      await controller.updateProfile(firstName: 'Nuevo');

      expect(controller.state.user, isA<User>());
      expect(controller.state.isAuthenticated, isTrue);
    });

    test('changePassword delega en el repositorio', () async {
      final repository = FakeAuthRepository();
      final controller = AuthController(authRepository: repository);

      await controller.changePassword(
        currentPassword: 'old',
        newPassword: 'new',
      );

      expect(repository.calls, contains('changePassword'));
    });
  });
}
