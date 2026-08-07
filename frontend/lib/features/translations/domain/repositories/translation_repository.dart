import '../entities/translation.dart';

/// Contrato del repositorio de traducciones.
abstract class TranslationRepository {
  Future<TranslationSummary> translate({
    required int documentId,
    required String targetLanguage,
  });

  Future<List<TranslationSummary>> getTranslations(int documentId);

  Future<TranslationDetail> getTranslationDetail({
    required int documentId,
    required String targetLanguage,
  });

  Future<void> delete({
    required int documentId,
    required String targetLanguage,
  });

  Future<List<TranslationLanguage>> getLanguages();
}
