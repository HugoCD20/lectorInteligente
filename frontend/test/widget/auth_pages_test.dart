import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lector_inteligente/config/providers.dart';
import 'package:lector_inteligente/config/routes.dart';
import 'package:lector_inteligente/config/strings.dart';
import 'package:lector_inteligente/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:lector_inteligente/features/authentication/presentation/login_page.dart';
import 'package:lector_inteligente/features/authentication/presentation/register_page.dart';

import '../helpers/fakes.dart';
import '../helpers/surface.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(onGenerateRoute: Routes.onGenerateRoute, home: child);
  }

  group('LoginPage', () {
    testWidgets('muestra errores de validación con campos vacíos', (
      tester,
    ) async {
      configureLargeSurface(tester);
      final authRepository = FakeAuthRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(
              (ref) => AuthController(authRepository: authRepository),
            ),
          ],
          child: wrap(const LoginPage()),
        ),
      );

      await tester.tap(find.text(AppStrings.login));
      await tester.pump();

      expect(find.text(AppStrings.requiredField), findsNWidgets(2));
      expect(authRepository.calls, isNot(contains('login')));
    });

    testWidgets('muestra error del repositorio en un SnackBar', (tester) async {
      configureLargeSurface(tester);
      final authRepository = FakeAuthRepository(failOn: true);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(
              (ref) => AuthController(authRepository: authRepository),
            ),
          ],
          child: wrap(const LoginPage()),
        ),
      );

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'test@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.tap(find.text(AppStrings.login));
      await tester.pump();
      await tester.pump();

      expect(find.text('Credenciales inválidas.'), findsOneWidget);
      expect(authRepository.calls, contains('login'));
    });
  });

  group('RegisterPage', () {
    testWidgets('muestra error de validación de contraseña corta', (
      tester,
    ) async {
      configureLargeSurface(tester);
      await tester.pumpWidget(
        ProviderScope(child: wrap(const RegisterPage())),
      );

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'test@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(3), 'corta');
      await tester.enterText(find.byType(TextFormField).at(4), 'corta');
      await tester.tap(find.text(AppStrings.register));
      await tester.pump();

      expect(find.text(AppStrings.shortPassword), findsOneWidget);
    });

    testWidgets('registra al usuario y navega a la página de inicio', (
      tester,
    ) async {
      configureLargeSurface(tester);
      final authRepository = FakeAuthRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(
              (ref) => AuthController(authRepository: authRepository),
            ),
          ],
          child: wrap(const RegisterPage()),
        ),
      );

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'test@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'Ana');
      await tester.enterText(find.byType(TextFormField).at(2), 'Pérez');
      await tester.enterText(find.byType(TextFormField).at(3), 'password123');
      await tester.enterText(find.byType(TextFormField).at(4), 'password123');
      await tester.tap(find.text(AppStrings.register));
      await tester.pump();
      await tester.pump();

      expect(authRepository.calls, contains('register'));
    });
  });
}
