import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_guard.dart';
import '../../../../core/network/api_response.dart';
import '../domain/media_repository.dart';

class MediaRemoteDataSource {
  MediaRemoteDataSource(this._api, this._storageClient);

  final Dio _api;
  final Dio _storageClient;

  /// `GET /media/upload_url?media_for=...` → `{uploadURL, objectKey}`.
  Future<({String uploadUrl, String objectKey})> uploadTarget(MediaFor mediaFor) async {
    final res = await _api.get<dynamic>(ApiEndpoints.uploadUrl, queryParameters: {'media_for': mediaFor.apiValue});
    final data = res.dataMap;
    return (uploadUrl: data['uploadURL'] as String, objectKey: data['objectKey'] as String);
  }

  /// PUT the bytes straight to S3. The signed URL was created for image/jpeg.
  Future<void> putToStorage(String uploadUrl, Uint8List bytes) async {
    await _storageClient.put<dynamic>(
      uploadUrl,
      data: Stream<List<int>>.value(bytes),
      options: Options(
        headers: {
          Headers.contentTypeHeader: 'image/jpeg',
          Headers.contentLengthHeader: bytes.length,
        },
      ),
    );
  }

  /// `GET /media/download_url?image_key=...` → `{downloadUrl}`.
  Future<String> downloadUrl(String objectKey) async {
    final res = await _api.get<dynamic>(ApiEndpoints.downloadUrl, queryParameters: {'image_key': objectKey});
    return res.dataMap['downloadUrl'] as String;
  }
}

class MediaRepositoryImpl implements MediaRepository {
  MediaRepositoryImpl(this._remote);

  final MediaRemoteDataSource _remote;

  @override
  Future<String> uploadImage(MediaFor mediaFor, Uint8List bytes) => guardApi(() async {
        final target = await _remote.uploadTarget(mediaFor);
        await _remote.putToStorage(target.uploadUrl, bytes);
        return target.objectKey;
      });

  @override
  Future<String> imageUrl(String objectKey) => guardApi(() => _remote.downloadUrl(objectKey));
}
