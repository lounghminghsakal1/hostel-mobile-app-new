import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_guard.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/utils/json.dart';
import '../domain/admin_profile.dart';

class AdminProfileRemoteDataSource {
  AdminProfileRemoteDataSource(this._dio);

  final Dio _dio;

  /// `GET /hostel_admin/splash_screen` → `{id, hostelAdminName, hostel: {hostelName}, college: {collegeName}}`.
  Future<AdminProfile> load() async {
    final data = (await _dio.get<dynamic>(ApiEndpoints.adminSplash)).dataMap;
    final hostel = JsonRead.map(data['hostel']) ?? const {};
    final college = JsonRead.map(data['college']) ?? const {};
    return AdminProfile(
      id: JsonRead.integer(data['id']),
      name: JsonRead.string(data['hostelAdminName'], 'Warden'),
      hostelName: JsonRead.string(hostel['hostelName'], 'Your hostel'),
      collegeName: JsonRead.string(college['collegeName']),
      hostelId: JsonRead.integerOrNull(hostel['id'] ?? data['hostelId']),
    );
  }
}

class AdminProfileRepositoryImpl implements AdminProfileRepository {
  AdminProfileRepositoryImpl(this._remote);

  final AdminProfileRemoteDataSource _remote;

  @override
  Future<AdminProfile> load() => guardApi(_remote.load);
}
