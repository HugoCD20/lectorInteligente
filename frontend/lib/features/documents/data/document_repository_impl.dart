import 'dart:typed_data';

import '../domain/entities/document.dart';
import '../domain/repositories/document_repository.dart';
import 'datasources/document_remote_datasource.dart';

/// Implementación del repositorio de documentos.
class DocumentRepositoryImpl implements DocumentRepository {
  DocumentRepositoryImpl({required this.datasource});

  final DocumentRemoteDatasource datasource;

  @override
  Future<PaginatedDocuments> getGallery({int page = 1, String? search}) {
    return datasource.getGallery(page: page, search: search);
  }

  @override
  Future<List<Document>> getRecent({int limit = 5}) {
    return datasource.getRecent(limit: limit);
  }

  @override
  Future<Document> upload({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) {
    return datasource.upload(
      fileName: fileName,
      bytes: bytes,
      mimeType: mimeType,
    );
  }

  @override
  Future<void> delete(int id) => datasource.delete(id);
}
