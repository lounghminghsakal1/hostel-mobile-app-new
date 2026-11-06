import '../../../../core/models/paginated.dart';

/// "Below 65%" (strictly less) or "65% or more".
enum FaceMatchOperator { below, atLeast }

/// How much to trust a face match score (0–100).
enum FaceMatchLevel {
  /// 65% and above: the selfie and the photo on file are the same person.
  trusted,

  /// 30% to under 65%: worth a look.
  check,

  /// Under 30%: probably not the same person.
  mismatch,

  /// No score (not checked).
  unknown;

  static const trustedFrom = 65.0;
  static const checkFrom = 30.0;

  static FaceMatchLevel of(double? percent) {
    if (percent == null) return unknown;
    if (percent >= trustedFrom) return trusted;
    if (percent >= checkFrom) return check;
    return mismatch;
  }
}

/// Everything the admin can filter the attendance list by.
class AttendanceFilters {
  const AttendanceFilters({
    required this.from,
    required this.to,
    this.departmentId,
    this.roomId,
    this.rollNumber,
    this.faceMatchPercent,
    this.faceMatchOperator = FaceMatchOperator.below,
    this.outsideOnly = false,
  });

  /// Calendar dates; equal for a single day.
  final DateTime from;
  final DateTime to;
  final int? departmentId;
  final int? roomId;
  final String? rollNumber;
  final double? faceMatchPercent;
  final FaceMatchOperator faceMatchOperator;
  final bool outsideOnly;

  bool get isSingleDay => from == to;

  /// The one-tap "face match below 65%" filter.
  bool get isLowFaceMatchOnly =>
      faceMatchPercent == FaceMatchLevel.trustedFrom && faceMatchOperator == FaceMatchOperator.below;

  /// A face match filter other than the one-tap one.
  bool get hasCustomFaceMatch => faceMatchPercent != null && !isLowFaceMatchOnly;

  /// How many filters besides the dates are on (for the badge on the filter button).
  int get extraCount =>
      [departmentId, roomId, rollNumber, faceMatchPercent].where((v) => v != null).length + (outsideOnly ? 1 : 0);

  AttendanceFilters withDay(DateTime day) => AttendanceFilters(
        from: day,
        to: day,
        departmentId: departmentId,
        roomId: roomId,
        rollNumber: rollNumber,
        faceMatchPercent: faceMatchPercent,
        faceMatchOperator: faceMatchOperator,
        outsideOnly: outsideOnly,
      );

  /// Same filters with the face match filter set ([percent] null clears it).
  AttendanceFilters withFaceMatch(double? percent, [FaceMatchOperator operator = FaceMatchOperator.below]) =>
      AttendanceFilters(
        from: from,
        to: to,
        departmentId: departmentId,
        roomId: roomId,
        rollNumber: rollNumber,
        faceMatchPercent: percent,
        faceMatchOperator: percent == null ? FaceMatchOperator.below : operator,
        outsideOnly: outsideOnly,
      );

  @override
  bool operator ==(Object other) =>
      other is AttendanceFilters &&
      other.from == from &&
      other.to == to &&
      other.departmentId == departmentId &&
      other.roomId == roomId &&
      other.rollNumber == rollNumber &&
      other.faceMatchPercent == faceMatchPercent &&
      other.faceMatchOperator == faceMatchOperator &&
      other.outsideOnly == outsideOnly;

  @override
  int get hashCode =>
      Object.hash(from, to, departmentId, roomId, rollNumber, faceMatchPercent, faceMatchOperator, outsideOnly);
}

class AttendanceSummary {
  const AttendanceSummary({required this.totalStudents, required this.presentCount, required this.completelyAbsentCount});

  final int totalStudents;

  /// Present on at least one day of the range.
  final int presentCount;

  /// Absent on every day of the range (the absent list shows anyone absent on any day).
  final int completelyAbsentCount;
}

class PresentRecord {
  const PresentRecord({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.attendanceDate,
    required this.reportedTime,
    required this.insideRadius,
    this.rollNumber,
    this.roomNumber,
    this.departmentName,
    this.contactNumber,
    this.studentImageKey,
    this.capturedImageKey,
    this.faceMatchPercent,
    this.distanceMeters,
  });

  final int id;
  final int studentId;
  final String studentName;
  final DateTime attendanceDate;
  final DateTime reportedTime;
  final bool insideRadius;
  final String? rollNumber;
  final String? roomNumber;
  final String? departmentName;
  final String? contactNumber;
  final String? studentImageKey;
  final String? capturedImageKey;
  final double? faceMatchPercent;
  final double? distanceMeters;
}

class AbsentRecord {
  const AbsentRecord({
    required this.studentName,
    required this.absentDates,
    this.studentId,
    this.rollNumber,
    this.roomNumber,
    this.departmentName,
    this.contactNumber,
    this.parentMobileNumber,
    this.studentImageKey,
  });

  final String studentName;
  final List<DateTime> absentDates;

  /// Student profile id, to open the student's page.
  final int? studentId;
  final String? rollNumber;
  final String? roomNumber;
  final String? departmentName;
  final String? contactNumber;
  final String? parentMobileNumber;
  final String? studentImageKey;
}

class AttendancePage<T> {
  const AttendancePage({required this.summary, required this.page});

  final AttendanceSummary summary;
  final PageResult<T> page;
}

abstract interface class AttendanceReportRepository {
  Future<AttendancePage<PresentRecord>> present(AttendanceFilters filters, {String? search, required int page});
  Future<AttendancePage<AbsentRecord>> absent(AttendanceFilters filters, {String? search, required int page});
}
