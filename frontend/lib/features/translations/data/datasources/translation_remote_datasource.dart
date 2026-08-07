import 'package:dio/dio.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/translation.dart';
import '../models/translation_model.dart';

/// Fuente de datos remota de traducciones.
class TranslationRemoteDatasource {
  TranslationRemoteDatasource({required ApiClient apiClient})
      : _dio = apiClient.dio;

  final Dio _dio;

  Future<TranslationSummary> translate({
    required int documentId,
    required String targetLanguage,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/documents/$documentId/translate/',
        data: {'target_language': targetLanguage},
      );
      final data = response.data!['data'] as Map<String, dynamic>;
      return TranslationSummaryModel.fromJson(data);
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  Future<List<TranslationSummary>> getTranslations(int documentId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/documents/$documentId/translations/',
      );
      final data = response.data!['data'] as List<dynamic>;
      return data
          .map((item) =>
              TranslationSummaryModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  Future<TranslationDetail> getTranslationDetail({
    required int documentId,
    required String targetLanguage,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/documents/$documentId/translations/$targetLanguage/',
      );
      final data = response.data!['data'] as Map<String, dynamic>;
      return TranslationDetailModel.fromJson(data);
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  Future<void> deleteTranslation({
    required int documentId,
    required String targetLanguage,
  }) async {
    try {
      await _dio.delete<Map<String, dynamic>>(
        '/api/documents/$documentId/translations/$targetLanguage/',
      );
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  Future<List<TranslationLanguage>> getLanguages() async {
    try {
      final response =
          await _dio.get<Map<String, dynamic>>('/api/translation/languages/');
      final data = response.data!['data'] as List<dynamic>;
      return data
          .map((item) => TranslationLanguageModel.fromJson(
              item as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }
}
