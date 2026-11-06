import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/auth_interceptor.dart';
import '../models/auth_models.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._dio);

  final Dio _dio;

  /// Public endpoints go out without a token and never trigger a refresh.
  Options get _public => Options(extra: {AuthInterceptor.skipAuth: true});

  Future<LoginResponseModel> login(String email, String password) async {
    final res = await _dio.post<dynamic>(
      ApiEndpoints.login,
      data: {'email': email, 'password': password},
      options: _public,
    );
    return LoginResponseModel.fromJson(res.dataMap);
  }

  Future<void> logout(String refreshToken) async {
    await _dio.post<dynamic>(ApiEndpoints.logout, data: {'refreshToken': refreshToken});
  }

  Future<void> forgotPassword(String email) async {
    await _dio.post<dynamic>(ApiEndpoints.forgotPassword, data: {'email': email}, options: _public);
  }

  Future<void> setupNewPassword(String token, String newPassword) async {
    await _dio.post<dynamic>(
      ApiEndpoints.setupNewPassword,
      data: {'token': token, 'newPassword': newPassword},
      options: _public,
    );
  }

  /// 400 `{errors: "Invalid current password"}` when the current password is wrong.
  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    await _dio.post<dynamic>(
      ApiEndpoints.changePassword,
      data: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
  }
}
