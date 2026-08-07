import 'dart:typed_data';

import '../entities/document.dart';

/// Contrato del repositorio de documentos.
abstract class DocumentRepository {
  Future<PaginatedDocuments> getGallery({int page = 1, String? search});

  Future<List<Document>> getRecent({int limit = 5});

  Future<Document> upload({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  });

  Future<void> delete(int id);
}
