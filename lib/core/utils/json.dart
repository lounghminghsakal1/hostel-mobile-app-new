/// Tolerant readers for API JSON. The backend sends Prisma decimals as
/// strings and calendar dates as midnight-UTC instants, so parse defensively.
abstract final class JsonRead {
  static String string(Object? v, [String fallback = '']) => v == null ? fallback : '$v';

  static String? stringOrNull(Object? v) {
    if (v == null) return null;
    final s = '$v'.trim();
    return s.isEmpty ? null : s;
  }

  static int integer(Object? v, [int fallback = 0]) {
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? double.tryParse(v)?.toInt() ?? fallback;
    return fallback;
  }

  static int? integerOrNull(Object? v) => v == null ? null : integer(v);

  static double decimal(Object? v, [double fallback = 0]) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? fallback;
    return fallback;
  }

  static double? decimalOrNull(Object? v) => v == null ? null : decimal(v);

  static bool boolean(Object? v, [bool fallback = false]) {
    if (v is bool) return v;
    if (v is String) return v.toLowerCase() == 'true';
    return fallback;
  }

  /// A real moment in time (`reportedTime`, `startingAt`), kept in UTC.
  static DateTime? instant(Object? v) => v is String ? DateTime.tryParse(v)?.toUtc() : null;

  /// A calendar date (`fromDate`, `lastDate`). Uses the first 10 characters
  /// so the day never shifts with time zones.
  static DateTime? calendarDate(Object? v) {
    if (v is! String || v.length < 10) return null;
    final parts = v.substring(0, 10).split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  static Map<String, dynamic>? map(Object? v) => v is Map<String, dynamic> ? v : null;

  static List<Map<String, dynamic>> list(Object? v) =>
      v is List ? v.whereType<Map<String, dynamic>>().toList() : const [];
}
