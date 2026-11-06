import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_guard.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/utils/json.dart';
import '../../../common/mess_bills/mess_bill.dart';
import '../domain/student_fees_repository.dart';

class StudentFeesRemoteDataSource {
  StudentFeesRemoteDataSource(this._dio);

  final Dio _dio;

  /// `GET /mess_fee/my_bills` → `data: {bills: [...], paymentInfo: {...}}`.
  Future<MyMessBills> myBills() async {
    final data = (await _dio.get<dynamic>(ApiEndpoints.myMessBills)).dataMap;
    return MyMessBills(
      bills: JsonRead.list(data['bills']).map(MessBillModel.fromJson).toList(),
      paymentInfo: _paymentInfo(JsonRead.map(data['paymentInfo'])),
    );
  }

  static MessFeePaymentInfo _paymentInfo(Map<String, dynamic>? json) {
    if (json == null) return MessFeePaymentInfo.fallback;
    final hours = [
      for (final h in JsonRead.list(json['officeHours']))
        OfficeHours(
          label: JsonRead.string(h['label'], JsonRead.string(h['shift'])),
          opensAt: JsonRead.string(h['opensAt']),
          closesAt: JsonRead.string(h['closesAt']),
        ),
    ];
    return MessFeePaymentInfo(
      onlinePaymentAvailable: JsonRead.boolean(json['onlinePaymentAvailable']),
      message: JsonRead.stringOrNull(json['message']) ?? MessFeePaymentInfo.fallback.message,
      officeHours: hours.isEmpty ? MessFeePaymentInfo.fallback.officeHours : hours,
    );
  }
}

class StudentFeesRepositoryImpl implements StudentFeesRepository {
  StudentFeesRepositoryImpl(this._remote);

  final StudentFeesRemoteDataSource _remote;

  @override
  Future<MyMessBills> myBills() => guardApi(() async {
        final result = await _remote.myBills();
        result.bills.sort((a, b) => b.monthDate.compareTo(a.monthDate));
        return result;
      });
}
