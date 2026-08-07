import 'package:dio/dio.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/user.dart';
import '../models/user_model.dart';

/// Fuente de datos remota de autenticación.
class AuthRemoteDatasource {
  AuthRemoteDatasource({required ApiClient apiClient}) : _dio = apiClient.dio;

  final Dio _dio;

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/auth/login/',
        data: {'email': email, 'password': password},
      );
      return _sessionFromBody(response.data!);
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  Future<AuthSession> register({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/auth/register/',
        data: {
          'email': email,
          'password': password,
          if (firstName != null && firstName.isNotEmpty) 'first_name': firstName,
          if (lastName != null && lastName.isNotEmpty) 'last_name': lastName,
        },
      );
      return _sessionFromBody(response.data!);
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  Future<void> logout(String refreshToken) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/api/auth/logout/',
        data: {'refresh': refreshToken},
      );
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  Future<User> getCurrentUser() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/api/users/me/');
      final data = response.data!['data'] as Map<String, dynamic>;
      return UserModel.fromJson(data);
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  Future<User> updateProfile({
    String? firstName,
    String? lastName,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/api/users/me/',
        data: {
          'first_name': ?firstName,
          'last_name': ?lastName,
        },
      );
      final data = response.data!['data'] as Map<String, dynamic>;
      return UserModel.fromJson(data);
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/api/users/change-password/',
        data: {'current_password': currentPassword, 'new_password': newPassword},
      );
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  Future<void> deleteAccount() async {
    try {
      await _dio.delete<Map<String, dynamic>>('/api/users/me/');
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  AuthSession _sessionFromBody(Map<String, dynamic> body) {
    final data = body['data'] as Map<String, dynamic>;
    final userData = data['user'] as Map<String, dynamic>;
    final tokens = data['tokens'] as Map<String, dynamic>;
    return AuthSession(
      user: UserModel.fromJson(userData),
      accessToken: tokens['access'] as String,
      refreshToken: tokens['refresh'] as String,
    );
  }
}
