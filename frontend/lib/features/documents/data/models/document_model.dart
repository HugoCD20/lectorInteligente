import '../../../translations/data/models/translation_model.dart';
import '../../domain/entities/document.dart';

/// Modelo de datos del documento (capa de datos).
class DocumentModel extends Document {
  const DocumentModel({
    required super.id,
    required super.originalName,
    super.extension,
    super.mimeType,
    super.fileSize,
    super.fileUrl,
    super.translations,
    required super.createdAt,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) => DocumentModel(
        id: json['id'] as int,
        originalName: json['original_name'] as String,
        extension: (json['extension'] as String?) ?? '',
        mimeType: (json['mime_type'] as String?) ?? '',
        fileSize: (json['file_size'] as int?) ?? 0,
        fileUrl: (json['file'] as String?) ?? '',
        translations: (json['translations'] as List<dynamic>? ?? const [])
            .map((item) => TranslationSummaryModel.fromJson(
                item as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
      );
}
