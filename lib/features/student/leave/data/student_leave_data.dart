import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_guard.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/utils/app_dates.dart';
import '../../../../core/utils/json.dart';
import '../../../common/leave/leave_application.dart';
import '../domain/student_leave.dart';

class StudentLeaveRemoteDataSource {
  StudentLeaveRemoteDataSource(this._dio);

  final Dio _dio;

  Map<String, Object> _body(LeaveRequest r) => {
        'leaveReason': r.reason.trim(),
        'fromDate': AppDates.apiDate(r.fromDate),
        'toDate': AppDates.apiDate(r.toDate),
      };

  Future<List<LeaveApplicationModel>> myLeaves() async {
    final payload = (await _dio.get<dynamic>(ApiEndpoints.myLeaves)).payload;
    final rows = payload is Map ? JsonRead.list(payload['leaveApplications']) : JsonRead.list(payload);
    return rows.map(LeaveApplicationModel.fromJson).toList();
  }

  Future<LeaveApplicationModel> myLeave(int id) async {
    final data = (await _dio.get<dynamic>(ApiEndpoints.myLeave(id))).dataMap;
    return LeaveApplicationModel.fromJson(JsonRead.map(data['leaveApplication']) ?? data);
  }

  Future<LeaveApplicationModel> apply(LeaveRequest r) async =>
      LeaveApplicationModel.fromJson((await _dio.post<dynamic>(ApiEndpoints.leaves, data: _body(r))).dataMap);

  Future<LeaveApplicationModel> update(int id, LeaveRequest r) async =>
      LeaveApplicationModel.fromJson((await _dio.patch<dynamic>(ApiEndpoints.leave(id), data: _body(r))).dataMap);

  Future<LeaveApplicationModel> cancel(int id) async =>
      LeaveApplicationModel.fromJson((await _dio.patch<dynamic>(ApiEndpoints.cancelLeave(id))).dataMap);
}

class StudentLeaveRepositoryImpl implements StudentLeaveRepository {
  StudentLeaveRepositoryImpl(this._remote);

  final StudentLeaveRemoteDataSource _remote;

  @override
  Future<List<LeaveApplication>> myLeaves() => guardApi(() async {
        final leaves = await _remote.myLeaves();
        return leaves..sort((a, b) => b.fromDate.compareTo(a.fromDate));
      });

  @override
  Future<LeaveApplication> myLeave(int id) => guardApi(() => _remote.myLeave(id));

  @override
  Future<LeaveApplication> apply(LeaveRequest request) => guardApi(() => _remote.apply(request));

  @override
  Future<LeaveApplication> update(int id, LeaveRequest request) => guardApi(() => _remote.update(id, request));

  @override
  Future<LeaveApplication> cancel(int id) => guardApi(() => _remote.cancel(id));
}
