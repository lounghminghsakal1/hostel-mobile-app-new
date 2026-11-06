import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keeps the access token, refresh token and the signed-in user in the
/// platform keystore (Android Keystore / iOS Keychain). The access token is
/// also cached in memory because every request needs it.
class TokenStorage {
  TokenStorage(this._storage);

  final FlutterSecureStorage _storage;

  static const _accessKey = 'auth.access_token';
  static const _refreshKey = 'auth.refresh_token';
  static const _userKey = 'auth.user';

  String? _accessToken;
  bool _accessLoaded = false;

  Future<String?> readAccessToken() async {
    if (!_accessLoaded) {
      _accessToken = await _storage.read(key: _accessKey);
      _accessLoaded = true;
    }
    return _accessToken;
  }

  Future<String?> readRefreshToken() => _storage.read(key: _refreshKey);

  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    _accessToken = accessToken;
    _accessLoaded = true;
    await _storage.write(key: _accessKey, value: accessToken);
    await _storage.write(key: _refreshKey, value: refreshToken);
  }

  Future<String?> readUserJson() => _storage.read(key: _userKey);

  Future<void> saveUserJson(String json) => _storage.write(key: _userKey, value: json);

  Future<void> clear() async {
    _accessToken = null;
    _accessLoaded = true;
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
    await _storage.delete(key: _userKey);
  }
}
