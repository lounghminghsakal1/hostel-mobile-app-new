import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../common/mess_bills/mess_bill.dart';
import '../data/mess_bills_data.dart';
import '../domain/mess_bills.dart';

final messBillRepositoryProvider = Provider<MessBillRepository>(
  (ref) => MessBillRepositoryImpl(MessBillRemoteDataSource(ref.watch(dioProvider))),
);

final saveMessBillProvider = Provider((ref) => SaveMessBill(ref.watch(messBillRepositoryProvider)));

final messBillsProvider = FutureProvider.autoDispose<List<MessBill>>(
  (ref) => ref.watch(messBillRepositoryProvider).list(),
);
