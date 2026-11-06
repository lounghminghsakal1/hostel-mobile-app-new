import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:our_hostel/features/student/home/domain/student_home.dart';
import 'package:our_hostel/features/student/home/presentation/student_home_providers.dart';

StudentHome _home({
  AttendanceWindow window = AttendanceWindow.open,
  TodayAttendance? today,
  bool? hasPhoto = true,
  LeaveSpan? leave,
}) =>
    StudentHome(
      canMarkAttendance: true,
      window: window,
      todayAttendance: today,
      hasProfilePhoto: hasPhoto,
      approvedLeaveToday: leave,
      announcements: const [],
      events: const [],
      hostel: const HostelSchedule(id: 1, name: 'Test Hostel', windowStart: '20:30', windowEnd: '22:00'),
      studentProfileId: 12,
      email: 'student@example.com',
    );

Future<AttendanceCardState?> _stateFor(StudentHome home) async {
  final container = ProviderContainer(overrides: [studentHomeProvider.overrideWith((ref) async => home)]);
  addTearDown(container.dispose);
  final sub = container.listen(attendanceCardStateProvider, (_, _) {});
  await container.read(studentHomeProvider.future);
  return sub.read();
}

void main() {
  test('window open and not marked shows the Mark attendance card', () async {
    expect(await _stateFor(_home()), AttendanceCardState.open);
  });

  test('a check-in today wins over everything else', () async {
    final today = TodayAttendance(reportedTime: DateTime.now().toUtc(), insideHostelRadius: true);
    expect(await _stateFor(_home(today: today, hasPhoto: false)), AttendanceCardState.marked);
  });

  test('no profile photo blocks marking', () async {
    expect(await _stateFor(_home(hasPhoto: false)), AttendanceCardState.photoNeeded);
  });

  test('approved leave today replaces the button', () async {
    final leave = LeaveSpan(from: DateTime(2026, 11, 4), to: DateTime(2026, 11, 6));
    expect(await _stateFor(_home(leave: leave)), AttendanceCardState.onLeave);
  });

  test('before and after the window', () async {
    expect(await _stateFor(_home(window: AttendanceWindow.notOpenYet)), AttendanceCardState.notOpenYet);
    expect(await _stateFor(_home(window: AttendanceWindow.closed)), AttendanceCardState.missed);
  });
}
