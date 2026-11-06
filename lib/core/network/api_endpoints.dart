/// Every backend path, relative to `AppConfig.apiBaseUrl`.
abstract final class ApiEndpoints {
  // Auth
  static const login = 'auth/login';
  static const refresh = 'auth/refresh';
  static const logout = 'auth/logout';
  static const changePassword = 'auth/change_password';
  static const forgotPassword = 'students/forgot_password';
  static const setupNewPassword = 'students/setup_new_password';

  // Student
  static const studentSplash = 'students/splash_screen';
  static String student(int id) => 'students/$id';
  static const myLeaves = 'leave_applications/student/my_leave_applications';
  static String myLeave(int id) => 'leave_applications/student/my_leave_applications/$id';
  static const leaves = 'leave_applications';
  static String leave(int id) => 'leave_applications/$id';
  static String cancelLeave(int id) => 'leave_applications/$id/cancel';
  static String reviewLeave(int id) => 'leave_applications/$id/review';
  static const attendance = 'attendance_records';

  // Shared
  static const announcements = 'announcements';
  static String announcement(int id) => 'announcements/$id';
  static const events = 'upcoming_events';
  static String event(int id) => 'upcoming_events/$id';
  static const uploadUrl = 'media/upload_url';
  static const downloadUrl = 'media/download_url';

  // Hostel admin
  static const adminSplash = 'hostel_admin/splash_screen';
  static const students = 'students';
  static const departments = 'students/departments';
  static String studentStatus(int id) => 'students/$id/status';
  static String studentRoom(int id) => 'students/$id/room';
  static const activationLink = 'students/activation_link';
  static const studentImageCheck = 'students/image_check';
  static const rooms = 'rooms';
  static String room(int id) => 'rooms/$id';
  static const messBills = 'mess_fee/mess_bill';
  static String messBill(int id) => 'mess_fee/mess_bill/$id';
  static String publishMessBill(int id) => 'mess_fee/mess_bill/$id/publish';
  static const myMessBills = 'mess_fee/my_bills';
  static const hostels = 'hostels';
  static String hostel(int id) => 'hostels/$id';
}
