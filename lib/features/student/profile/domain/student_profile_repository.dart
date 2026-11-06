import '../../../common/students/student_profile.dart';

abstract interface class StudentProfileRepository {
  /// Students can read but not edit their profile; only admins can edit.
  Future<StudentProfile> myProfile(int studentProfileId);
}
