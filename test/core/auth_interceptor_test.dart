import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:our_hostel/core/network/auth_interceptor.dart';
import 'package:our_hostel/core/storage/token_storage.dart';

class _MemoryTokenStorage extends TokenStorage {
  _MemoryTokenStorage({this.access, this.refresh}) : super(const FlutterSecureStorage());

  String? access;
  String? refresh;
  bool cleared = false;

  @override
  Future<String?> readAccessToken() async => access;

  @override
  Future<String?> readRefreshToken() async => refresh;

  @override
  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    access = accessToken;
    refresh = refreshToken;
  }

  @override
  Future<void> clear() async {
    access = null;
    refresh = null;
    cleared = true;
  }
}

/// Behaves like the real backend: one valid access token, and each refresh
/// token works exactly once (reusing one is treated as theft).
class _FakeBackend implements HttpClientAdapter {
  int refreshCalls = 0;
  final _usedRefreshTokens = <String>{};

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    await Future<void>.delayed(const Duration(milliseconds: 5));
    if (options.path.endsWith('auth/refresh')) {
      refreshCalls++;
      final token = (options.data as Map)['refreshToken'] as String;
      if (token != 'refresh-1' || !_usedRefreshTokens.add(token)) {
        return _json(409, {'status': 'failure', 'message': 'Refresh token already used', 'data': null, 'errors': 'Refresh token already used'});
      }
      return _json(200, {
        'status': 'success',
        'data': {'accessToken': 'access-2', 'refreshToken': 'refresh-2'},
      });
    }
    if (options.headers['Authorization'] != 'Bearer access-2') {
      return _json(401, {'status': 'failure', 'message': 'Token expired, please login again', 'data': null, 'errors': 'Token expired'});
    }
    return _json(200, {'status': 'success', 'data': {'ok': true}});
  }

  ResponseBody _json(int status, Object body) => ResponseBody.fromString(
        jsonEncode(body),
        status,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

  @override
  void close({bool force = false}) {}
}

void main() {
  late _FakeBackend backend;
  late _MemoryTokenStorage storage;
  late int expiredCalls;

  Dio buildDio() {
    final options = BaseOptions(baseUrl: 'https://api.test/api/v1/');
    final plain = Dio(options)..httpClientAdapter = backend;
    return Dio(options)
      ..httpClientAdapter = backend
      ..interceptors.add(AuthInterceptor(
        storage: storage,
        refreshClient: plain,
        retryClient: plain,
        onSessionExpired: () => expiredCalls++,
      ));
  }

  setUp(() {
    backend = _FakeBackend();
    expiredCalls = 0;
  });

  test('refreshes once when several requests get 401 at the same time', () async {
    storage = _MemoryTokenStorage(access: 'access-1', refresh: 'refresh-1');
    final dio = buildDio();

    final responses = await Future.wait([dio.get<dynamic>('a'), dio.get<dynamic>('b'), dio.get<dynamic>('c')]);

    expect(responses.map((r) => r.statusCode), everyElement(200));
    expect(backend.refreshCalls, 1);
    expect(storage.access, 'access-2');
    expect(storage.refresh, 'refresh-2');
    expect(expiredCalls, 0);
  });

  test('ends the session when the server rejects the refresh token', () async {
    storage = _MemoryTokenStorage(access: 'access-1', refresh: 'stale');
    final dio = buildDio();

    await expectLater(dio.get<dynamic>('a'), throwsA(isA<DioException>()));

    expect(expiredCalls, 1);
    expect(storage.cleared, isTrue);
  });

  test('public requests are sent without a token and never refresh', () async {
    storage = _MemoryTokenStorage(access: 'access-1', refresh: 'refresh-1');
    final dio = buildDio();

    await expectLater(
      dio.post<dynamic>('auth/login', options: Options(extra: {AuthInterceptor.skipAuth: true})),
      throwsA(isA<DioException>()),
    );

    expect(backend.refreshCalls, 0);
    expect(storage.access, 'access-1');
  });
}
