import 'package:dio/dio.dart';

import '../models/paginated.dart';

typedef Json = Map<String, dynamic>;

/// Unwraps the backend envelope `{status, message, data, errors, meta?}`.
extension ApiEnvelope on Response<dynamic> {
  Json get _body => data as Json;

  Object? get payload => _body['data'];

  Json get dataMap => payload as Json;

  List<Json> get dataList => ((payload as List?) ?? const []).cast<Json>();

  /// Pagination sits directly under `body.meta`.
  PageMeta get meta {
    final raw = _body['meta'];
    if (raw is! Map) return const PageMeta(page: 1, pageSize: 0, totalPages: 1);
    return PageMeta(
      page: (raw['page'] as num?)?.toInt() ?? 1,
      pageSize: (raw['pageSize'] as num?)?.toInt() ?? 0,
      totalPages: (raw['totalPages'] as num?)?.toInt() ?? 1,
    );
  }
}

/// Query parameters for list endpoints, dropping empty values.
Map<String, dynamic> query(Map<String, Object?> params) => {
      for (final e in params.entries)
        if (e.value != null && !(e.value is String && (e.value as String).trim().isEmpty)) e.key: e.value,
    };
