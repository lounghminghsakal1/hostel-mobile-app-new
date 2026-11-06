import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_guard.dart';
import '../../../../core/network/api_response.dart';
import '../../../common/students/student_profile.dart';
import '../domain/student_profile_repository.dart';

/// `GET /students/{id}` is allowed for students too (their own profile).
class StudentProfileRemoteDataSource {
  StudentProfileRemoteDataSource(this._dio);

  final Dio _dio;

  Future<StudentProfileModel> get(int id) async =>
      StudentProfileModel.fromJson((await _dio.get<dynamic>(ApiEndpoints.student(id))).dataMap);
}

class StudentProfileRepositoryImpl implements StudentProfileRepository {
  StudentProfileRepositoryImpl(this._remote);

  final StudentProfileRemoteDataSource _remote;

  @override
  Future<StudentProfile> myProfile(int studentProfileId) => guardApi(() => _remote.get(studentProfileId));
}
