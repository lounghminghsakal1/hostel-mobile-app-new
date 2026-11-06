import 'package:dio/dio.dart';

import '../storage/token_storage.dart';
import 'api_endpoints.dart';

/// Adds `Authorization: Bearer <accessToken>` to every request and renews
/// the tokens when the backend answers 401.
///
/// How the backend behaves (src/modules/auth/auth.service.js):
/// * access tokens live 15 minutes; the session lives 7 days;
/// * `POST /auth/refresh {refreshToken}` returns a NEW access AND refresh token;
/// * a refresh token works once. Sending a used one revokes the whole session.
///
/// That last rule is why this is a [QueuedInterceptor]: errors are handled
/// one at a time, so when several requests fail together only the first one
/// refreshes; the rest see the token has already changed and just retry.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required this.storage,
    required this.refreshClient,
    required this.retryClient,
    required this.onSessionExpired,
  });

  /// Put `extra: {AuthInterceptor.skipAuth: true}` on public calls (login,
  /// forgot password) so they are sent without a token and never refreshed.
  static const skipAuth = 'skipAuth';
  static const _retried = 'authRetried';

  final TokenStorage storage;
  final Dio refreshClient;
  final Dio retryClient;
  final void Function() onSessionExpired;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (options.extra[skipAuth] != true) {
      final token = await storage.readAccessToken();
      if (token != null) options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    final isUnauthorized = err.response?.statusCode == 401;
    if (!isUnauthorized || options.extra[skipAuth] == true || options.extra[_retried] == true) {
      return handler.next(err);
    }

    final sentToken = _bearerToken(options.headers['Authorization']);
    final currentToken = await storage.readAccessToken();

    final freshToken = (currentToken != null && currentToken != sentToken)
        ? currentToken // another request already refreshed while this one was waiting
        : await _refreshTokens();

    if (freshToken == null) return handler.next(err);

    try {
      options.headers['Authorization'] = 'Bearer $freshToken';
      options.extra[_retried] = true;
      // A separate client: retrying through this queued interceptor would deadlock.
      final response = await retryClient.fetch<dynamic>(options);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  Future<String?> _refreshTokens() async {
    final refreshToken = await storage.readRefreshToken();
    if (refreshToken == null) {
      await _expireSession();
      return null;
    }
    try {
      final response = await refreshClient.post<dynamic>(
        ApiEndpoints.refresh,
        data: {'refreshToken': refreshToken},
      );
      final data = (response.data as Map)['data'] as Map;
      final accessToken = data['accessToken'] as String;
      final newRefreshToken = data['refreshToken'] as String;
      await storage.saveTokens(accessToken: accessToken, refreshToken: newRefreshToken);
      return accessToken;
    } on DioException catch (e) {
      // The server said no (expired, revoked, reused, account inactive):
      // the session is over. With no response we're offline, so keep the
      // tokens and let the screen show a network error instead.
      if (e.response != null) await _expireSession();
      return null;
    } on Object {
      await _expireSession();
      return null;
    }
  }

  Future<void> _expireSession() async {
    await storage.clear();
    onSessionExpired();
  }

  static String? _bearerToken(Object? header) {
    if (header is! String || !header.startsWith('Bearer ')) return null;
    return header.substring(7);
  }
}
