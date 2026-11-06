import 'package:intl/intl.dart';

/// Date helpers. The hostel runs on India time, so moments from the API
/// (UTC) are shown in IST whatever the phone's time zone is, and calendar
/// dates (leave days, bill due dates) are never shifted.
abstract final class AppDates {
  static const _istOffset = Duration(hours: 5, minutes: 30);

  /// UTC moment → India wall-clock time (only for formatting).
  static DateTime ist(DateTime moment) => moment.toUtc().add(_istOffset);

  /// Today's date in India, without a time.
  static DateTime todayIst() {
    final now = ist(DateTime.now());
    return DateTime(now.year, now.month, now.day);
  }

  /// A wall-clock time the user picked (taken as IST) → UTC moment for the API.
  static DateTime fromIstWallTime(DateTime wall) =>
      DateTime.utc(wall.year, wall.month, wall.day, wall.hour, wall.minute).subtract(_istOffset);

  /// UTC moment → IST wall-clock values, for pre-filling pickers.
  static DateTime toIstWallTime(DateTime moment) {
    final t = ist(moment);
    return DateTime(t.year, t.month, t.day, t.hour, t.minute);
  }

  static String time(DateTime moment) => DateFormat('h:mm a').format(ist(moment));

  static String dayMonth(DateTime date) => DateFormat('d MMM').format(date);

  static String dayMonthYear(DateTime date) => DateFormat('d MMM yyyy').format(date);

  static String weekdayDayMonth(DateTime date) => DateFormat('EEE, d MMM').format(date);

  static String fullDate(DateTime date) => DateFormat('EEEE, d MMMM').format(date);

  static String monthYear(DateTime date) => DateFormat('MMMM yyyy').format(date);

  static String shortMonth(DateTime date) => DateFormat('MMM').format(date).toUpperCase();

  static String weekdayShort(DateTime date) => DateFormat('EEE').format(date);

  /// "Sun, 8 Nov · 7:00 PM – 10:30 PM" for one-day events.
  static String eventWhen(DateTime start, DateTime end) {
    final s = ist(start);
    final e = ist(end);
    final sameDay = s.year == e.year && s.month == e.month && s.day == e.day;
    if (sameDay) return '${weekdayDayMonth(s)} · ${time(start)} – ${time(end)}';
    return '${weekdayDayMonth(s)}, ${time(start)} – ${weekdayDayMonth(e)}, ${time(end)}';
  }

  /// "12–14 Nov", "28 Oct – 2 Nov" or "12 Nov" for calendar dates.
  static String range(DateTime from, DateTime to) {
    if (from.year == to.year && from.month == to.month) {
      if (from.day == to.day) return dayMonth(from);
      return '${from.day}–${to.day} ${DateFormat('MMM').format(to)}';
    }
    return '${dayMonth(from)} – ${dayMonth(to)}';
  }

  static int daysInclusive(DateTime from, DateTime to) =>
      DateTime(to.year, to.month, to.day).difference(DateTime(from.year, from.month, from.day)).inDays + 1;

  static String dayCount(int days) => days == 1 ? '1 day' : '$days days';

  /// Calendar date → `YYYY-MM-DD`, the format the backend expects.
  static String apiDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  /// UTC moment → ISO string with exactly 3 fractional digits (backend requires it).
  static String apiInstant(DateTime moment) =>
      DateTime.fromMillisecondsSinceEpoch(moment.millisecondsSinceEpoch, isUtc: true).toIso8601String();

  /// "20:30" → "8:30 PM".
  static String clockLabel(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return hhmm;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return hhmm;
    return DateFormat('h:mm a').format(DateTime(2000, 1, 1, h, m));
  }

  static String hhmm(int hour, int minute) =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  static bool isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  /// "Today", "Tomorrow", "In 3 days", or null when it's in the past.
  static String? daysFromNow(DateTime date) {
    final days = DateTime(date.year, date.month, date.day).difference(todayIst()).inDays;
    if (days < 0) return null;
    if (days == 0) return 'Today';
    if (days == 1) return 'Tomorrow';
    return 'In $days days';
  }

  static String greeting() {
    final hour = ist(DateTime.now()).hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}
