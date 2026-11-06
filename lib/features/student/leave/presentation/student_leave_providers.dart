import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../common/leave/leave_application.dart';
import '../data/student_leave_data.dart';
import '../domain/student_leave.dart';

final studentLeaveRepositoryProvider = Provider<StudentLeaveRepository>(
  (ref) => StudentLeaveRepositoryImpl(StudentLeaveRemoteDataSource(ref.watch(dioProvider))),
);

final submitLeaveRequestProvider = Provider((ref) => SubmitLeaveRequest(ref.watch(studentLeaveRepositoryProvider)));
final cancelLeaveRequestProvider = Provider((ref) => CancelLeaveRequest(ref.watch(studentLeaveRepositoryProvider)));

final myLeavesProvider = FutureProvider.autoDispose<List<LeaveApplication>>(
  (ref) => ref.watch(studentLeaveRepositoryProvider).myLeaves(),
);

/// A student can have only one pending request at a time.
final pendingLeaveProvider = Provider.autoDispose<LeaveApplication?>((ref) {
  final leaves = ref.watch(myLeavesProvider).value ?? const [];
  for (final leave in leaves) {
    if (leave.isPending) return leave;
  }
  return null;
});

final myLeaveProvider = FutureProvider.autoDispose.family<LeaveApplication, int>(
  (ref, id) => ref.watch(studentLeaveRepositoryProvider).myLeave(id),
);
