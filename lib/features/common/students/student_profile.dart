import '../../../core/models/account_status.dart';
import '../../../core/utils/json.dart';

/// Student profile entity and its JSON model, shared by the student's own
/// profile screen and the admin's student screens.
class StudentProfile {
  const StudentProfile({
    required this.id,
    required this.name,
    required this.contactNumber,
    required this.parentMobileNumber,
    required this.rollNumber,
    this.email,
    this.imageKey,
    this.imageUrl,
    this.departmentId,
    this.departmentName,
    this.roomId,
    this.roomNumber,
    this.status = AccountStatus.unknown,
    this.activationEmailSent = true,
  });

  final int id;
  final String name;
  final String contactNumber;
  final String parentMobileNumber;
  final String rollNumber;
  final String? email;
  final String? imageKey;

  /// Signed URL the detail endpoint sends (`studentImageUrl`), valid 5 minutes.
  final String? imageUrl;
  final int? departmentId;
  final String? departmentName;
  final int? roomId;
  final String? roomNumber;

  /// `unknown` until the backend includes the user's status (see API_GAPS.md).
  final AccountStatus status;

  /// Only meaningful right after creating a student: false when the server
  /// saved the student but couldn't send the activation email.
  final bool activationEmailSent;

  StudentProfile copyWith({String? departmentName, String? roomNumber}) => StudentProfile(
        id: id,
        name: name,
        contactNumber: contactNumber,
        parentMobileNumber: parentMobileNumber,
        rollNumber: rollNumber,
        email: email,
        imageKey: imageKey,
        imageUrl: imageUrl,
        departmentId: departmentId,
        departmentName: departmentName ?? this.departmentName,
        roomId: roomId,
        roomNumber: roomNumber ?? this.roomNumber,
        status: status,
      );
}

class StudentProfileModel extends StudentProfile {
  const StudentProfileModel({
    required super.id,
    required super.name,
    required super.contactNumber,
    required super.parentMobileNumber,
    required super.rollNumber,
    super.email,
    super.imageKey,
    super.imageUrl,
    super.departmentId,
    super.departmentName,
    super.roomId,
    super.roomNumber,
    super.status,
    super.activationEmailSent,
  });

  factory StudentProfileModel.fromJson(Map<String, dynamic> json) {
    final user = JsonRead.map(json['user']);
    final room = JsonRead.map(json['room']);
    final department = JsonRead.map(json['department']);
    return StudentProfileModel(
      id: JsonRead.integer(json['id']),
      name: JsonRead.string(json['studentName'], 'Student'),
      contactNumber: JsonRead.string(json['contactNumber']),
      parentMobileNumber: JsonRead.string(json['parentMobileNumber']),
      rollNumber: JsonRead.string(json['rollNumber']),
      email: JsonRead.stringOrNull(user?['email'] ?? json['email']),
      imageKey: JsonRead.stringOrNull(json['studentImageKey']),
      imageUrl: JsonRead.stringOrNull(json['studentImageUrl']),
      departmentId: JsonRead.integerOrNull(json['departmentId'] ?? department?['id']),
      departmentName: JsonRead.stringOrNull(department?['departmentName']),
      roomId: JsonRead.integerOrNull(json['roomId'] ?? room?['id']),
      roomNumber: JsonRead.stringOrNull(room?['roomNumber']),
      // Not sent yet; read it as soon as the backend adds `user.status`.
      status: AccountStatus.fromApi(user?['status'] ?? json['status']),
      activationEmailSent: JsonRead.boolean(json['activationEmailSent'], true),
    );
  }
}
