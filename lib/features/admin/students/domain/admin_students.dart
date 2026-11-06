import 'dart:typed_data';

import '../../../../core/error/app_exception.dart';
import '../../../../core/models/account_status.dart';
import '../../../../core/models/paginated.dart';
import '../../../common/media/domain/media_repository.dart';
import '../../../common/students/student_profile.dart';

class Department {
  const Department({required this.id, required this.name});

  final int id;
  final String name;
}

/// Fields for creating a student, or only the changed fields when editing.
class StudentDraft {
  const StudentDraft({
    this.email,
    this.name,
    this.contactNumber,
    this.parentMobileNumber,
    this.departmentId,
    this.rollNumber,
    this.roomId,
    this.imageKey,
  });

  final String? email;
  final String? name;
  final String? contactNumber;
  final String? parentMobileNumber;
  final int? departmentId;
  final String? rollNumber;
  final int? roomId;
  final String? imageKey;

  StudentDraft withImageKey(String key) => StudentDraft(
        email: email,
        name: name,
        contactNumber: contactNumber,
        parentMobileNumber: parentMobileNumber,
        departmentId: departmentId,
        rollNumber: rollNumber,
        roomId: roomId,
        imageKey: key,
      );
}

typedef StudentQuery = ({String? search, int? departmentId, int? roomId, String? rollNumber, int page});

/// One problem the face check found in a student photo.
class PhotoIssue {
  const PhotoIssue({required this.code, required this.message, required this.isError});

  /// e.g. NO_FACE, BLURRY, TOO_DARK, NOT_FACING_CAMERA.
  final String code;
  final String message;

  /// An error means the photo can't be used; otherwise it's a warning.
  final bool isError;
}

/// Result of checking a just-uploaded student photo (`POST students/image_check`).
class PhotoCheck {
  const PhotoCheck({required this.ok, required this.message, this.issues = const []});

  /// False when any issue is an error: the photo can't be saved.
  final bool ok;
  final String message;
  final List<PhotoIssue> issues;

  List<PhotoIssue> get errors => issues.where((i) => i.isError).toList();
  List<PhotoIssue> get warnings => issues.where((i) => !i.isError).toList();
}

abstract interface class AdminStudentRepository {
  Future<PageResult<StudentProfile>> list(StudentQuery query);
  Future<StudentProfile> get(int id);
  Future<StudentProfile> create(StudentDraft draft);
  Future<StudentProfile> update(int id, StudentDraft changes);
  Future<void> changeStatus(int id, AccountStatus status);
  Future<void> changeRoom(int id, int roomId);
  Future<void> resendActivation(int id);
  Future<List<Department>> departments();

  /// Checks an uploaded photo: one clear, sharp, well-lit, front-facing face.
  Future<PhotoCheck> checkPhoto(String imageKey);
}

/// Uses the already-uploaded photo ([photoKey]) or uploads [photo] first, then
/// creates or updates the student. Creating a student also emails them an
/// activation link (server side), and the server re-checks the photo.
class SaveStudent {
  const SaveStudent(this._students, this._media);

  final AdminStudentRepository _students;
  final MediaRepository _media;

  Future<StudentProfile> call(StudentDraft draft, {Uint8List? photo, String? photoKey, int? editingId}) async {
    if (editingId == null) {
      final missing = [draft.email, draft.name, draft.contactNumber, draft.parentMobileNumber, draft.rollNumber]
          .any((v) => v == null || v.trim().isEmpty);
      if (missing || draft.departmentId == null) {
        throw const AppException('Fill in every required field.', code: 'required');
      }
    }
    var payload = draft;
    if (photoKey != null) {
      payload = draft.withImageKey(photoKey);
    } else if (photo != null) {
      payload = draft.withImageKey(await _media.uploadImage(MediaFor.studentImage, photo));
    }
    return editingId == null ? _students.create(payload) : _students.update(editingId, payload);
  }
}
