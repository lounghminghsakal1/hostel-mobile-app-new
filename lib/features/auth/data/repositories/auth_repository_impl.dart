import 'dart:convert';

import '../../../../core/network/api_guard.dart';
import '../../../../core/storage/token_storage.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/auth_models.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote, this._storage);

  final AuthRemoteDataSource _remote;
  final TokenStorage _storage;

  @override
  Future<AppUser> login({required String email, required String password}) => guardApi(() async {
        final response = await _remote.login(email, password);
        await _storage.saveTokens(accessToken: response.accessToken, refreshToken: response.refreshToken);
        await _storage.saveUserJson(jsonEncode(response.user.toJson()));
        return response.user;
      });

  @override
  Future<AppUser?> restoreSession() async {
    final refreshToken = await _storage.readRefreshToken();
    final userJson = await _storage.readUserJson();
    if (refreshToken == null || userJson == null) return null;
    try {
      return AppUserModel.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
    } on Object {
      await _storage.clear();
      return null;
    }
  }

  @override
  Future<void> logout() async {
    final refreshToken = await _storage.readRefreshToken();
    try {
      if (refreshToken != null) await _remote.logout(refreshToken);
    } on Object {
      // Signing out locally must always work, even offline.
    } finally {
      await _storage.clear();
    }
  }

  @override
  Future<void> requestPasswordReset(String email) => guardApi(() => _remote.forgotPassword(email));

  @override
  Future<void> setNewPassword({required String token, required String newPassword}) =>
      guardApi(() => _remote.setupNewPassword(token, newPassword));

  @override
  Future<void> changePassword({required String currentPassword, required String newPassword}) =>
      guardApi(() => _remote.changePassword(currentPassword: currentPassword, newPassword: newPassword));
}
