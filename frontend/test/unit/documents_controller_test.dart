import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lector_inteligente/features/documents/presentation/controllers/documents_controller.dart';

import '../helpers/fakes.dart';

void main() {
  group('DocumentsController', () {
    test('loadRecent carga los documentos recientes', () async {
      final controller = DocumentsController(
        documentRepository: FakeDocumentRepository(recent: [makeDocument()]),
      );

      await controller.loadRecent();

      expect(controller.state.recent, hasLength(1));
      expect(controller.state.recentError, isNull);
    });

    test('loadRecent falla y guarda el error', () async {
      final controller = DocumentsController(
        documentRepository: FakeDocumentRepository(),
      );

      controller.loadRecent();
      await Future<void>.delayed(Duration.zero);

      expect(controller.state.recent, isEmpty);
    });

    test('loadGallery carga la primera página', () async {
      final repository = FakeDocumentRepository(
        documents: [
          makeDocument(id: 1, name: 'a.pdf'),
          makeDocument(id: 2, name: 'b.pdf'),
          makeDocument(id: 3, name: 'c.pdf'),
        ],
      );
      final controller = DocumentsController(documentRepository: repository);

      await controller.loadGallery();

      expect(controller.state.documents, hasLength(2));
      expect(controller.state.hasMore, isTrue);
      expect(controller.state.loadingGallery, isFalse);
    });

    test('loadGallery acumula páginas siguientes', () async {
      final repository = FakeDocumentRepository(
        documents: List.generate(4, (i) => makeDocument(id: i + 1)),
      );
      final controller = DocumentsController(documentRepository: repository);

      await controller.loadGallery();
      await controller.loadGallery();

      expect(controller.state.documents, hasLength(4));
      expect(controller.state.hasMore, isFalse);
      expect(controller.state.page, 2);
    });

    test('loadGallery con refresh reemplaza la lista', () async {
      final repository = FakeDocumentRepository(
        documents: List.generate(3, (i) => makeDocument(id: i + 1)),
      );
      final controller = DocumentsController(documentRepository: repository);

      await controller.loadGallery();
      await controller.loadGallery(refresh: true);

      expect(controller.state.documents, hasLength(2));
      expect(controller.state.page, 2);
    });

    test('loadGallery falla y guarda el error', () async {
      final controller = DocumentsController(
        documentRepository: FakeDocumentRepository(failOnGallery: true),
      );

      await controller.loadGallery();

      expect(controller.state.galleryError, isNotNull);
      expect(controller.state.loadingGallery, isFalse);
    });

    test('setSearch vacía la galería y filtra por el término', () async {
      final repository = FakeDocumentRepository(
        documents: [makeDocument(id: 1, name: 'algoritmos.pdf')],
      );
      final controller = DocumentsController(documentRepository: repository);

      controller.setSearch('historia');
      await Future<void>.delayed(Duration.zero);

      expect(controller.state.documents, isEmpty);
      expect(controller.state.hasMore, isFalse);
      expect(controller.state.page, 1);
    });

    test('upload agrega a recientes y recarga la galería', () async {
      final repository = FakeDocumentRepository(
        documents: [makeDocument(id: 1)],
      );
      final controller = DocumentsController(documentRepository: repository);

      final document = await controller.upload(
        fileName: 'nuevo.pdf',
        bytes: Uint8List.fromList([1, 2, 3]),
        mimeType: 'application/pdf',
      );

      expect(document.id, 99);
      expect(controller.state.uploading, isFalse);
      expect(controller.state.recent.first.id, 99);
      expect(controller.state.recentError, isNull);
    });

    test('upload fallido guarda el error y relanza', () async {
      final controller = DocumentsController(
        documentRepository: FakeDocumentRepository(failOnUpload: true),
      );

      await expectLater(
        controller.upload(
          fileName: 'malo.pdf',
          bytes: Uint8List.fromList([1]),
          mimeType: 'application/pdf',
        ),
        throwsA(isA<Exception>()),
      );

      expect(controller.state.uploading, isFalse);
      expect(controller.state.uploadError, isNotNull);
    });

    test('delete elimina el documento de la lista', () async {
      final repository = FakeDocumentRepository(
        documents: [makeDocument(id: 1), makeDocument(id: 2)],
      );
      final controller = DocumentsController(documentRepository: repository);
      await controller.loadGallery();

      await controller.delete(1);

      expect(repository.deletedIds, [1]);
      expect(controller.state.documents.map((d) => d.id), isNot(contains(1)));
      expect(controller.state.deletingIds, isEmpty);
    });
  });
}
