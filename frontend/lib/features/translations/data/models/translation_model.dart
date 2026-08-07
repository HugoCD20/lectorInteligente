import '../../domain/entities/translation.dart';

/// Modelo de datos de traducciones (capa de datos).
class TranslationSummaryModel extends TranslationSummary {
  const TranslationSummaryModel({
    required super.id,
    super.sourceLanguage,
    required super.targetLanguage,
    super.status,
    super.totalPages,
    super.processedPages,
    super.failedPages,
    required super.updatedAt,
  });

  factory TranslationSummaryModel.fromJson(Map<String, dynamic> json) =>
      TranslationSummaryModel(
        id: json['id'] as int,
        sourceLanguage: (json['source_language'] as String?) ?? 'auto',
        targetLanguage: json['target_language'] as String,
        status: (json['status'] as String?) ?? 'pending',
        totalPages: (json['total_pages'] as int?) ?? 0,
        processedPages: (json['processed_pages'] as int?) ?? 0,
        failedPages: (json['failed_pages'] as int?) ?? 0,
        updatedAt:
            DateTime.tryParse(json['updated_at'] as String? ?? '') ??
                DateTime.now(),
      );
}

/// Modelo de página de traducción.
class TranslationPageModel extends TranslationPage {
  const TranslationPageModel({
    required super.pageNumber,
    super.originalContent,
    super.translatedContent,
    super.status,
  });

  factory TranslationPageModel.fromJson(Map<String, dynamic> json) =>
      TranslationPageModel(
        pageNumber: json['page_number'] as int,
        originalContent: (json['original_content'] as String?) ?? '',
        translatedContent: (json['translated_content'] as String?) ?? '',
        status: (json['status'] as String?) ?? 'pending',
      );
}

/// Modelo de detalle de traducción.
class TranslationDetailModel extends TranslationDetail {
  const TranslationDetailModel({required super.summary, super.pages});

  factory TranslationDetailModel.fromJson(Map<String, dynamic> json) =>
      TranslationDetailModel(
        summary: TranslationSummaryModel.fromJson(json),
        pages: (json['pages'] as List<dynamic>? ?? const [])
            .map((item) =>
                TranslationPageModel.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
}

/// Modelo de idioma disponible.
class TranslationLanguageModel extends TranslationLanguage {
  const TranslationLanguageModel({required super.code, required super.name});

  factory TranslationLanguageModel.fromJson(Map<String, dynamic> json) =>
      TranslationLanguageModel(
        code: json['code'] as String,
        name: (json['name'] as String?) ?? (json['code'] as String),
      );
}
