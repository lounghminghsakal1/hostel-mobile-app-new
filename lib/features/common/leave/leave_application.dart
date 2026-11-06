import '../../../core/utils/app_dates.dart';
import '../../../core/utils/json.dart';
import '../../../core/widgets/tone.dart';

/// Leave entity and its JSON model, shared by the student and admin flows.
enum LeaveStatus {
  pending('WAITING_FOR_APPROVAL', 'Pending', Tone.warning),
  approved('APPROVED', 'Approved', Tone.success),
  rejected('REJECTED', 'Rejected', Tone.danger),
  cancelled('CANCELLED', 'Cancelled', Tone.neutral);

  const LeaveStatus(this.apiValue, this.label, this.tone);
  final String apiValue;
  final String label;
  final Tone tone;

  static LeaveStatus fromApi(Object? v) =>
      LeaveStatus.values.firstWhere((s) => s.apiValue == v, orElse: () => LeaveStatus.pending);
}

/// Student details embedded in admin leave responses.
class LeaveStudent {
  const LeaveStudent({required this.name, this.rollNumber, this.contactNumber, this.department, this.roomNumber, this.imageKey});

  final String name;
  final String? rollNumber;
  final String? contactNumber;
  final String? department;
  final String? roomNumber;
  final String? imageKey;

  String get subtitle => [rollNumber, department, roomNumber].whereType<String>().join(' · ');
}

class LeaveApplication {
  const LeaveApplication({
    required this.id,
    required this.reason,
    required this.fromDate,
    required this.toDate,
    required this.status,
    required this.studentId,
    this.rejectionReason,
    this.createdAt,
    this.reviewedAt,
    this.student,
  });

  final int id;
  final String reason;
  final DateTime fromDate;
  final DateTime toDate;
  final LeaveStatus status;
  final int studentId;
  final String? rejectionReason;
  final DateTime? createdAt;
  final DateTime? reviewedAt;
  final LeaveStudent? student;

  int get days => AppDates.daysInclusive(fromDate, toDate);
  bool get isPending => status == LeaveStatus.pending;
  String get rangeLabel => AppDates.range(fromDate, toDate);
}

class LeaveApplicationModel extends LeaveApplication {
  const LeaveApplicationModel({
    required super.id,
    required super.reason,
    required super.fromDate,
    required super.toDate,
    required super.status,
    required super.studentId,
    super.rejectionReason,
    super.createdAt,
    super.reviewedAt,
    super.student,
  });

  factory LeaveApplicationModel.fromJson(Map<String, dynamic> json) {
    final from = JsonRead.calendarDate(json['fromDate']) ?? AppDates.todayIst();
    final s = JsonRead.map(json['student']);
    return LeaveApplicationModel(
      id: JsonRead.integer(json['id']),
      reason: JsonRead.string(json['leaveReason']),
      fromDate: from,
      toDate: JsonRead.calendarDate(json['toDate']) ?? from,
      status: LeaveStatus.fromApi(json['status']),
      studentId: JsonRead.integer(json['studentId']),
      rejectionReason: JsonRead.stringOrNull(json['rejectionReason']),
      createdAt: JsonRead.instant(json['createdAt']),
      reviewedAt: JsonRead.instant(json['reviewedAt']),
      student: s == null
          ? null
          : LeaveStudent(
              name: JsonRead.string(s['studentName'], 'Student'),
              rollNumber: JsonRead.stringOrNull(s['rollNumber']),
              contactNumber: JsonRead.stringOrNull(s['contactNumber']),
              department: JsonRead.stringOrNull(JsonRead.map(s['department'])?['departmentName']),
              roomNumber: JsonRead.stringOrNull(JsonRead.map(s['room'])?['roomNumber']),
              imageKey: JsonRead.stringOrNull(s['studentImageKey']),
            ),
    );
  }
}
