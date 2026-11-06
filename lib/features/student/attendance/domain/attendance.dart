import 'dart:typed_data';

import '../../../../core/services/location_service.dart';
import '../../../common/media/domain/media_repository.dart';

/// The saved check-in returned by `POST /attendance_records`.
class AttendanceMark {
  const AttendanceMark({
    required this.reportedTime,
    required this.insideHostelRadius,
    this.distanceFromHostelMeters,
    this.faceMatchPercent,
  });

  final DateTime reportedTime;
  final bool insideHostelRadius;
  final double? distanceFromHostelMeters;

  /// Not shown to students: the score isn't enforced yet.
  final double? faceMatchPercent;
}

abstract interface class AttendanceRepository {
  Future<AttendanceMark> submit({required String capturedImageKey, required GeoPoint location});
}

/// Uploads the selfie to storage, then records attendance with its key and
/// the GPS position. One check-in per day; the server enforces that.
class MarkAttendance {
  const MarkAttendance(this._attendance, this._media);

  final AttendanceRepository _attendance;
  final MediaRepository _media;

  Future<AttendanceMark> call({required Uint8List selfie, required GeoPoint location}) async {
    final key = await _media.uploadImage(MediaFor.attendanceImage, selfie);
    return _attendance.submit(capturedImageKey: key, location: location);
  }
}
