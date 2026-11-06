import '../../../../core/utils/app_dates.dart';
import '../../../common/announcements/domain/announcement.dart';
import '../../../common/events/domain/hostel_event.dart';

/// Where "now" (India time) sits relative to tonight's attendance window.
enum AttendanceWindow {
  notOpenYet,
  open,
  closed;

  static AttendanceWindow? fromApi(Object? value) => switch (value) {
        'NOT_OPEN_YET' => AttendanceWindow.notOpenYet,
        'OPEN' => AttendanceWindow.open,
        'CLOSED' => AttendanceWindow.closed,
        _ => null,
      };
}

class HostelSchedule {
  const HostelSchedule({required this.id, required this.name, required this.windowStart, required this.windowEnd});

  final int id;
  final String name;

  /// "HH:mm" in India time, e.g. "20:30".
  final String windowStart;
  final String windowEnd;

  String get startLabel => AppDates.clockLabel(windowStart);
  String get endLabel => AppDates.clockLabel(windowEnd);
  String get windowLabel => '$startLabel – $endLabel';

  /// Worked out on the phone, for when the server doesn't send the state.
  AttendanceWindow get windowNow {
    final now = AppDates.ist(DateTime.now());
    final minutes = now.hour * 60 + now.minute;
    if (minutes < _minutes(windowStart)) return AttendanceWindow.notOpenYet;
    if (minutes > _minutes(windowEnd)) return AttendanceWindow.closed;
    return AttendanceWindow.open;
  }

  static int _minutes(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return 0;
    return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
  }
}

/// Tonight's check-in, when there is one.
class TodayAttendance {
  const TodayAttendance({required this.reportedTime, required this.insideHostelRadius, this.distanceMeters});

  final DateTime reportedTime;
  final bool insideHostelRadius;
  final double? distanceMeters;
}

/// Approved leave that covers today.
class LeaveSpan {
  const LeaveSpan({required this.from, required this.to});

  final DateTime from;
  final DateTime to;
}

/// Everything the student home screen needs, from `GET /students/splash_screen`.
class StudentHome {
  const StudentHome({
    required this.canMarkAttendance,
    required this.window,
    required this.announcements,
    required this.events,
    required this.hostel,
    required this.studentProfileId,
    required this.email,
    this.todayAttendance,
    this.hasProfilePhoto,
    this.approvedLeaveToday,
  });

  /// The server's own flag. While its testing override is on, it's true even
  /// outside the window, so the card follows [window] instead.
  final bool canMarkAttendance;
  final AttendanceWindow window;
  final TodayAttendance? todayAttendance;

  /// Null when the server didn't say.
  final bool? hasProfilePhoto;
  final LeaveSpan? approvedLeaveToday;

  /// At most 5, valid today, important first.
  final List<Announcement> announcements;

  /// At most 5 ongoing or upcoming events.
  final List<HostelEvent> events;
  final HostelSchedule hostel;
  final int studentProfileId;
  final String email;
}

abstract interface class StudentHomeRepository {
  Future<StudentHome> load();
}
