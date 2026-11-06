import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../common/students/student_profile.dart';
import '../../home/presentation/student_home_providers.dart';
import '../data/student_profile_data.dart';
import '../domain/student_profile_repository.dart';

final studentProfileRepositoryProvider = Provider<StudentProfileRepository>(
  (ref) => StudentProfileRepositoryImpl(StudentProfileRemoteDataSource(ref.watch(dioProvider))),
);

/// The signed-in student's own profile. The profile id comes from the splash data.
final myProfileProvider = FutureProvider.autoDispose<StudentProfile>((ref) async {
  final home = await ref.watch(studentHomeProvider.future);
  return ref.watch(studentProfileRepositoryProvider).myProfile(home.studentProfileId);
});
