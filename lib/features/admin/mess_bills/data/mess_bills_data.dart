import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_guard.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/utils/app_dates.dart';
import '../../../../core/utils/json.dart';
import '../../../common/mess_bills/mess_bill.dart';
import '../domain/mess_bills.dart';

class MessBillRemoteDataSource {
  MessBillRemoteDataSource(this._dio);

  final Dio _dio;

  Map<String, Object> _body(MessBillDraft d) => {
        'month': monthApiNames[d.month - 1],
        'year': d.year,
        'amount': d.amount,
        'lastDate': AppDates.apiDate(d.lastDate),
      };

  Future<List<MessBillModel>> list() async {
    final payload = (await _dio.get<dynamic>(ApiEndpoints.messBills)).payload;
    final rows = payload is Map ? JsonRead.list(payload['monthlyMessBills']) : JsonRead.list(payload);
    return rows.map(MessBillModel.fromJson).toList();
  }

  Future<MessBillModel> create(MessBillDraft d) async =>
      MessBillModel.fromJson((await _dio.post<dynamic>(ApiEndpoints.messBills, data: _body(d))).dataMap);

  Future<MessBillModel> update(int id, MessBillDraft d) async =>
      MessBillModel.fromJson((await _dio.patch<dynamic>(ApiEndpoints.messBill(id), data: _body(d))).dataMap);

  Future<MessBillModel> publish(int id) async =>
      MessBillModel.fromJson((await _dio.post<dynamic>(ApiEndpoints.publishMessBill(id))).dataMap);

  Future<void> delete(int id) async {
    await _dio.delete<dynamic>(ApiEndpoints.messBill(id));
  }
}

class MessBillRepositoryImpl implements MessBillRepository {
  MessBillRepositoryImpl(this._remote);

  final MessBillRemoteDataSource _remote;

  @override
  Future<List<MessBill>> list() => guardApi(() async {
        final bills = await _remote.list();
        return bills..sort((a, b) => b.monthDate.compareTo(a.monthDate));
      });

  @override
  Future<MessBill> create(MessBillDraft draft) => guardApi(() => _remote.create(draft));

  @override
  Future<MessBill> update(int id, MessBillDraft draft) => guardApi(() => _remote.update(id, draft));

  @override
  Future<MessBill> publish(int id) => guardApi(() => _remote.publish(id));

  @override
  Future<void> delete(int id) => guardApi(() => _remote.delete(id));
}
