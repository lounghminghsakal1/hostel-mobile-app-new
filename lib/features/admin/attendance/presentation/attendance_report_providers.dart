import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/app_dates.dart';
import '../data/attendance_report_data.dart';
import '../domain/attendance_report.dart';

final attendanceReportRepositoryProvider = Provider<AttendanceReportRepository>(
  (ref) => AttendanceReportRepositoryImpl(AttendanceReportRemoteDataSource(ref.watch(dioProvider))),
);

/// The dashboard's current filters. Starts on today.
final attendanceFiltersProvider = NotifierProvider<AttendanceFiltersNotifier, AttendanceFilters>(
  AttendanceFiltersNotifier.new,
);

class AttendanceFiltersNotifier extends Notifier<AttendanceFilters> {
  @override
  AttendanceFilters build() {
    final today = AppDates.todayIst();
    return AttendanceFilters(from: today, to: today);
  }

  void selectDay(DateTime day) => state = state.withDay(day);

  void apply(AttendanceFilters filters) => state = filters;

  void reset() => state = build();
}

/// Present dates for one student over the last 7 days (admin student page).
final lastWeekPresenceProvider = FutureProvider.autoDispose.family<Set<DateTime>, String>((ref, rollNumber) async {
  final today = AppDates.todayIst();
  final filters = AttendanceFilters(from: today.subtract(const Duration(days: 6)), to: today, rollNumber: rollNumber);
  final result = await ref.watch(attendanceReportRepositoryProvider).present(filters, page: 1);
  return result.page.items.map((r) => r.attendanceDate).toSet();
});
