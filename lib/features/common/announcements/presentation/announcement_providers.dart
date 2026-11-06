import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/paginated.dart';
import '../../../../core/network/api_client.dart';
import '../data/announcement_data.dart';
import '../domain/announcement.dart';

final announcementRepositoryProvider = Provider<AnnouncementRepository>(
  (ref) => AnnouncementRepositoryImpl(AnnouncementRemoteDataSource(ref.watch(dioProvider))),
);

final announcementsProvider =
    FutureProvider.autoDispose.family<PageResult<Announcement>, AnnouncementQuery>(
  (ref, query) => ref.watch(announcementRepositoryProvider).list(query),
);

final announcementProvider = FutureProvider.autoDispose.family<Announcement, int>(
  (ref, id) => ref.watch(announcementRepositoryProvider).get(id),
);
