import 'dart:typed_data';

/// What an upload is for; the backend uses it as the S3 folder.
enum MediaFor {
  attendanceImage('attendance_image'),
  studentImage('student_image'),
  eventImage('event_image');

  const MediaFor(this.apiValue);
  final String apiValue;
}

abstract interface class MediaRepository {
  /// Uploads a JPEG and returns the object key to send to other endpoints.
  Future<String> uploadImage(MediaFor mediaFor, Uint8List bytes);

  /// Short-lived (5 minute) signed URL for an object key.
  Future<String> imageUrl(String objectKey);
}

class UploadImage {
  const UploadImage(this._repository);
  final MediaRepository _repository;

  Future<String> call(MediaFor mediaFor, Uint8List bytes) => _repository.uploadImage(mediaFor, bytes);
}
