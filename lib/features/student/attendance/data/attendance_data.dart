import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_guard.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/utils/json.dart';
import '../domain/attendance.dart';

class AttendanceRemoteDataSource {
  AttendanceRemoteDataSource(this._dio);

  final Dio _dio;

  Future<AttendanceMark> submit({required String capturedImageKey, required GeoPoint location}) async {
    final data = (await _dio.post<dynamic>(
      ApiEndpoints.attendance,
      data: {
        'capturedImageKey': capturedImageKey,
        'latitude': location.latitude,
        'longitude': location.longitude,
      },
    ))
        .dataMap;
    return AttendanceMark(
      reportedTime: JsonRead.instant(data['reportedTime']) ?? DateTime.now().toUtc(),
      insideHostelRadius: JsonRead.boolean(data['isLocatedWithinHostelRadius'], true),
      distanceFromHostelMeters: JsonRead.decimalOrNull(data['locationDeviationFromHostel']),
      faceMatchPercent: JsonRead.decimalOrNull(data['faceMatchingPercentage']),
    );
  }
}

class AttendanceRepositoryImpl implements AttendanceRepository {
  AttendanceRepositoryImpl(this._remote);

  final AttendanceRemoteDataSource _remote;

  @override
  Future<AttendanceMark> submit({required String capturedImageKey, required GeoPoint location}) =>
      guardApi(() => _remote.submit(capturedImageKey: capturedImageKey, location: location));
}
