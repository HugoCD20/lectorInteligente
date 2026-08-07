import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/document.dart';
import '../models/document_model.dart';

/// Fuente de datos remota de documentos.
class DocumentRemoteDatasource {
  DocumentRemoteDatasource({required ApiClient apiClient}) : _dio = apiClient.dio;

  final Dio _dio;

  Future<PaginatedDocuments> getGallery({
    required int page,
    String? search,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/documents/',
        queryParameters: {
          'page': page,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );
      final data = response.data!['data'] as Map<String, dynamic>;
      final results = (data['results'] as List<dynamic>)
          .map((item) => DocumentModel.fromJson(item as Map<String, dynamic>))
          .toList();
      return PaginatedDocuments(
        count: data['count'] as int,
        page: data['page'] as int? ?? page,
        pageSize: data['page_size'] as int? ?? results.length,
        next: data['next'] as String?,
        previous: data['previous'] as String?,
        documents: results,
      );
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  Future<List<Document>> getRecent({int limit = 5}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/documents/recent/',
        queryParameters: {'limit': limit},
      );
      final data = response.data!['data'] as List<dynamic>;
      return data
          .map((item) => DocumentModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  Future<Document> upload({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: fileName,
          contentType: DioMediaType.parse(mimeType),
        ),
      });
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/documents/upload/',
        data: formData,
      );
      final data = response.data!['data'] as Map<String, dynamic>;
      return DocumentModel.fromJson(data);
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete<Map<String, dynamic>>('/api/documents/$id/');
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }
}
