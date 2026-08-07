import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lector_inteligente/config/providers.dart';
import 'package:lector_inteligente/config/routes.dart';
import 'package:lector_inteligente/config/strings.dart';
import 'package:lector_inteligente/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:lector_inteligente/shared/widgets/app_navigation_bar.dart';

import '../helpers/fakes.dart';
import '../helpers/surface.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(onGenerateRoute: Routes.onGenerateRoute, home: child);
  }

  group('AppNavigationBar', () {
    testWidgets('sin autenticación muestra inicio de sesión y registro', (
      tester,
    ) async {
      configureLargeSurface(tester);
      final auth = AuthController(authRepository: FakeAuthRepository());
      await auth.restoreSession();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authControllerProvider.overrideWith((ref) => auth)],
          child: wrap(const Scaffold(appBar: AppNavigationBar())),
        ),
      );

      expect(find.text(AppStrings.login), findsOneWidget);
      expect(find.text(AppStrings.register), findsOneWidget);
      expect(find.text(AppStrings.profile), findsNothing);
    });

    testWidgets('autenticado muestra galería, perfil y cierre de sesión', (
      tester,
    ) async {
      configureLargeSurface(tester);
      final auth = AuthController(authRepository: FakeAuthRepository());
      auth.state = AuthState.authenticated(fakeUser);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authControllerProvider.overrideWith((ref) => auth)],
          child: wrap(const Scaffold(appBar: AppNavigationBar())),
        ),
      );

      expect(find.text(AppStrings.gallery), findsOneWidget);
      expect(find.text(AppStrings.profile), findsOneWidget);
      expect(find.byTooltip(AppStrings.logout), findsOneWidget);
      expect(find.text(AppStrings.login), findsNothing);
    });

    testWidgets('cierra sesión y muestra el aviso', (tester) async {
      configureLargeSurface(tester);
      final repository = FakeAuthRepository();
      final auth = AuthController(authRepository: repository);
      auth.state = AuthState.authenticated(fakeUser);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authControllerProvider.overrideWith((ref) => auth)],
          child: wrap(const Scaffold(appBar: AppNavigationBar())),
        ),
      );

      await tester.tap(find.byTooltip(AppStrings.logout));
      await tester.pump();
      await tester.pump();

      expect(auth.state.isAuthenticated, isFalse);
      expect(find.text(AppStrings.sessionClosed), findsOneWidget);
    });
  });
}
