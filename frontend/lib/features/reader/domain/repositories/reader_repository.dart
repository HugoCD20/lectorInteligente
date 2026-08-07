import '../entities/reader_page_data.dart';

/// Contrato del repositorio del lector.
abstract class ReaderRepository {
  Future<ReaderPageData> readPage({
    required int documentId,
    required int page,
    int pageSize = 1,
    String? targetLanguage,
  });
}
