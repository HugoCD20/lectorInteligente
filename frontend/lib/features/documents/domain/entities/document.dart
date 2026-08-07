import '../../../translations/domain/entities/translation.dart';

/// Entidad de documento del dominio.
class Document {
  const Document({
    required this.id,
    required this.originalName,
    this.extension = '',
    this.mimeType = '',
    this.fileSize = 0,
    this.fileUrl = '',
    this.translations = const [],
    required this.createdAt,
  });

  final int id;
  final String originalName;
  final String extension;
  final String mimeType;
  final int fileSize;
  final String fileUrl;
  final List<TranslationSummary> translations;
  final DateTime createdAt;

  String get sizeLabel {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Resultado paginado de la galería.
class PaginatedDocuments {
  const PaginatedDocuments({
    required this.count,
    required this.page,
    required this.pageSize,
    this.next,
    this.previous,
    required this.documents,
  });

  final int count;
  final int page;
  final int pageSize;
  final String? next;
  final String? previous;
  final List<Document> documents;

  bool get hasMore => next != null;
}
