import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/widgets.dart';
import '../../features/admin/attendance/presentation/admin_home_screen.dart';
import '../../features/admin/leave/presentation/leave_requests_screen.dart';
import '../../features/admin/leave/presentation/leave_review_screen.dart';
import '../../features/admin/mess_bills/presentation/mess_bills_screen.dart';
import '../../features/admin/notices/presentation/admin_notices_screen.dart';
import '../../features/admin/notices/presentation/announcement_form_screen.dart';
import '../../features/admin/notices/presentation/event_form_screen.dart';
import '../../features/admin/rooms/presentation/room_detail_screen.dart';
import '../../features/admin/rooms/presentation/rooms_screen.dart';
import '../../features/admin/settings/presentation/hostel_settings_screen.dart';
import '../../features/admin/shell/admin_shell.dart';
import '../../features/admin/students/presentation/student_detail_screen.dart';
import '../../features/admin/students/presentation/student_form_screen.dart';
import '../../features/admin/students/presentation/students_screen.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/screens/change_password_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/set_password_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/common/announcements/presentation/announcement_detail_screen.dart';
import '../../features/common/events/presentation/event_detail_screen.dart';
import '../../features/student/attendance/presentation/attendance_providers.dart';
import '../../features/student/attendance/presentation/attendance_result_screen.dart';
import '../../features/student/attendance/presentation/mark_attendance_screen.dart';
import '../../features/student/fees/presentation/fees_screen.dart';
import '../../features/student/home/presentation/student_home_screen.dart';
import '../../features/student/leave/presentation/apply_leave_screen.dart';
import '../../features/student/leave/presentation/leave_detail_screen.dart';
import '../../features/student/leave/presentation/my_leaves_screen.dart';
import '../../features/student/notices/presentation/notices_screen.dart';
import '../../features/student/profile/presentation/profile_screen.dart';
import '../../features/student/shell/student_shell.dart';
import 'routes.dart';

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

int _id(GoRouterState state) => int.tryParse(state.pathParameters['id'] ?? '') ?? -1;

