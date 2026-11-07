import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:our_hostel/features/common/announcements/domain/announcement.dart';
import 'package:our_hostel/features/common/events/domain/hostel_event.dart';
import 'package:our_hostel/features/student/home/domain/student_home.dart';
import 'package:our_hostel/features/student/home/presentation/student_home_providers.dart';
import 'package:our_hostel/features/student/shell/student_shell.dart';

Announcement _announcement({required bool on, required DateTime start, required DateTime end}) => Announcement(
      id: 1,
      title: 'Water supply off',
      description: '',
      isActive: on,
      startDate: start,
      endDate: end,
      type: AnnouncementType.hostel,
      isImportant: false,
      pushNotification: false,
    );

HostelEvent _event({required bool on, required DateTime start, required DateTime end}) =>
    HostelEvent(id: 1, name: 'Movie night', description: '', startingAt: start, endingAt: end, isActive: on);

StudentHome _home() => const StudentHome(
      canMarkAttendance: false,
      window: AttendanceWindow.notOpenYet,
      todayAttendance: null,
      hasProfilePhoto: true,
      approvedLeaveToday: null,
      announcements: [],
      events: [],
      hostel: HostelSchedule(id: 1, name: 'Test Hostel', windowStart: '20:30', windowEnd: '22:00'),
      studentProfileId: 1,
      email: 'student@example.com',
    );

class _HomeTab extends ConsumerWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(studentHomeProvider);
    return const Text('Home tab');
  }
}

void main() {
  group('announcement visibility (today between start and end, switched on)', () {
    final today = DateTime(2026, 11, 7);
    test('live, including the first and last day', () {
      expect(_announcement(on: true, start: DateTime(2026, 11, 6), end: DateTime(2026, 11, 8)).visibility(today), AnnouncementVisibility.live);
      expect(_announcement(on: true, start: today, end: today).visibility(today), AnnouncementVisibility.live);
    });
    test('scheduled, expired and hidden', () {
      expect(_announcement(on: true, start: DateTime(2026, 11, 8), end: DateTime(2026, 11, 9)).visibility(today), AnnouncementVisibility.scheduled);
      expect(_announcement(on: true, start: DateTime(2026, 11, 1), end: DateTime(2026, 11, 6)).visibility(today), AnnouncementVisibility.expired);
      expect(_announcement(on: false, start: DateTime(2026, 11, 6), end: DateTime(2026, 11, 8)).visibility(today), AnnouncementVisibility.hidden);
    });
  });

  test('event visibility: live between start and end, upcoming before, ended after', () {
    final now = DateTime.utc(2026, 11, 7, 14);
    final start = DateTime.utc(2026, 11, 7, 13), end = DateTime.utc(2026, 11, 7, 16);
    expect(_event(on: true, start: start, end: end).visibility(now), EventVisibility.live);
    expect(_event(on: true, start: start, end: end).visibility(DateTime.utc(2026, 11, 7, 12)), EventVisibility.upcoming);
    expect(_event(on: true, start: start, end: end).visibility(end), EventVisibility.ended);
    expect(_event(on: false, start: start, end: end).visibility(now), EventVisibility.hidden);
  });

  testWidgets('opening the Home tab again reloads home (new notices show up)', (tester) async {
    var loads = 0;
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (_, _, shell) => StudentShell(navigationShell: shell),
          branches: [
            StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (_, _) => const _HomeTab())]),
            StatefulShellBranch(routes: [GoRoute(path: '/leave', builder: (_, _) => const Text('Leave tab'))]),
            StatefulShellBranch(routes: [GoRoute(path: '/notices', builder: (_, _) => const Text('Notices tab'))]),
            StatefulShellBranch(routes: [GoRoute(path: '/fees', builder: (_, _) => const Text('Fees tab'))]),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        studentHomeProvider.overrideWith((ref) async {
          loads++;
          return _home();
        }),
      ],
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();
    expect(loads, 1);

    await tester.tap(find.text('Notices'));
    await tester.pumpAndSettle();
    expect(find.text('Notices tab'), findsOneWidget);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('Home tab'), findsOneWidget);
    expect(loads, 2, reason: 'reloaded when coming back to Home');
  });
}
