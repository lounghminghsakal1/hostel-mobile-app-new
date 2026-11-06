import 'package:flutter_test/flutter_test.dart';
import 'package:our_hostel/app/router/routes.dart';
import 'package:our_hostel/core/error/app_exception.dart';
import 'package:our_hostel/features/admin/mess_bills/domain/mess_bills.dart';
import 'package:our_hostel/features/common/mess_bills/mess_bill.dart';
import 'package:our_hostel/features/student/fees/presentation/fees_providers.dart';

MessBill _bill(int month, int year, {MessBillStatus status = MessBillStatus.published, DateTime? lastDate, DateTime? paidAt}) => MessBill(
      id: month + year * 100,
      month: month,
      year: year,
      amount: 3000,
      lastDate: lastDate ?? DateTime(year, month, 10),
      status: status,
      paidAt: paidAt,
    );

class _NoopRepo implements MessBillRepository {
  @override
  Future<MessBill> create(MessBillDraft draft) async => _bill(draft.month, draft.year, status: MessBillStatus.draft);
  @override
  Future<MessBill> update(int id, MessBillDraft draft) => create(draft);
  @override
  Future<void> delete(int id) async {}
  @override
  Future<List<MessBill>> list() async => const [];
  @override
  Future<MessBill> publish(int id) async => _bill(1, 2026);
}

void main() {
  group('allowed bill months', () {
    test('this month and next, rolling over the year in December', () {
      expect(allowedBillMonths(DateTime(2026, 11, 5)), [(month: 11, year: 2026), (month: 12, year: 2026)]);
      expect(allowedBillMonths(DateTime(2026, 12, 31)), [(month: 12, year: 2026), (month: 1, year: 2027)]);
      expect(isAllowedBillMonth(10, 2026, DateTime(2026, 11, 5)), isFalse);
      expect(isAllowedBillMonth(1, 2027, DateTime(2026, 11, 5)), isFalse);
    });

    test('model fills in action flags when the server omits them', () {
      final now = allowedBillMonths().first;
      final current = MessBillModel.fromJson({'id': 1, 'month': monthApiNames[now.month - 1], 'year': now.year, 'amount': '3000.00', 'lastDate': '2099-01-10', 'status': 'DRAFT'});
      expect(current.canEdit, isTrue);
      expect(current.canDelete, isTrue);
      final old = MessBillModel.fromJson({'id': 2, 'month': 'JANUARY', 'year': 2000, 'amount': '3000.00', 'lastDate': '2000-01-10', 'status': 'DRAFT'});
      expect(old.canEdit, isFalse);
      expect(old.canPublish, isFalse);
      expect(old.canDelete, isTrue);
      final server = MessBillModel.fromJson({'id': 3, 'month': 'JANUARY', 'year': 2000, 'amount': 1, 'lastDate': '2000-01-10', 'status': 'DRAFT', 'canEdit': true});
      expect(server.canEdit, isTrue);
    });
  });

  group('SaveMessBill', () {
    final save = SaveMessBill(_NoopRepo());
    final next = allowedBillMonths().last;

    test('rejects months other than this month and next', () {
      expect(
        () => save(MessBillDraft(month: 1, year: 2000, amount: 3000, lastDate: DateTime(2000, 1, 10))),
        throwsA(isA<AppException>().having((e) => e.code, 'code', 'month')),
      );
    });

    test('rejects a last date before the month starts', () {
      expect(
        () => save(MessBillDraft(month: next.month, year: next.year, amount: 3000, lastDate: DateTime(next.year, next.month - 1, 28))),
        throwsA(isA<AppException>().having((e) => e.code, 'code', 'lastDate')),
      );
    });

    test('accepts next month with a future last date', () async {
      final bill = await save(MessBillDraft(month: next.month, year: next.year, amount: 3000, lastDate: DateTime(next.year, next.month, 10)));
      expect(bill.month, next.month);
    });
  });

  test('due bill is the newest published one whose last date has not passed', () {
    final today = DateTime(2026, 11, 5);
    final bills = [
      _bill(12, 2026, status: MessBillStatus.draft),
      _bill(11, 2026, lastDate: DateTime(2026, 11, 10)),
      _bill(10, 2026, lastDate: DateTime(2026, 10, 10)),
    ];
    expect(pickDueBill(bills, today)?.month, 11);
    expect(pickDueBill(bills, DateTime(2026, 11, 10))?.month, 11, reason: 'last day still counts');
    expect(pickDueBill(bills, DateTime(2026, 11, 11)), isNull);
    expect(pickDueBill([_bill(11, 2026, paidAt: DateTime.utc(2026, 11, 2))], today), isNull);
  });

  test('emailed set-password links map to the in-app screen', () {
    expect(setPasswordDeepLinkTarget(Uri.parse('ourhostel://setup-password?token=abc&mode=reset')), '/set-password?token=abc&mode=reset');
    expect(setPasswordDeepLinkTarget(Uri.parse('ourhostel://setup-password?token=abc')), '/set-password?token=abc&mode=welcome');
    expect(setPasswordDeepLinkTarget(Uri.parse('/setup-password?token=x&mode=welcome')), '/set-password?token=x&mode=welcome');
    expect(setPasswordDeepLinkTarget(Uri.parse('/student/home')), isNull);
    expect(setPasswordDeepLinkTarget(Uri.parse('/')), isNull);
  });
}