/// A full-screen route that covers the bottom navigation.
GoRoute _page(String path, Widget Function(BuildContext context, GoRouterState state) builder) =>
    GoRoute(path: path, parentNavigatorKey: _rootKey, builder: builder);

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref.listen(authControllerProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    navigatorKey: _rootKey,
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) => _redirect(ref.read(authControllerProvider), state),
    errorBuilder: (context, state) => Scaffold(
      appBar: const AppTopBar(showBack: true),
      body: const EmptyView(icon: Icons.explore_off_outlined, title: 'Page not found', message: "That screen doesn't exist."),
    ),
    routes: [
      // ── Public ──
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: Routes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(path: Routes.forgotPassword, builder: (_, _) => const ForgotPasswordScreen()),
      GoRoute(
        path: Routes.setPassword,
        builder: (_, state) => SetPasswordScreen(
          token: state.uri.queryParameters['token'],
          mode: state.uri.queryParameters['mode'] == 'reset' ? SetPasswordMode.reset : SetPasswordMode.welcome,
        ),
      ),
      // Same link with the path form (`/setup-password?token=...`).
      GoRoute(path: '/setup-password', redirect: (_, state) => setPasswordDeepLinkTarget(state.uri) ?? Routes.setPassword),
      // https email link opened straight in the app (Android App Links)
      GoRoute(path: '/open/setup-password', redirect: (_, state) => setPasswordDeepLinkTarget(state.uri) ?? Routes.setPassword),

      // ── Student ──
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => StudentShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: Routes.studentHome, builder: (_, _) => const StudentHomeScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.myLeaves, builder: (_, _) => const MyLeavesScreen())]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.studentNotices,
              builder: (_, state) => NoticesScreen(initialTab: state.extra is int ? state.extra! as int : 0),
            ),
          ]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.fees, builder: (_, _) => const FeesScreen())]),
        ],
      ),
      _page(Routes.markAttendance, (_, _) => const MarkAttendanceScreen()),
      _page(Routes.attendanceResult, (_, state) => AttendanceResultScreen(
            outcome: state.extra is AttendanceOutcome ? state.extra! as AttendanceOutcome : const AttendanceNeedsPhoto(),
          )),
      _page(Routes.applyLeave, (_, _) => const ApplyLeaveScreen()),
      _page('/student/leave/:id', (_, state) => LeaveDetailScreen(id: _id(state))),
      _page('/student/leave/:id/edit', (_, state) => ApplyLeaveScreen(editingId: _id(state))),
      _page('/student/notices/announcements/:id', (_, state) => AnnouncementDetailScreen(id: _id(state))),
      _page('/student/notices/events/:id', (_, state) => EventDetailScreen(id: _id(state))),
      _page(Routes.profile, (_, _) => const ProfileScreen()),
      _page(Routes.studentChangePassword, (_, _) => const ChangePasswordScreen()),

      // ── Hostel admin ──
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AdminShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: Routes.adminHome, builder: (_, _) => const AdminHomeScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.rooms, builder: (_, _) => const RoomsScreen())]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.adminLeaves,
              builder: (_, state) => LeaveRequestsScreen(rollNumber: state.uri.queryParameters['roll']),
            ),
          ]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.students, builder: (_, _) => const StudentsScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.adminNotices, builder: (_, _) => const AdminNoticesScreen())]),
        ],
      ),
      _page('/admin/rooms/:id', (_, state) => RoomDetailScreen(id: _id(state))),
      _page('/admin/leave/:id', (_, state) => LeaveReviewScreen(id: _id(state))),
      _page(Routes.addStudent, (_, _) => const StudentFormScreen()),
      _page('/admin/students/:id', (_, state) => StudentDetailScreen(id: _id(state))),
      _page('/admin/students/:id/edit', (_, state) => StudentFormScreen(editingId: _id(state))),
      _page(Routes.newAnnouncement, (_, _) => const AnnouncementFormScreen()),
      _page('/admin/notices/announcements/:id', (context, state) => AnnouncementDetailScreen(
            id: _id(state),
            onEdit: (a) => context.push(Routes.editAnnouncement(a.id)),
          )),
      _page('/admin/notices/announcements/:id/edit', (_, state) => AnnouncementFormScreen(editingId: _id(state))),
      _page(Routes.newEvent, (_, _) => const EventFormScreen()),
      _page('/admin/notices/events/:id', (context, state) => EventDetailScreen(
            id: _id(state),
            onEdit: (e) => context.push(Routes.editEvent(e.id)),
          )),
      _page('/admin/notices/events/:id/edit', (_, state) => EventFormScreen(editingId: _id(state))),
      _page(Routes.messBills, (_, _) => const MessBillsScreen()),
      _page(Routes.hostelSettings, (_, _) => const HostelSettingsScreen()),
      _page(Routes.adminChangePassword, (_, _) => const ChangePasswordScreen()),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

/// Keeps signed-out users on public screens and each role inside its own area.
String? _redirect(AuthState auth, GoRouterState state) {
  // Emailed links open the app as `ourhostel://setup-password?token=...&mode=...`;
  // go_router sees that as "/" (the host isn't part of the path).
  final deepLink = setPasswordDeepLinkTarget(state.uri);
  if (deepLink != null) return deepLink;

  final location = state.matchedLocation;
  final isPublic = location == Routes.login || location == Routes.forgotPassword || location == Routes.setPassword;

  switch (auth) {
    case AuthChecking():
      return location == Routes.splash || location == Routes.setPassword ? null : Routes.splash;
    case Unauthenticated():
      return isPublic ? null : Routes.login;
    case Authenticated(:final user):
      final home = user.isAdmin ? Routes.adminHome : Routes.studentHome;
      if (location == Routes.splash || location == Routes.login || location == Routes.forgotPassword) return home;
      if (user.isAdmin && location.startsWith('/student')) return home;
      if (!user.isAdmin && location.startsWith('/admin')) return home;
      return null;
  }
}
