import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../data/admin_profile_data.dart';
import '../domain/admin_profile.dart';

final adminProfileRepositoryProvider = Provider<AdminProfileRepository>(
  (ref) => AdminProfileRepositoryImpl(AdminProfileRemoteDataSource(ref.watch(dioProvider))),
);

/// Used by every admin tab, so it stays alive; reloads when another user signs in.
final adminProfileProvider = FutureProvider<AdminProfile>((ref) {
  ref.watch(currentUserProvider);
  return ref.watch(adminProfileRepositoryProvider).load();
});
