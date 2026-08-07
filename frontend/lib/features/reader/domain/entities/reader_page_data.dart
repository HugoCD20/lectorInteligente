import '../../../translations/domain/entities/translation.dart';

/// Página del lector (contenido original y, si existe, su traducción).
class ReaderPage {
  const ReaderPage({
    required this.pageNumber,
    this.originalContent = '',
    this.translatedContent,
  });

  final int pageNumber;
  final String originalContent;
  final String? translatedContent;
}

/// Resultado de una consulta de lectura (ventana de páginas).
class ReaderPageData {
  const ReaderPageData({
    required this.totalPages,
    required this.page,
    this.pageSize = 1,
    this.targetLanguage,
    this.translation,
    this.pages = const [],
  });

  final int totalPages;
  final int page;
  final int pageSize;
  final String? targetLanguage;
  final TranslationSummary? translation;
  final List<ReaderPage> pages;
}
