import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/app_config.dart';
import '../storage/token_storage.dart';
import 'auth_interceptor.dart';
import 'base_url.dart';
import 'session_events.dart';

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => TokenStorage(const FlutterSecureStorage()),
);

final sessionEventsProvider = Provider<SessionEvents>((ref) {
  final events = SessionEvents();
  ref.onDispose(events.dispose);
  return events;
});

BaseOptions _apiOptions(String baseUrl) => BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      contentType: Headers.jsonContentType,
      headers: {'Accept': 'application/json'},
    );

/// The Dio instance every remote data source uses.
final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  final events = ref.watch(sessionEventsProvider);
  final baseUrl = ref.watch(apiBaseUrlProvider);

  final plainClient = Dio(_apiOptions(baseUrl));
  final dio = Dio(_apiOptions(baseUrl))
    ..interceptors.add(
      AuthInterceptor(
        storage: storage,
        refreshClient: plainClient,
        retryClient: plainClient,
        onSessionExpired: () => events.emit(SessionEvent.expired),
      ),
    );

  if (kDebugMode) {
    // Bodies and headers stay out of the log: they carry passwords and tokens.
    dio.interceptors.add(LogInterceptor(
      requestHeader: false,
      requestBody: false,
      responseHeader: false,
      responseBody: false,
      logPrint: (line) => debugPrint('$line'),
    ));
  }
  return dio;
});

/// For PUT uploads to S3 pre-signed URLs: no base URL and no auth header.
final storageUploadDioProvider = Provider<Dio>(
  (ref) => Dio(BaseOptions(
    connectTimeout: AppConfig.connectTimeout,
    sendTimeout: const Duration(seconds: 60),
    receiveTimeout: AppConfig.receiveTimeout,
  )),
);
