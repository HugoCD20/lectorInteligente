import '../../../translations/data/models/translation_model.dart';
import '../../domain/entities/reader_page_data.dart';

/// Modelo de datos de la lectura (capa de datos).
class ReaderPageModel extends ReaderPage {
  const ReaderPageModel({
    required super.pageNumber,
    super.originalContent,
    super.translatedContent,
  });

  factory ReaderPageModel.fromJson(Map<String, dynamic> json) =>
      ReaderPageModel(
        pageNumber: json['page_number'] as int,
        originalContent: (json['original_content'] as String?) ?? '',
        translatedContent: json['translated_content'] as String?,
      );
}

/// Modelo de resultado de lectura.
class ReaderPageDataModel extends ReaderPageData {
  const ReaderPageDataModel({
    required super.totalPages,
    required super.page,
    super.pageSize,
    super.targetLanguage,
    super.translation,
    super.pages,
  });

  factory ReaderPageDataModel.fromJson(Map<String, dynamic> json) =>
      ReaderPageDataModel(
        totalPages: json['total_pages'] as int,
        page: json['page'] as int,
        pageSize: (json['page_size'] as int?) ?? 1,
        targetLanguage: json['target_language'] as String?,
        translation: json['translation'] == null
            ? null
            : TranslationSummaryModel.fromJson(
                json['translation'] as Map<String, dynamic>,
              ),
        pages: (json['pages'] as List<dynamic>? ?? const [])
            .map((item) =>
                ReaderPageModel.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
}
