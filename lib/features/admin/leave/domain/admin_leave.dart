import '../../../../core/error/app_exception.dart';
import '../../../../core/models/paginated.dart';
import '../../../common/leave/leave_application.dart';

typedef LeaveQuery = ({LeaveStatus? status, String? search, String? rollNumber, int page});

/// Counts per status for the whole matching set, whichever tab is selected.
class LeaveCounts {
  const LeaveCounts({this.pending = 0, this.approved = 0, this.rejected = 0, this.cancelled = 0});

  final int pending;
  final int approved;
  final int rejected;
  final int cancelled;

  int of(LeaveStatus status) => switch (status) {
        LeaveStatus.pending => pending,
        LeaveStatus.approved => approved,
        LeaveStatus.rejected => rejected,
        LeaveStatus.cancelled => cancelled,
      };
}

class LeavePage {
  const LeavePage({required this.page, required this.counts});

  final PageResult<LeaveApplication> page;
  final LeaveCounts counts;
}

class LeaveReviewDetail {
  const LeaveReviewDetail({required this.leave, required this.recent});

  final LeaveApplication leave;

  /// The same student's leaves from the last two months.
  final List<LeaveApplication> recent;
}

abstract interface class AdminLeaveRepository {
  Future<LeavePage> list(LeaveQuery query);
  Future<LeaveReviewDetail> get(int id);
  Future<LeaveApplication> review(int id, {required bool approve, String? rejectionReason});
}

/// Rejecting needs a reason the student will see.
class ReviewLeave {
  const ReviewLeave(this._repository);
  final AdminLeaveRepository _repository;

  Future<LeaveApplication> approve(int id) => _repository.review(id, approve: true);

  Future<LeaveApplication> reject(int id, String reason) {
    if (reason.trim().isEmpty) {
      throw const AppException('Add a short reason so the student knows why.', code: 'reason_required');
    }
    return _repository.review(id, approve: false, rejectionReason: reason.trim());
  }
}
