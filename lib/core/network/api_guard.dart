import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../error/app_exception.dart';

/// Runs an API call and turns every failure into an [AppException],
/// so repositories never leak Dio types to the domain layer.
Future<T> guardApi<T>(Future<T> Function() call) async {
  try {
    return await call();
  } on DioException catch (e) {
    final inner = e.error;
    if (inner is AppException) throw inner;
    throw mapDioException(e);
  } on AppException {
    rethrow;
  } on TypeError {
    throw const AppException('We got an unexpected response from the server.', code: 'parse');
  } on FormatException {
    throw const AppException('We got an unexpected response from the server.', code: 'parse');
  }
}

/// The backend always answers `{status, message, data, errors}`.
/// `errors` is either a short string or a field → message object.
AppException mapDioException(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
      return _unreachable(e, code: 'timeout');
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return const AppException('The server is taking too long to respond. Please try again.', code: 'timeout');
    case DioExceptionType.connectionError:
      return _unreachable(e);
    case DioExceptionType.cancel:
      return const AppException('The request was cancelled.', code: 'cancelled');
    case DioExceptionType.unknown when e.response == null:
      return _unreachable(e);
    default:
      break;
  }

  final status = e.response?.statusCode;
  final body = e.response?.data;
  String? message;
  String? code;
  final fields = <String, String>{};

  if (body is Map) {
    final m = body['message'];
    if (m is String && m.trim().isNotEmpty) message = m;
    final errors = body['errors'];
    if (errors is String) {
      code = errors;
    } else if (errors is Map) {
      errors.forEach((key, value) => fields['$key'] = '$value');
    }
  }

  // The backend replaces unexpected 500s with a generic message itself, so a
  // 5xx message from it is meant for the user (e.g. "Couldn't send the
  // activation email: ..."). Proxies' error pages have no JSON message.
  if (status != null && status >= 500 && message == null) {
    message = 'Something went wrong on our side. Please try again in a moment.';
  } else if (status == 404 && message == null) {
    message = "We couldn't find that.";
  }

  return AppException(
    message ?? 'Something went wrong. Please try again.',
    statusCode: status,
    code: code,
    fieldErrors: fields,
  );
}

/// No response at all: offline, wrong address, server down, or (Android)
/// plain http blocked. Debug builds say which address failed.
AppException _unreachable(DioException e, {String code = 'network'}) {
  if (!kDebugMode) {
    return AppException("Can't reach the server. Check your internet connection and try again.", code: code);
  }
  final uri = e.requestOptions.uri;
  final server = '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
  final detail = '${e.error ?? e.message ?? ''}';
  if (detail.contains('Cleartext')) {
    return AppException('Android blocked plain http to $server. Debug builds allow it; check android/app/src/debug/AndroidManifest.xml.', code: code);
  }
  return AppException(
    "Can't reach the server at $server. Check that the backend is running and that this device can reach that address "
    '(on a real phone use your PC\'s Wi-Fi IP, not localhost).',
    code: code,
  );
}
