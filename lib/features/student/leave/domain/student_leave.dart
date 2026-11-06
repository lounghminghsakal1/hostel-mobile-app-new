import '../../../../core/error/app_exception.dart';
import '../../../../core/utils/app_dates.dart';
import '../../../common/leave/leave_application.dart';

class LeaveRequest {
  const LeaveRequest({required this.fromDate, required this.toDate, required this.reason});

  final DateTime fromDate;
  final DateTime toDate;
  final String reason;
}

abstract interface class StudentLeaveRepository {
  Future<List<LeaveApplication>> myLeaves();
  Future<LeaveApplication> myLeave(int id);
  Future<LeaveApplication> apply(LeaveRequest request);
  Future<LeaveApplication> update(int id, LeaveRequest request);
  Future<LeaveApplication> cancel(int id);
}

/// Creates or edits a request. The backend doesn't check dates on edits,
/// so the rules live here for both.
class SubmitLeaveRequest {
  const SubmitLeaveRequest(this._repository);
  final StudentLeaveRepository _repository;

  Future<LeaveApplication> call(LeaveRequest request, {int? editingId}) {
    if (request.reason.trim().isEmpty) {
      throw const AppException('Tell your warden why you need leave.', code: 'reason_required');
    }
    if (request.toDate.isBefore(request.fromDate)) {
      throw const AppException('The last day must be on or after the first day.', code: 'invalid_range');
    }
    if (request.fromDate.isBefore(AppDates.todayIst())) {
      throw const AppException("Leave can't start in the past.", code: 'past_date');
    }
    return editingId == null ? _repository.apply(request) : _repository.update(editingId, request);
  }
}

class CancelLeaveRequest {
  const CancelLeaveRequest(this._repository);
  final StudentLeaveRepository _repository;

  Future<LeaveApplication> call(int id) => _repository.cancel(id);
}
