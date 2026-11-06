import 'package:dio/dio.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_guard.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/utils/json.dart';
import '../../../common/leave/leave_application.dart';
import '../domain/admin_leave.dart';

class AdminLeaveRemoteDataSource {
  AdminLeaveRemoteDataSource(this._dio);

  final Dio _dio;

  /// `data: {leaveApplications: [...], statusesCount: {WAITING_FOR_APPROVAL, APPROVED, REJECTED, CANCELLED}}`.
  Future<LeavePage> list(LeaveQuery q) async {
    final res = await _dio.get<dynamic>(
      ApiEndpoints.leaves,
      queryParameters: query({
        'page': q.page,
        'pageSize': AppConfig.pageSize,
        'by_status': q.status?.apiValue,
        'by_student_name': q.search,
        'by_student_roll_number': q.rollNumber,
      }),
    );
    final data = res.dataMap;
    final counts = JsonRead.map(data['statusesCount']) ?? const {};
    return LeavePage(
      page: (
        items: JsonRead.list(data['leaveApplications']).map(LeaveApplicationModel.fromJson).toList(),
        hasMore: res.meta.hasMore,
      ),
      counts: LeaveCounts(
        pending: JsonRead.integer(counts['WAITING_FOR_APPROVAL']),
        approved: JsonRead.integer(counts['APPROVED']),
        rejected: JsonRead.integer(counts['REJECTED']),
        cancelled: JsonRead.integer(counts['CANCELLED']),
      ),
    );
  }

  /// `data: {leaveApplication, previoudTwoMonthLeaveApplications}` (sic).
  Future<LeaveReviewDetail> get(int id) async {
    final data = (await _dio.get<dynamic>(ApiEndpoints.leave(id))).dataMap;
    final leave = LeaveApplicationModel.fromJson(JsonRead.map(data['leaveApplication']) ?? data);
    final recent = JsonRead.list(data['previoudTwoMonthLeaveApplications'] ?? data['previousTwoMonthLeaveApplications'])
        .map(LeaveApplicationModel.fromJson)
        .where((l) => l.id != leave.id)
        .toList();
    return LeaveReviewDetail(leave: leave, recent: recent);
  }

  Future<LeaveApplication> review(int id, bool approve, String? reason) async {
    final res = await _dio.patch<dynamic>(
      ApiEndpoints.reviewLeave(id),
      data: {'status': approve ? 'APPROVED' : 'REJECTED', 'rejectionReason': ?reason},
    );
    return LeaveApplicationModel.fromJson(res.dataMap);
  }
}

class AdminLeaveRepositoryImpl implements AdminLeaveRepository {
  AdminLeaveRepositoryImpl(this._remote);

  final AdminLeaveRemoteDataSource _remote;

  @override
  Future<LeavePage> list(LeaveQuery query) => guardApi(() => _remote.list(query));

  @override
  Future<LeaveReviewDetail> get(int id) => guardApi(() => _remote.get(id));

  @override
  Future<LeaveApplication> review(int id, {required bool approve, String? rejectionReason}) =>
      guardApi(() => _remote.review(id, approve, rejectionReason));
}
