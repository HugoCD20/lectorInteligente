import 'package:dio/dio.dart';

import 'app_exception.dart';

/// Convierte errores técnicos en [AppException] con mensaje amigable.
AppException mapDioError(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map<String, dynamic> && data['message'] is String) {
      return AppException(data['message'] as String);
    }
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.connectionError:
        return const AppException(
          'No se pudo conectar con el servidor. Inténtalo nuevamente.',
        );
      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
      case DioExceptionType.transformTimeout:
        return const AppException(
          'Ocurrió un error inesperado. Inténtalo nuevamente.',
        );
    }
  }
  return const AppException('Ocurrió un error inesperado.');
}
