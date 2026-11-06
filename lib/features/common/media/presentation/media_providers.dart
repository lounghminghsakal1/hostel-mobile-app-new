import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_guard.dart';
import '../data/media_remote_data_source.dart';
import '../domain/media_repository.dart';

final mediaRepositoryProvider = Provider<MediaRepository>(
  (ref) => MediaRepositoryImpl(MediaRemoteDataSource(ref.watch(dioProvider), ref.watch(storageUploadDioProvider))),
);

final uploadImageProvider = Provider((ref) => UploadImage(ref.watch(mediaRepositoryProvider)));

/// Signed image URL for an object key. Signed URLs expire after 5 minutes,
/// so the value is kept only while a widget uses it, and for 4 minutes at most.
final signedImageUrlProvider = FutureProvider.autoDispose.family<String, String>((ref, objectKey) async {
  final url = await guardApi(() => ref.watch(mediaRepositoryProvider).imageUrl(objectKey));
  final link = ref.keepAlive();
  final timer = Timer(const Duration(minutes: 4), link.close);
  ref.onDispose(timer.cancel);
  return url;
});
