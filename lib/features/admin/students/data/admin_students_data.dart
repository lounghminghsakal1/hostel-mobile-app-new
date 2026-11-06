import 'package:dio/dio.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/models/account_status.dart';
import '../../../../core/models/paginated.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_guard.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/utils/json.dart';
import '../../../../core/utils/validators.dart';
import '../../../common/students/student_profile.dart';
import '../domain/admin_students.dart';

extension on StudentDraft {
  Map<String, Object> toJson() => {
        if (email != null) 'email': email!.trim().toLowerCase(),
        if (name != null) 'studentName': name!.trim(),
        if (contactNumber != null) 'contactNumber': Validators.digitsOnly(contactNumber!),
        if (parentMobileNumber != null) 'parentMobileNumber': Validators.digitsOnly(parentMobileNumber!),
        'departmentId': ?departmentId,
        if (rollNumber != null) 'rollNumber': rollNumber!.trim(),
        'roomId': ?roomId,
        'studentImageKey': ?imageKey,
      };
}

class AdminStudentRemoteDataSource {
  AdminStudentRemoteDataSource(this._dio);

  final Dio _dio;

  Future<PageResult<StudentProfile>> list(StudentQuery q) async {
    final res = await _dio.get<dynamic>(
      ApiEndpoints.students,
      queryParameters: query({
        'page': q.page,
        'pageSize': AppConfig.pageSize,
        'by_student_name': q.search,
        'by_department_id': q.departmentId,
        'by_room_id': q.roomId,
        'by_roll_number': q.rollNumber,
      }),
    );
    return (items: res.dataList.map(StudentProfileModel.fromJson).toList(), hasMore: res.meta.hasMore);
  }

  Future<StudentProfile> get(int id) async =>
      StudentProfileModel.fromJson((await _dio.get<dynamic>(ApiEndpoints.student(id))).dataMap);

  Future<StudentProfile> create(StudentDraft draft) async =>
      StudentProfileModel.fromJson((await _dio.post<dynamic>(ApiEndpoints.students, data: draft.toJson())).dataMap);

  Future<StudentProfile> update(int id, StudentDraft changes) async =>
      StudentProfileModel.fromJson((await _dio.patch<dynamic>(ApiEndpoints.student(id), data: changes.toJson())).dataMap);

  Future<void> changeStatus(int id, AccountStatus status) async {
    await _dio.patch<dynamic>(ApiEndpoints.studentStatus(id), data: {'status': status.apiValue});
  }

  Future<void> changeRoom(int id, int roomId) async {
    await _dio.patch<dynamic>(ApiEndpoints.studentRoom(id), data: {'roomId': roomId});
  }

  Future<void> resendActivation(int id) async {
    await _dio.post<dynamic>(ApiEndpoints.activationLink, queryParameters: {'studentProfileId': '$id'});
  }

  Future<PhotoCheck> checkPhoto(String imageKey) async {
    final data = (await _dio.post<dynamic>(ApiEndpoints.studentImageCheck, data: {'studentImageKey': imageKey})).dataMap;
    return PhotoCheck(
      ok: JsonRead.boolean(data['ok'], true),
      message: JsonRead.string(data['message']),
      issues: [
        for (final i in JsonRead.list(data['issues']))
          PhotoIssue(
            code: JsonRead.string(i['code']),
            message: JsonRead.string(i['message']),
            isError: JsonRead.string(i['severity']) == 'error',
          ),
      ],
    );
  }

  Future<List<Department>> departments() async {
    final res = await _dio.get<dynamic>(ApiEndpoints.departments);
    return res.dataList
        .map((d) => Department(id: JsonRead.integer(d['id']), name: JsonRead.string(d['departmentName'])))
        .toList();
  }
}

class AdminStudentRepositoryImpl implements AdminStudentRepository {
  AdminStudentRepositoryImpl(this._remote);

  final AdminStudentRemoteDataSource _remote;

  @override
  Future<PageResult<StudentProfile>> list(StudentQuery query) => guardApi(() => _remote.list(query));

  @override
  Future<StudentProfile> get(int id) => guardApi(() => _remote.get(id));

  @override
  Future<StudentProfile> create(StudentDraft draft) => guardApi(() => _remote.create(draft));

  @override
  Future<StudentProfile> update(int id, StudentDraft changes) => guardApi(() => _remote.update(id, changes));

  @override
  Future<void> changeStatus(int id, AccountStatus status) => guardApi(() => _remote.changeStatus(id, status));

  @override
  Future<void> changeRoom(int id, int roomId) => guardApi(() => _remote.changeRoom(id, roomId));

  @override
  Future<void> resendActivation(int id) => guardApi(() => _remote.resendActivation(id));

  @override
  Future<List<Department>> departments() => guardApi(_remote.departments);

  @override
  Future<PhotoCheck> checkPhoto(String imageKey) => guardApi(() => _remote.checkPhoto(imageKey));
}
