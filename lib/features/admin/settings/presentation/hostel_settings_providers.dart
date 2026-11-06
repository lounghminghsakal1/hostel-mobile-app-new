import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../home/presentation/admin_providers.dart';
import '../data/hostel_settings_data.dart';
import '../domain/hostel_settings.dart';

final hostelSettingsRepositoryProvider = Provider<HostelSettingsRepository>(
  (ref) => HostelSettingsRepositoryImpl(HostelSettingsRemoteDataSource(ref.watch(dioProvider))),
);

final hostelSettingsProvider = FutureProvider.autoDispose<HostelSettings>((ref) async {
  final admin = await ref.watch(adminProfileProvider.future);
  return ref.watch(hostelSettingsRepositoryProvider).load(admin);
});
