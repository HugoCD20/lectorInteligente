import 'package:flutter_test/flutter_test.dart';
import 'package:lector_inteligente/features/reader/data/models/reader_page_model.dart';

void main() {
  group('ReaderPageModel', () {
    test('fromJson construye el modelo completo', () {
      final model = ReaderPageModel.fromJson(const {
        'page_number': 3,
        'original_content': 'Original',
        'translated_content': 'Traducido',
      });

      expect(model.pageNumber, 3);
      expect(model.originalContent, 'Original');
      expect(model.translatedContent, 'Traducido');
    });

    test('fromJson conserva translated_content nulo', () {
      final model = ReaderPageModel.fromJson(const {
        'page_number': 1,
        'original_content': 'Original',
      });

      expect(model.translatedContent, isNull);
    });
  });

  group('ReaderPageDataModel', () {
    test('fromJson construye el resultado completo', () {
      final model = ReaderPageDataModel.fromJson(const {
        'total_pages': 5,
        'page': 2,
        'page_size': 1,
        'target_language': 'en',
        'translation': {
          'id': 1,
          'target_language': 'en',
          'status': 'completed',
          'updated_at': '2026-01-01T00:00:00Z',
        },
        'pages': [
          {
            'page_number': 2,
            'original_content': 'Contenido',
            'translated_content': 'Contenido traducido',
          },
        ],
      });

      expect(model.totalPages, 5);
      expect(model.page, 2);
      expect(model.targetLanguage, 'en');
      expect(model.translation, isNotNull);
      expect(model.translation!.targetLanguage, 'en');
      expect(model.pages, hasLength(1));
      expect(model.pages.single.translatedContent, 'Contenido traducido');
    });

    test('fromJson sin traducción deja translation nulo', () {
      final model = ReaderPageDataModel.fromJson(const {
        'total_pages': 1,
        'page': 1,
        'pages': [
          {'page_number': 1, 'original_content': 'X'},
        ],
      });

      expect(model.translation, isNull);
      expect(model.targetLanguage, isNull);
      expect(model.pageSize, 1);
    });
  });
}
