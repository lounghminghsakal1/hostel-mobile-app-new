import 'package:dio/dio.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_guard.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/utils/app_dates.dart';
import '../../../../core/utils/json.dart';
import '../domain/attendance_report.dart';

class AttendanceReportRemoteDataSource {
  AttendanceReportRemoteDataSource(this._dio);

  final Dio _dio;

  Future<Response<dynamic>> _fetch(AttendanceFilters f, String status, String? search, int page) {
    return _dio.get<dynamic>(
      ApiEndpoints.attendance,
      queryParameters: query({
        'status': status,
        'page': page,
        'pageSize': AppConfig.pageSize,
        // Send `date` OR `fromDate` + `toDate`, never both.
        'date': f.isSingleDay ? AppDates.apiDate(f.from) : null,
        'fromDate': f.isSingleDay ? null : AppDates.apiDate(f.from),
        'toDate': f.isSingleDay ? null : AppDates.apiDate(f.to),
        'by_student_name': search,
        'by_student_department_id': f.departmentId,
        'by_student_room_id': f.roomId,
        'by_roll_number': f.rollNumber,
        if (status == 'present' && f.faceMatchPercent != null) ...{
          'by_face_matching_percentage': f.faceMatchPercent,
          // "Below 65%" is strictly less than 65 (65 itself counts as trusted).
          'face_matching_operator': f.faceMatchOperator == FaceMatchOperator.atLeast ? 'gte' : 'lt',
        },
        'is_outside_hostel': status == 'present' && f.outsideOnly ? 'true' : null,
      }),
    );
  }

  AttendanceSummary _summary(Map<String, dynamic> data) {
    final s = JsonRead.map(data['summary']) ?? const {};
    return AttendanceSummary(
      totalStudents: JsonRead.integer(s['totalStudentsOfTheHostel']),
      // The backend key is `...WithAtleast...` (capital A); the old spelling is a fallback.
      presentCount: JsonRead.integer(
        s['totalStudentsWithAtleastOnePresentDuringDateFilter'] ?? s['totalStudentsWithatleastOnePresentDuringDateFilter'],
      ),
      completelyAbsentCount: JsonRead.integer(s['completelyAbsentStudentsCountDuringDates']),
    );
  }

  Future<AttendancePage<PresentRecord>> present(AttendanceFilters f, String? search, int page) async {
    final res = await _fetch(f, 'present', search, page);
    final data = res.dataMap;
    final rows = JsonRead.list(data['attendanceRecords']).map((r) {
      final student = JsonRead.map(r['student']) ?? const {};
      return PresentRecord(
        id: JsonRead.integer(r['id']),
        studentId: JsonRead.integer(r['studentId']),
        studentName: JsonRead.string(student['studentName'], 'Student'),
        rollNumber: JsonRead.stringOrNull(student['rollNumber']),
        roomNumber: JsonRead.stringOrNull(JsonRead.map(student['room'])?['roomNumber']),
        departmentName: JsonRead.stringOrNull(JsonRead.map(student['department'])?['departmentName']),
        contactNumber: JsonRead.stringOrNull(student['contactNumber']),
        studentImageKey: JsonRead.stringOrNull(student['studentImageKey']),
        attendanceDate: JsonRead.calendarDate(r['attendanceDate']) ?? AppDates.todayIst(),
        reportedTime: JsonRead.instant(r['reportedTime']) ?? DateTime.now().toUtc(),
        capturedImageKey: JsonRead.stringOrNull(r['capturedImageKey']),
        faceMatchPercent: JsonRead.decimalOrNull(r['faceMatchingPercentage']),
        insideRadius: JsonRead.boolean(r['isLocatedWithinHostelRadius'], true),
        distanceMeters: JsonRead.decimalOrNull(r['locationDeviationFromHostel']),
      );
    }).toList();
    return AttendancePage(summary: _summary(data), page: (items: rows, hasMore: res.meta.hasMore));
  }

  Future<AttendancePage<AbsentRecord>> absent(AttendanceFilters f, String? search, int page) async {
    final res = await _fetch(f, 'absent', search, page);
    final data = res.dataMap;
    final rows = JsonRead.list(data['attendanceRecords']).map((r) {
      final dates = (r['absentDates'] as List? ?? const []).map(JsonRead.calendarDate).whereType<DateTime>().toList();
      return AbsentRecord(
        studentId: JsonRead.integerOrNull(r['id']),
        studentName: JsonRead.string(r['studentName'], 'Student'),
        rollNumber: JsonRead.stringOrNull(r['rollNumber']),
        roomNumber: JsonRead.stringOrNull(r['roomNumber']),
        departmentName: JsonRead.stringOrNull(r['department']),
        contactNumber: JsonRead.stringOrNull(r['contactNumber']),
        parentMobileNumber: JsonRead.stringOrNull(r['parentMobileNumber']),
        studentImageKey: JsonRead.stringOrNull(r['studentImageKey']),
        absentDates: dates,
      );
    }).toList();
    return AttendancePage(summary: _summary(data), page: (items: rows, hasMore: res.meta.hasMore));
  }
}

class AttendanceReportRepositoryImpl implements AttendanceReportRepository {
  AttendanceReportRepositoryImpl(this._remote);

  final AttendanceReportRemoteDataSource _remote;

  @override
  Future<AttendancePage<PresentRecord>> present(AttendanceFilters filters, {String? search, required int page}) =>
      guardApi(() => _remote.present(filters, search, page));

  @override
  Future<AttendancePage<AbsentRecord>> absent(AttendanceFilters filters, {String? search, required int page}) =>
      guardApi(() => _remote.absent(filters, search, page));
}
