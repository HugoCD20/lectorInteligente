import 'package:flutter_test/flutter_test.dart';
import 'package:lector_inteligente/features/reader/presentation/controllers/reader_controller.dart';

import '../helpers/fakes.dart';

Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  group('ReaderController', () {
    test('open selecciona el primer idioma disponible', () async {
      final controller = ReaderController(repository: FakeReaderRepository());
      final translations = [
        makeTranslation(target: 'fr'),
        makeTranslation(target: 'en', status: 'completed'),
      ];

      controller.open(
        documentId: 1,
        documentName: 'libro.pdf',
        translations: translations,
      );
      await settle();

      expect(controller.state.availableLanguages, ['en']);
      expect(controller.state.targetLanguage, 'en');
      expect(controller.state.pages[1], isNotNull);
      expect(controller.state.totalPages, 3);
    });

    test('open sin traducciones no fija idioma', () async {
      final controller = ReaderController(repository: FakeReaderRepository());

      controller.open(
        documentId: 1,
        documentName: 'libro.pdf',
        translations: const [],
      );
      await settle();

      expect(controller.state.targetLanguage, isNull);
      expect(controller.state.hasTranslation, isFalse);
    });

    test('goToPage carga la página solicitada', () async {
      final controller = ReaderController(repository: FakeReaderRepository());

      controller.open(
        documentId: 1,
        documentName: 'libro.pdf',
        translations: const [],
      );
      await settle();
      controller.goToPage(2);
      await settle();

      expect(controller.state.currentPage, 2);
      expect(controller.state.pages[2], isNotNull);
    });

    test('goToPage a página cacheada no vuelve a consultar', () async {
      final repository = FakeReaderRepository();
      final controller = ReaderController(repository: repository);

      controller.open(
        documentId: 1,
        documentName: 'libro.pdf',
        translations: const [],
      );
      await settle();
      controller.goToPage(2);
      await settle();
      final requestsBefore = repository.requestedPages.length;

      controller.goToPage(2);
      await settle();

      expect(repository.requestedPages.length, requestsBefore);
      expect(controller.state.currentPage, 2);
    });

    test('nextPage y previousPage respetan los límites', () async {
      final controller = ReaderController(repository: FakeReaderRepository());

      controller.open(
        documentId: 1,
        documentName: 'libro.pdf',
        translations: const [],
      );
      await settle();

      controller.nextPage();
      await settle();
      expect(controller.state.currentPage, 2);

      controller.nextPage();
      await settle();
      expect(controller.state.currentPage, 3);

      controller.nextPage();
      await settle();
      expect(controller.state.currentPage, 3);

      controller.previousPage();
      await settle();
      expect(controller.state.currentPage, 2);

      controller.previousPage();
      controller.previousPage();
      controller.previousPage();
      await settle();
      expect(controller.state.currentPage, 1);
    });

    test('fallo de lectura guarda el error y retry reintenta', () async {
      final repository = FakeReaderRepository(failOn: true);
      final controller = ReaderController(repository: repository);

      controller.open(
        documentId: 1,
        documentName: 'libro.pdf',
        translations: const [],
      );
      await settle();

      expect(controller.state.error, isNotNull);
      expect(controller.state.loading, isFalse);

      controller.retry();
      await settle();

      expect(controller.state.error, isNotNull);
    });

    test('setTargetLanguage reinicia la lectura con el nuevo idioma', () async {
      final controller = ReaderController(repository: FakeReaderRepository());
      final translations = [
        makeTranslation(target: 'en', status: 'completed'),
        makeTranslation(target: 'fr', status: 'completed'),
      ];

      controller.open(
        documentId: 1,
        documentName: 'libro.pdf',
        translations: translations,
      );
      await settle();
      expect(controller.state.targetLanguage, 'en');

      controller.setTargetLanguage('fr');
      await settle();

      expect(controller.state.targetLanguage, 'fr');
      expect(controller.state.currentPage, 1);
      expect(controller.state.pages[1]?.translatedContent, '[fr] página 1');
    });
  });
}
