/// Entidades de traducción del dominio.
library;

/// Resumen de una traducción (una por documento e idioma destino).
class TranslationSummary {
  const TranslationSummary({
    required this.id,
    this.sourceLanguage = 'auto',
    required this.targetLanguage,
    this.status = 'pending',
    this.totalPages = 0,
    this.processedPages = 0,
    this.failedPages = 0,
    required this.updatedAt,
  });

  final int id;
  final String sourceLanguage;
  final String targetLanguage;
  final String status;
  final int totalPages;
  final int processedPages;
  final int failedPages;
  final DateTime updatedAt;

  bool get isTerminal =>
      status == 'completed' || status == 'partial' || status == 'failed';
}

/// Página traducida de una traducción.
class TranslationPage {
  const TranslationPage({
    required this.pageNumber,
    this.originalContent = '',
    this.translatedContent = '',
    this.status = 'pending',
  });

  final int pageNumber;
  final String originalContent;
  final String translatedContent;
  final String status;
}

/// Detalle de una traducción con sus páginas.
class TranslationDetail {
  const TranslationDetail({
    required this.summary,
    this.pages = const [],
  });

  final TranslationSummary summary;
  final List<TranslationPage> pages;
}

/// Idioma disponible en el motor de traducción.
class TranslationLanguage {
  const TranslationLanguage({required this.code, required this.name});

  final String code;
  final String name;
}
