import '../domain/entities/translation.dart';
import '../domain/repositories/translation_repository.dart';
import 'datasources/translation_remote_datasource.dart';

/// Implementación del repositorio de traducciones.
class TranslationRepositoryImpl implements TranslationRepository {
  TranslationRepositoryImpl({required this.datasource});

  final TranslationRemoteDatasource datasource;

  @override
  Future<TranslationSummary> translate({
    required int documentId,
    required String targetLanguage,
  }) {
    return datasource.translate(
      documentId: documentId,
      targetLanguage: targetLanguage,
    );
  }

  @override
  Future<List<TranslationSummary>> getTranslations(int documentId) {
    return datasource.getTranslations(documentId);
  }

  @override
  Future<TranslationDetail> getTranslationDetail({
    required int documentId,
    required String targetLanguage,
  }) {
    return datasource.getTranslationDetail(
      documentId: documentId,
      targetLanguage: targetLanguage,
    );
  }

  @override
  Future<void> delete({
    required int documentId,
    required String targetLanguage,
  }) {
    return datasource.deleteTranslation(
      documentId: documentId,
      targetLanguage: targetLanguage,
    );
  }

  @override
  Future<List<TranslationLanguage>> getLanguages() {
    return datasource.getLanguages();
  }
}
