import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_guard.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/utils/json.dart';
import '../../../common/announcements/data/announcement_data.dart';
import '../../../common/events/data/event_data.dart';
import '../domain/student_home.dart';

class StudentHomeRemoteDataSource {
  StudentHomeRemoteDataSource(this._dio);

  final Dio _dio;

  Future<StudentHome> load() async {
    final data = (await _dio.get<dynamic>(ApiEndpoints.studentSplash)).dataMap;
    final hostel = JsonRead.map(data['hostel']) ?? const {};
    final user = JsonRead.map(data['user']) ?? const {};
    final profile = JsonRead.map(user['studentProfile']) ?? const {};
    final schedule = HostelSchedule(
      id: JsonRead.integer(hostel['id']),
      name: JsonRead.string(hostel['hostelName'], 'Your hostel'),
      windowStart: JsonRead.string(hostel['attendanceMarkingStartTime'], '20:30'),
      windowEnd: JsonRead.string(hostel['attendanceMarkingEndTime'], '22:00'),
    );
    final today = JsonRead.map(data['todayAttendance']);
    final leave = JsonRead.map(data['approvedLeaveToday']);
    final leaveFrom = JsonRead.calendarDate(leave?['fromDate']);
    final rawPhoto = data['hasProfilePhoto'];

    return StudentHome(
      canMarkAttendance: JsonRead.boolean(data['canMarkAttendance']),
      window: AttendanceWindow.fromApi(data['attendanceWindowState']) ?? schedule.windowNow,
      todayAttendance: today == null
          ? null
          : TodayAttendance(
              reportedTime: JsonRead.instant(today['reportedTime']) ?? DateTime.now().toUtc(),
              insideHostelRadius: JsonRead.boolean(today['isLocatedWithinHostelRadius'], true),
              distanceMeters: JsonRead.decimalOrNull(today['locationDeviationFromHostel']),
            ),
      hasProfilePhoto: rawPhoto is bool ? rawPhoto : null,
      approvedLeaveToday: leaveFrom == null
          ? null
          : LeaveSpan(from: leaveFrom, to: JsonRead.calendarDate(leave?['toDate']) ?? leaveFrom),
      announcements: JsonRead.list(data['announcements']).map(AnnouncementModel.fromJson).toList(),
      events: JsonRead.list(data['upcomingEvents']).map(HostelEventModel.fromJson).toList(),
      hostel: schedule,
      studentProfileId: JsonRead.integer(profile['id']),
      email: JsonRead.string(user['email']),
    );
  }
}

class StudentHomeRepositoryImpl implements StudentHomeRepository {
  StudentHomeRepositoryImpl(this._remote);

  final StudentHomeRemoteDataSource _remote;

  @override
  Future<StudentHome> load() => guardApi(_remote.load);
}
