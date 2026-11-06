import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/app_dates.dart';
import '../data/student_home_data.dart';
import '../domain/student_home.dart';

final studentHomeRepositoryProvider = Provider<StudentHomeRepository>(
  (ref) => StudentHomeRepositoryImpl(StudentHomeRemoteDataSource(ref.watch(dioProvider))),
);

/// Refetched on pull-to-refresh and after marking attendance.
final studentHomeProvider = FutureProvider.autoDispose<StudentHome>(
  (ref) => ref.watch(studentHomeRepositoryProvider).load(),
);

/// The check-in just made on this phone, so the card flips to "marked"
/// straight away, before the splash data reloads.
final markedTodayProvider = NotifierProvider<MarkedTodayNotifier, TodayAttendance?>(MarkedTodayNotifier.new);

class MarkedTodayNotifier extends Notifier<TodayAttendance?> {
  @override
  TodayAttendance? build() => null;

  void record(TodayAttendance attendance) => state = attendance;
}

bool _isToday(DateTime moment) => AppDates.isSameDay(AppDates.ist(moment), AppDates.todayIst());

/// Tonight's check-in, from the server or from this phone.
final todayCheckInProvider = Provider.autoDispose<TodayAttendance?>((ref) {
  final server = ref.watch(studentHomeProvider).value?.todayAttendance;
  if (server != null) return server;
  final local = ref.watch(markedTodayProvider);
  return local != null && _isToday(local.reportedTime) ? local : null;
});

/// Which attendance card the student home shows. Exactly one at a time.
enum AttendanceCardState { open, marked, notOpenYet, missed, photoNeeded, onLeave }

final attendanceCardStateProvider = Provider.autoDispose<AttendanceCardState?>((ref) {
  final home = ref.watch(studentHomeProvider).value;
  if (home == null) return null;
  if (ref.watch(todayCheckInProvider) != null) return AttendanceCardState.marked;
  if (home.hasProfilePhoto == false) return AttendanceCardState.photoNeeded;
  if (home.approvedLeaveToday != null) return AttendanceCardState.onLeave;
  return switch (home.window) {
    AttendanceWindow.open => AttendanceCardState.open,
    AttendanceWindow.notOpenYet => AttendanceCardState.notOpenYet,
    AttendanceWindow.closed => AttendanceCardState.missed,
  };
});
