import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lector_inteligente/core/errors/app_exception.dart';
import 'package:lector_inteligente/core/errors/error_mapper.dart';

void main() {
  DioException dioException(DioExceptionType type, {Object? data}) {
    return DioException(
      requestOptions: RequestOptions(path: '/api/test/'),
      type: type,
      response: data == null
          ? null
          : Response<Object?>(
              requestOptions: RequestOptions(path: '/api/test/'),
              data: data,
            ),
    );
  }

  group('mapDioError', () {
    test('usa el mensaje del servidor cuando existe', () {
      final error = dioException(
        DioExceptionType.badResponse,
        data: {'message': 'La contraseña actual es incorrecta.'},
      );

      final mapped = mapDioError(error);

      expect(mapped, isA<AppException>());
      expect(mapped.message, 'La contraseña actual es incorrecta.');
    });

    test('errores de conexión devuelven mensaje amigable', () {
      for (final type in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.connectionError,
      ]) {
        final mapped = mapDioError(dioException(type));
        expect(mapped.message, 'No se pudo conectar con el servidor. Inténtalo nuevamente.');
      }
    });

    test('otros errores devuelven mensaje inesperado', () {
      for (final type in [
        DioExceptionType.cancel,
        DioExceptionType.badCertificate,
        DioExceptionType.badResponse,
        DioExceptionType.unknown,
        DioExceptionType.transformTimeout,
      ]) {
        final mapped = mapDioError(dioException(type));
        expect(mapped.message, 'Ocurrió un error inesperado. Inténtalo nuevamente.');
      }
    });

    test('errores no-Dio devuelven mensaje genérico', () {
      final mapped = mapDioError(StateError('boom'));
      expect(mapped.message, 'Ocurrió un error inesperado.');
    });
  });
}
