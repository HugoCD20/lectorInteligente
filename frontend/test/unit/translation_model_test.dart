import 'package:flutter_test/flutter_test.dart';
import 'package:lector_inteligente/features/translations/data/models/translation_model.dart';

void main() {
  group('TranslationSummaryModel', () {
    test('fromJson construye el modelo completo', () {
      final model = TranslationSummaryModel.fromJson(const {
        'id': 4,
        'source_language': 'es',
        'target_language': 'en',
        'status': 'completed',
        'total_pages': 10,
        'processed_pages': 10,
        'failed_pages': 0,
        'updated_at': '2026-01-15T11:00:00Z',
      });

      expect(model.id, 4);
      expect(model.sourceLanguage, 'es');
      expect(model.targetLanguage, 'en');
      expect(model.status, 'completed');
      expect(model.totalPages, 10);
      expect(model.processedPages, 10);
      expect(model.failedPages, 0);
      expect(model.updatedAt, DateTime.utc(2026, 1, 15, 11));
    });

    test('fromJson usa valores por defecto', () {
      final model = TranslationSummaryModel.fromJson(const {
        'id': 1,
        'target_language': 'fr',
        'updated_at': '2026-01-01T00:00:00Z',
      });

      expect(model.sourceLanguage, 'auto');
      expect(model.status, 'pending');
      expect(model.totalPages, 0);
      expect(model.processedPages, 0);
      expect(model.failedPages, 0);
    });

    test('isTerminal es cierto solo en estados finales', () {
      TranslationSummaryModel completed = TranslationSummaryModel.fromJson(
        const {
          'id': 1,
          'target_language': 'en',
          'status': 'completed',
          'updated_at': '2026-01-01T00:00:00Z',
        },
      );
      expect(completed.isTerminal, isTrue);

      TranslationSummaryModel pending = TranslationSummaryModel.fromJson(
        const {
          'id': 2,
          'target_language': 'en',
          'status': 'processing',
          'updated_at': '2026-01-01T00:00:00Z',
        },
      );
      expect(pending.isTerminal, isFalse);
    });
  });

  group('TranslationPageModel', () {
    test('fromJson construye el modelo completo', () {
      final model = TranslationPageModel.fromJson(const {
        'page_number': 2,
        'original_content': 'Original',
        'translated_content': 'Traducido',
        'status': 'completed',
      });

      expect(model.pageNumber, 2);
      expect(model.originalContent, 'Original');
      expect(model.translatedContent, 'Traducido');
      expect(model.status, 'completed');
    });

    test('fromJson usa valores por defecto', () {
      final model = TranslationPageModel.fromJson(const {
        'page_number': 1,
      });

      expect(model.originalContent, '');
      expect(model.translatedContent, '');
      expect(model.status, 'pending');
    });
  });

  group('TranslationDetailModel', () {
    test('fromJson construye detalle con páginas', () {
      final model = TranslationDetailModel.fromJson(const {
        'id': 1,
        'target_language': 'en',
        'status': 'completed',
        'updated_at': '2026-01-01T00:00:00Z',
        'pages': [
          {'page_number': 1, 'translated_content': 'X'},
          {'page_number': 2, 'translated_content': 'Y'},
        ],
      });

      expect(model.summary.targetLanguage, 'en');
      expect(model.pages, hasLength(2));
      expect(model.pages.first.translatedContent, 'X');
    });

    test('fromJson tolera páginas ausentes', () {
      final model = TranslationDetailModel.fromJson(const {
        'id': 1,
        'target_language': 'en',
        'updated_at': '2026-01-01T00:00:00Z',
      });

      expect(model.pages, isEmpty);
    });
  });

  group('TranslationLanguageModel', () {
    test('fromJson usa name o fallback al código', () {
      final named = TranslationLanguageModel.fromJson(
        const {'code': 'es', 'name': 'Spanish'},
      );
      expect(named.name, 'Spanish');

      final fallback = TranslationLanguageModel.fromJson(
        const {'code': 'fr'},
      );
      expect(fallback.name, 'fr');
    });
  });
}
