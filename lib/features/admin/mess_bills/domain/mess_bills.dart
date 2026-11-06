import '../../../../core/error/app_exception.dart';
import '../../../../core/utils/app_dates.dart';
import '../../../common/mess_bills/mess_bill.dart';

class MessBillDraft {
  const MessBillDraft({required this.month, required this.year, required this.amount, required this.lastDate});

  /// 1–12.
  final int month;
  final int year;
  final double amount;
  final DateTime lastDate;
}

abstract interface class MessBillRepository {
  Future<List<MessBill>> list();
  Future<MessBill> create(MessBillDraft draft);
  Future<MessBill> update(int id, MessBillDraft draft);

  /// Locks the bill and shows it to students. Can't be undone.
  Future<MessBill> publish(int id);

  /// Only drafts can be deleted.
  Future<void> delete(int id);
}

class SaveMessBill {
  const SaveMessBill(this._repository);
  final MessBillRepository _repository;

  /// Same rules as the backend: only this month or next, a positive amount,
  /// and a last date that's not in the past or before the month starts.
  Future<MessBill> call(MessBillDraft draft, {int? id}) async {
    if (!isAllowedBillMonth(draft.month, draft.year)) {
      final allowed = allowedBillMonths();
      throw AppException(
        'Bills can only be set for ${billMonthLabel(allowed.first)} or ${billMonthLabel(allowed.last)}.',
        code: 'month',
      );
    }
    if (draft.amount <= 0) throw const AppException('Enter an amount above zero.', code: 'amount');
    if (draft.lastDate.isBefore(DateTime(draft.year, draft.month))) {
      throw const AppException("The last date can't be before the bill's month starts.", code: 'lastDate');
    }
    if (draft.lastDate.isBefore(AppDates.todayIst())) {
      throw const AppException("The last date can't be in the past.", code: 'lastDate');
    }
    return id == null ? _repository.create(draft) : _repository.update(id, draft);
  }
}
