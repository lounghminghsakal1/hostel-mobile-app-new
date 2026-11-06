import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/app_dates.dart';
import '../../../common/mess_bills/mess_bill.dart';
import '../data/student_fees_data.dart';
import '../domain/student_fees_repository.dart';

final studentFeesRepositoryProvider = Provider<StudentFeesRepository>(
  (ref) => StudentFeesRepositoryImpl(StudentFeesRemoteDataSource(ref.watch(dioProvider))),
);

final myBillsProvider = FutureProvider.autoDispose<MyMessBills>(
  (ref) => ref.watch(studentFeesRepositoryProvider).myBills(),
);

/// The newest published bill whose last date hasn't passed and that has no
/// recorded payment. Payments made at the office aren't recorded in the app
/// yet, so this is "the bill to pay now", not proof that it's unpaid.
final dueBillProvider = Provider.autoDispose<MessBill?>((ref) {
  final bills = ref.watch(myBillsProvider).value?.bills ?? const [];
  return pickDueBill(bills, AppDates.todayIst());
});

MessBill? pickDueBill(List<MessBill> newestFirst, DateTime today) {
  for (final bill in newestFirst) {
    if (bill.status == MessBillStatus.published && !bill.isPaid && !bill.lastDate.isBefore(today)) return bill;
  }
  return null;
}
