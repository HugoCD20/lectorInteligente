import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lector_inteligente/config/providers.dart';
import 'package:lector_inteligente/config/routes.dart';
import 'package:lector_inteligente/config/strings.dart';
import 'package:lector_inteligente/features/documents/domain/entities/document.dart';
import 'package:lector_inteligente/features/reader/presentation/controllers/reader_controller.dart';
import 'package:lector_inteligente/features/reader/presentation/pages/document_reader_page.dart';

import '../helpers/fakes.dart';
import '../helpers/surface.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(onGenerateRoute: Routes.onGenerateRoute, home: child);
  }

  final document = Document(
    id: 1,
    originalName: 'libro.pdf',
    extension: 'pdf',
    mimeType: 'application/pdf',
    fileSize: 2048,
    createdAt: DateTime(2026, 1, 1),
    translations: [makeTranslation(target: 'en', status: 'completed')],
  );

  group('DocumentReaderPage', () {
    testWidgets('muestra el contenido de la página actual y la traducción', (
      tester,
    ) async {
      configureLargeSurface(tester);
      final reader = ReaderController(repository: FakeReaderRepository());
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            readerControllerProvider.overrideWith((ref) => reader),
          ],
          child: wrap(DocumentReaderPage(document: document)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Contenido de la página 1'), findsOneWidget);
      expect(find.text('[en] página 1'), findsOneWidget);
      expect(find.text(AppStrings.readerPageOf(1, 3)), findsOneWidget);
    });

    testWidgets('con error muestra el estado de error y reintenta', (
      tester,
    ) async {
      configureLargeSurface(tester);
      final repository = FakeReaderRepository(failOn: true);
      final reader = ReaderController(repository: repository);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            readerControllerProvider.overrideWith((ref) => reader),
          ],
          child: wrap(DocumentReaderPage(document: document)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No se pudo leer la página.'), findsOneWidget);
      expect(find.text(AppStrings.retry), findsOneWidget);
    });
  });
}
