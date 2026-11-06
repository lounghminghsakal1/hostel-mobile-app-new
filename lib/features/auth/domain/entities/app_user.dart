import '../../../../core/models/account_status.dart';

enum UserRole {
  student,
  hostelAdmin;

  static UserRole? fromApi(Object? value) => switch (value) {
        'STUDENT' => UserRole.student,
        'HOSTEL_ADMIN' => UserRole.hostelAdmin,
        _ => null,
      };

  String get apiValue => this == UserRole.student ? 'STUDENT' : 'HOSTEL_ADMIN';
}

class AppUser {
  const AppUser({required this.id, required this.email, required this.status, required this.role});

  final int id;
  final String email;
  final AccountStatus status;
  final UserRole role;

  bool get isAdmin => role == UserRole.hostelAdmin;
}
