import '../domain/entities/reader_page_data.dart';
import '../domain/repositories/reader_repository.dart';
import 'datasources/reader_remote_datasource.dart';

/// Implementación del repositorio del lector.
class ReaderRepositoryImpl implements ReaderRepository {
  ReaderRepositoryImpl({required this.datasource});

  final ReaderRemoteDatasource datasource;

  @override
  Future<ReaderPageData> readPage({
    required int documentId,
    required int page,
    int pageSize = 1,
    String? targetLanguage,
  }) {
    return datasource.readPage(
      documentId: documentId,
      page: page,
      pageSize: pageSize,
      targetLanguage: targetLanguage,
    );
  }
}
