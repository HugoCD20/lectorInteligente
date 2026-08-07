import 'package:flutter_test/flutter_test.dart';
import 'package:lector_inteligente/features/documents/data/models/document_model.dart';
import 'package:lector_inteligente/features/documents/domain/entities/document.dart';

void main() {
  group('DocumentModel', () {
    test('fromJson construye el modelo completo', () {
      final model = DocumentModel.fromJson(const {
        'id': 5,
        'original_name': 'capitulo.pdf',
        'extension': 'pdf',
        'mime_type': 'application/pdf',
        'file_size': 2048,
        'file': '/api/documents/5/file/',
        'created_at': '2026-01-15T10:00:00Z',
        'translations': [
          {
            'id': 1,
            'target_language': 'en',
            'status': 'completed',
            'updated_at': '2026-01-15T11:00:00Z',
          },
        ],
      });

      expect(model.id, 5);
      expect(model.originalName, 'capitulo.pdf');
      expect(model.extension, 'pdf');
      expect(model.mimeType, 'application/pdf');
      expect(model.fileSize, 2048);
      expect(model.fileUrl, '/api/documents/5/file/');
      expect(model.createdAt, DateTime.utc(2026, 1, 15, 10));
      expect(model.translations, hasLength(1));
      expect(model.translations.single.targetLanguage, 'en');
    });

    test('fromJson usa valores por defecto cuando faltan campos', () {
      final model = DocumentModel.fromJson(const {
        'id': 1,
        'original_name': 'libro.pdf',
        'created_at': '2026-01-01T00:00:00Z',
      });

      expect(model.extension, '');
      expect(model.mimeType, '');
      expect(model.fileSize, 0);
      expect(model.fileUrl, '');
      expect(model.translations, isEmpty);
    });

    test('sizeLabel formatea bytes', () {
      DocumentModel small = DocumentModel.fromJson(const {
        'id': 1,
        'original_name': 'a.pdf',
        'file_size': 500,
        'created_at': '2026-01-01T00:00:00Z',
      });
      expect(small.sizeLabel, '500 B');

      DocumentModel kb = DocumentModel.fromJson(const {
        'id': 2,
        'original_name': 'b.pdf',
        'file_size': 2048,
        'created_at': '2026-01-01T00:00:00Z',
      });
      expect(kb.sizeLabel, '2.0 KB');

      DocumentModel mb = DocumentModel.fromJson(const {
        'id': 3,
        'original_name': 'c.pdf',
        'file_size': 5 * 1024 * 1024,
        'created_at': '2026-01-01T00:00:00Z',
      });
      expect(mb.sizeLabel, '5.0 MB');
    });

    test('hasMore refleja la paginación', () {
      const paginated = PaginatedDocuments(
        count: 10,
        page: 1,
        pageSize: 2,
        next: '/api/documents/?page=2',
        documents: [],
      );
      expect(paginated.hasMore, isTrue);

      const lastPage = PaginatedDocuments(
        count: 2,
        page: 1,
        pageSize: 2,
        documents: [],
      );
      expect(lastPage.hasMore, isFalse);
    });
  });
}
