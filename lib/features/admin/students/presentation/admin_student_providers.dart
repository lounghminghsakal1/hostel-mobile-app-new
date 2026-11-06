import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../common/media/presentation/media_providers.dart';
import '../../../common/students/student_profile.dart';
import '../../rooms/presentation/room_providers.dart';
import '../data/admin_students_data.dart';
import '../domain/admin_students.dart';

final adminStudentRepositoryProvider = Provider<AdminStudentRepository>(
  (ref) => AdminStudentRepositoryImpl(AdminStudentRemoteDataSource(ref.watch(dioProvider))),
);

final saveStudentProvider = Provider(
  (ref) => SaveStudent(ref.watch(adminStudentRepositoryProvider), ref.watch(mediaRepositoryProvider)),
);

final departmentsProvider = FutureProvider.autoDispose<List<Department>>(
  (ref) => ref.watch(adminStudentRepositoryProvider).departments(),
);

/// The list endpoint only returns ids, so names are looked up client-side.
final departmentNamesProvider = Provider.autoDispose<Map<int, String>>((ref) {
  final list = ref.watch(departmentsProvider).value ?? const [];
  return {for (final d in list) d.id: d.name};
});

final roomNumbersProvider = Provider.autoDispose<Map<int, String>>((ref) {
  final list = ref.watch(allRoomsProvider).value ?? const [];
  return {for (final r in list) r.id: r.number};
});

final adminStudentProvider = FutureProvider.autoDispose.family<StudentProfile, int>(
  (ref, id) => ref.watch(adminStudentRepositoryProvider).get(id),
);
