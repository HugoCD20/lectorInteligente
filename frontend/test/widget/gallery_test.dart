import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lector_inteligente/config/providers.dart';
import 'package:lector_inteligente/config/routes.dart';
import 'package:lector_inteligente/config/strings.dart';
import 'package:lector_inteligente/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:lector_inteligente/features/documents/presentation/controllers/documents_controller.dart';
import 'package:lector_inteligente/features/documents/presentation/pages/gallery_page.dart';
import 'package:lector_inteligente/features/translations/presentation/controllers/translation_controller.dart';

import '../helpers/fakes.dart';
import '../helpers/surface.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(onGenerateRoute: Routes.onGenerateRoute, home: child);
  }

  group('GalleryPage', () {
    testWidgets('sin autenticación muestra el mensaje de inicio de sesión', (
      tester,
    ) async {
      configureLargeSurface(tester);
      final auth = AuthController(authRepository: FakeAuthRepository());
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith((ref) => auth),
            documentsControllerProvider.overrideWith(
              (ref) => DocumentsController(
                documentRepository: FakeDocumentRepository(),
              ),
            ),
            translationsControllerProvider.overrideWith(
              (ref) => TranslationsController(
                repository: FakeTranslationRepository(),
              ),
            ),
          ],
          child: wrap(const GalleryPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.galleryLoginRequired), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('autenticado muestra la galería con los documentos', (
      tester,
    ) async {
      configureLargeSurface(tester);
      final auth = AuthController(authRepository: FakeAuthRepository());
      await auth.restoreSession();
      auth.state = AuthState.authenticated(fakeUser);

      final documentRepository = FakeDocumentRepository(
        documents: [makeDocument(id: 1, name: 'algoritmos.pdf')],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith((ref) => auth),
            documentsControllerProvider.overrideWith(
              (ref) => DocumentsController(documentRepository: documentRepository),
            ),
            translationsControllerProvider.overrideWith(
              (ref) => TranslationsController(
                repository: FakeTranslationRepository(),
              ),
            ),
          ],
          child: wrap(const GalleryPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('algoritmos.pdf'), findsOneWidget);
      expect(find.text(AppStrings.galleryLoginRequired), findsNothing);
    });

    testWidgets('con error de galería muestra el estado de error', (
      tester,
    ) async {
      configureLargeSurface(tester);
      final auth = AuthController(authRepository: FakeAuthRepository());
      auth.state = AuthState.authenticated(fakeUser);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith((ref) => auth),
            documentsControllerProvider.overrideWith(
              (ref) => DocumentsController(
                documentRepository: FakeDocumentRepository(failOnGallery: true),
              ),
            ),
            translationsControllerProvider.overrideWith(
              (ref) => TranslationsController(
                repository: FakeTranslationRepository(),
              ),
            ),
          ],
          child: wrap(const GalleryPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Error al cargar la galería.'), findsOneWidget);
    });
  });
}
