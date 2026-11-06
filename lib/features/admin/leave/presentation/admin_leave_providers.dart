import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../data/admin_leave_data.dart';
import '../domain/admin_leave.dart';

final adminLeaveRepositoryProvider = Provider<AdminLeaveRepository>(
  (ref) => AdminLeaveRepositoryImpl(AdminLeaveRemoteDataSource(ref.watch(dioProvider))),
);

final reviewLeaveProvider = Provider((ref) => ReviewLeave(ref.watch(adminLeaveRepositoryProvider)));

final leaveReviewProvider = FutureProvider.autoDispose.family<LeaveReviewDetail, int>(
  (ref, id) => ref.watch(adminLeaveRepositoryProvider).get(id),
);
