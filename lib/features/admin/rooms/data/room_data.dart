import 'package:dio/dio.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/models/paginated.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_guard.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/utils/json.dart';
import '../domain/room.dart';

Room _room(Map<String, dynamic> json) {
  final count = JsonRead.map(json['_count']);
  return Room(
    id: JsonRead.integer(json['id']),
    number: JsonRead.string(json['roomNumber']),
    capacity: JsonRead.integer(json['capacity']),
    occupied: JsonRead.integer(json['occupied'] ?? count?['studentProfiles']),
  );
}

class RoomRemoteDataSource {
  RoomRemoteDataSource(this._dio);

  final Dio _dio;

  Future<PageResult<Room>> list(RoomQuery q, {int pageSize = AppConfig.pageSize}) async {
    final res = await _dio.get<dynamic>(
      ApiEndpoints.rooms,
      queryParameters: query({
        'page': q.page,
        'pageSize': pageSize,
        'starts_with': q.search,
        'only_vacancy': q.onlyVacancy ? 'true' : null,
      }),
    );
    return (items: res.dataList.map(_room).toList(), hasMore: res.meta.hasMore);
  }

  Future<RoomDetail> get(int id) async {
    final data = (await _dio.get<dynamic>(ApiEndpoints.room(id))).dataMap;
    final occupants = JsonRead.list(data['studentProfiles']).map((s) => RoomOccupant(
          name: JsonRead.string(s['studentName'], 'Student'),
          rollNumber: JsonRead.stringOrNull(s['rollNumber']),
          contactNumber: JsonRead.stringOrNull(s['contactNumber']),
          departmentName: JsonRead.stringOrNull(JsonRead.map(s['department'])?['departmentName']),
          studentId: JsonRead.integerOrNull(s['id']),
          imageKey: JsonRead.stringOrNull(s['studentImageKey']),
        ));
    return RoomDetail(room: _room(data), occupants: occupants.toList());
  }

  Future<Room> create(String number, int capacity) async =>
      _room((await _dio.post<dynamic>(ApiEndpoints.rooms, data: {'roomNumber': number, 'capacity': capacity})).dataMap);

  Future<Room> update(int id, String number, int capacity) async => _room(
      (await _dio.patch<dynamic>(ApiEndpoints.room(id), data: {'roomNumber': number, 'capacity': capacity})).dataMap);
}

class RoomRepositoryImpl implements RoomRepository {
  RoomRepositoryImpl(this._remote);

  final RoomRemoteDataSource _remote;

  @override
  Future<PageResult<Room>> list(RoomQuery query) => guardApi(() => _remote.list(query));

  @override
  Future<List<Room>> all() => guardApi(() async {
        final page = await _remote.list((search: null, onlyVacancy: false, page: 1), pageSize: 100);
        return page.items..sort((a, b) => a.number.compareTo(b.number));
      });

  @override
  Future<RoomDetail> get(int id) => guardApi(() => _remote.get(id));

  @override
  Future<Room> create({required String number, required int capacity}) => guardApi(() => _remote.create(number, capacity));

  @override
  Future<Room> update(int id, {required String number, required int capacity}) =>
      guardApi(() => _remote.update(id, number, capacity));
}
