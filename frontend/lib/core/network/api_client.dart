import 'package:dio/dio.dart';

import '../../config/environment.dart';
import '../storage/token_storage.dart';

/// Cliente HTTP centralizado de la aplicación.
///
/// Agrega automáticamente el token de acceso en cada solicitud.
class ApiClient {
  ApiClient({required this._tokenStorage})
      : _dio = Dio(
          BaseOptions(
            baseUrl: AppEnvironment.apiBaseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 15),
            headers: {'Content-Type': 'application/json'},
          ),
        ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.readAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  final TokenStorage _tokenStorage;
  final Dio _dio;

  Dio get dio => _dio;
}
