/// Every screen path in one place. Student screens live under `/student`,
/// hostel admin screens under `/admin`.
abstract final class Routes {
  // Public
  static const splash = '/';
  static const login = '/login';
  static const forgotPassword = '/forgot-password';

  /// Opened from the emailed link: `/set-password?token=...&mode=welcome|reset`.
  static const setPassword = '/set-password';

  // Student
  static const studentHome = '/student/home';
  static const markAttendance = '/student/attendance';
  static const attendanceResult = '/student/attendance/result';
  static const myLeaves = '/student/leave';
  static const applyLeave = '/student/leave/apply';
  static String leaveDetail(int id) => '/student/leave/$id';
  static String editLeave(int id) => '/student/leave/$id/edit';
  static const studentNotices = '/student/notices';
  static String studentAnnouncement(int id) => '/student/notices/announcements/$id';
  static String studentEvent(int id) => '/student/notices/events/$id';
  static const fees = '/student/fees';
  static const profile = '/student/profile';
  static const studentChangePassword = '/student/profile/change-password';

  // Hostel admin
  static const adminHome = '/admin/home';
  static const rooms = '/admin/rooms';
  static String room(int id) => '/admin/rooms/$id';
  static const adminLeaves = '/admin/leave';
  static String leaveReview(int id) => '/admin/leave/$id';
  static const students = '/admin/students';
  static const addStudent = '/admin/students/new';
  static String student(int id) => '/admin/students/$id';
  static String editStudent(int id) => '/admin/students/$id/edit';
  static const adminNotices = '/admin/notices';
  static const newAnnouncement = '/admin/notices/announcements/new';
  static String adminAnnouncement(int id) => '/admin/notices/announcements/$id';
  static String editAnnouncement(int id) => '/admin/notices/announcements/$id/edit';
  static const newEvent = '/admin/notices/events/new';
  static String adminEvent(int id) => '/admin/notices/events/$id';
  static String editEvent(int id) => '/admin/notices/events/$id/edit';
  static const messBills = '/admin/mess-bills';
  static const hostelSettings = '/admin/settings';
  static const adminChangePassword = '/admin/change-password';
}

/// The backend emails `ourhostel://setup-password?token=...&mode=welcome|reset`.
/// Returns the in-app location for such a link (host or path form), or null
/// when [uri] isn't one.
String? setPasswordDeepLinkTarget(Uri uri) {
  final isLink = uri.host == 'setup-password' || uri.path == '/setup-password';
  if (!isLink) return null;
  final token = uri.queryParameters['token'];
  final mode = uri.queryParameters['mode'] == 'reset' ? 'reset' : 'welcome';
  return Uri(path: Routes.setPassword, queryParameters: {'token': ?token, 'mode': mode}).toString();
}
