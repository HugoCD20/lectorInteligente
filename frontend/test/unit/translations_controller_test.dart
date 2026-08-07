import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lector_inteligente/features/translations/domain/entities/translation.dart';
import 'package:lector_inteligente/features/translations/presentation/controllers/translation_controller.dart';

import '../helpers/fakes.dart';

void main() {
  const languages = [
    TranslationLanguage(code: 'en', name: 'English'),
    TranslationLanguage(code: 'es', name: 'Spanish'),
  ];

  group('TranslationsController', () {
    test('loadLanguages carga los idiomas', () async {
      final controller = TranslationsController(
        repository: FakeTranslationRepository(languages: languages),
      );

      await controller.loadLanguages();

      expect(controller.state.languages, hasLength(2));
      expect(controller.state.loadingLanguages, isFalse);
      expect(controller.state.languagesError, isNull);
    });

    test('loadLanguages falla y guarda el error', () async {
      final controller = TranslationsController(
        repository: FakeTranslationRepository(failOn: true),
      );

      await controller.loadLanguages();

      expect(controller.state.languagesError, isNotNull);
      expect(controller.state.loadingLanguages, isFalse);
    });

    test('translate guarda el resumen y completa el sondeo', () {
      final controller = TranslationsController(
        repository: FakeTranslationRepository(
          translationsFor: {
            1: [
              TranslationSummary(
                id: 1,
                targetLanguage: 'en',
                status: 'completed',
                updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
              ),
            ],
          },
        ),
      );

      fakeAsync((async) {
        controller.translate(documentId: 1, targetLanguage: 'en');
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 2));
        async.flushMicrotasks();

        expect(controller.state.summariesFor(1), hasLength(1));
        expect(controller.state.summariesFor(1).single.targetLanguage, 'en');
        expect(controller.state.translatingIds, isEmpty);
      });
    });

    test('translate fallido guarda el error y relanza', () async {
      final controller = TranslationsController(
        repository: FakeTranslationRepository(failOn: true),
      );

      await expectLater(
        controller.translate(documentId: 1, targetLanguage: 'en'),
        throwsA(isA<Exception>()),
      );

      expect(controller.state.error, isNotNull);
      expect(controller.state.translatingIds, isEmpty);
    });

    test('refresh guarda resúmenes terminales sin sondeo', () async {
      final controller = TranslationsController(
        repository: FakeTranslationRepository(
          translationsFor: {
            1: [
              TranslationSummary(
                id: 1,
                targetLanguage: 'en',
                status: 'completed',
                updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
              ),
            ],
          },
        ),
      );

      await controller.refresh(1);

      expect(controller.state.summariesFor(1).single.status, 'completed');
    });

    test('delete elimina la traducción seleccionada', () async {
      final controller = TranslationsController(
        repository: FakeTranslationRepository(
          translationsFor: {
            1: [
              TranslationSummary(
                id: 1,
                targetLanguage: 'en',
                status: 'completed',
                updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
              ),
              TranslationSummary(
                id: 2,
                targetLanguage: 'fr',
                status: 'completed',
                updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
              ),
            ],
          },
        ),
      );
      await controller.refresh(1);

      await controller.delete(documentId: 1, targetLanguage: 'en');

      final remaining = controller.state.summariesFor(1);
      expect(remaining.map((s) => s.targetLanguage), ['fr']);
      expect(controller.state.deletingIds, isEmpty);
    });

    test('summariesFor devuelve lista vacía sin traducciones', () {
      final controller = TranslationsController(
        repository: FakeTranslationRepository(),
      );

      expect(controller.state.summariesFor(99), isEmpty);
      expect(controller.state.isDeleting(1, 'en'), isFalse);
    });
  });
}
