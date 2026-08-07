import 'package:dio/dio.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/reader_page_data.dart';
import '../models/reader_page_model.dart';

/// Fuente de datos remota del lector.
class ReaderRemoteDatasource {
  ReaderRemoteDatasource({required ApiClient apiClient}) : _dio = apiClient.dio;

  final Dio _dio;

  Future<ReaderPageData> readPage({
    required int documentId,
    required int page,
    int pageSize = 1,
    String? targetLanguage,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/documents/$documentId/read/',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
          'target_language': ?targetLanguage,
        },
      );
      final data = response.data!['data'] as Map<String, dynamic>;
      return ReaderPageDataModel.fromJson(data);
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }
}
