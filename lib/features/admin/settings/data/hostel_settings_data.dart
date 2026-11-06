import 'package:dio/dio.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_guard.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/utils/json.dart';
import '../../home/domain/admin_profile.dart';
import '../domain/hostel_settings.dart';

HostelSettings _fromJson(Map<String, dynamic> json) => HostelSettings(
      id: JsonRead.integer(json['id']),
      name: JsonRead.string(json['hostelName']),
      location: JsonRead.string(json['location']),
      contactPersonName: JsonRead.string(json['contactPersonName']),
      contactNumber: JsonRead.string(json['contactNumber']),
      windowStart: JsonRead.string(json['attendanceMarkingStartTime'], '20:30'),
      windowEnd: JsonRead.string(json['attendanceMarkingEndTime'], '22:00'),
      radiusMeters: JsonRead.decimal(json['attendanceRadius'], 800),
    );

class HostelSettingsRemoteDataSource {
  HostelSettingsRemoteDataSource(this._dio);

  final Dio _dio;

  /// The admin splash doesn't return the hostel id yet, so when it's missing
  /// the hostel is found by name in `GET /hostels` (all hostels of the college).
  Future<HostelSettings> load(AdminProfile admin) async {
    if (admin.hostelId != null) {
      return _fromJson((await _dio.get<dynamic>(ApiEndpoints.hostel(admin.hostelId!))).dataMap);
    }
    final hostels = (await _dio.get<dynamic>(ApiEndpoints.hostels)).dataList;
    final match = hostels.where((h) => JsonRead.string(h['hostelName']) == admin.hostelName).toList();
    if (match.length != 1) {
      throw const AppException("We couldn't work out which hostel is yours. Ask the backend team to add the hostel id to the admin splash.");
    }
    return _fromJson(match.single);
  }

  Future<HostelSettings> save(HostelSettings s) async {
    final res = await _dio.patch<dynamic>(
      ApiEndpoints.hostel(s.id),
      data: {
        'hostelName': s.name.trim(),
        'location': s.location.trim(),
        'contactPersonName': s.contactPersonName.trim(),
        'contactNumber': s.contactNumber.trim(),
        'attendanceMarkingStartTime': s.windowStart,
        'attendanceMarkingEndTime': s.windowEnd,
        'attendanceRadius': s.radiusMeters,
      },
    );
    return _fromJson(res.dataMap);
  }
}

class HostelSettingsRepositoryImpl implements HostelSettingsRepository {
  HostelSettingsRepositoryImpl(this._remote);

  final HostelSettingsRemoteDataSource _remote;

  @override
  Future<HostelSettings> load(AdminProfile admin) => guardApi(() => _remote.load(admin));

  @override
  Future<HostelSettings> save(HostelSettings settings) => guardApi(() => _remote.save(settings));
}
