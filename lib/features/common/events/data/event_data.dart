import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_guard.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/utils/app_dates.dart';
import '../../../../core/utils/json.dart';
import '../domain/hostel_event.dart';

class HostelEventModel extends HostelEvent {
  const HostelEventModel({
    required super.id,
    required super.name,
    required super.description,
    required super.startingAt,
    required super.endingAt,
    required super.isActive,
    super.imageKey,
    super.link,
    super.contactName,
    super.contactPhone,
  });

  factory HostelEventModel.fromJson(Map<String, dynamic> json) {
    final start = JsonRead.instant(json['startingAt']) ?? DateTime.now().toUtc();
    return HostelEventModel(
      id: JsonRead.integer(json['id']),
      name: JsonRead.string(json['eventName']),
      description: JsonRead.string(json['eventDescription']),
      startingAt: start,
      endingAt: JsonRead.instant(json['endingAt']) ?? start,
      isActive: JsonRead.boolean(json['isActive'], true),
      imageKey: JsonRead.stringOrNull(json['eventImageKey']),
      link: JsonRead.stringOrNull(json['eventLink']),
      contactName: JsonRead.stringOrNull(json['contactPersonName']),
      contactPhone: JsonRead.stringOrNull(json['contactPersonPhone']),
    );
  }
}

extension EventDraftJson on EventDraft {
  Map<String, Object> toJson() => {
        'eventName': name.trim(),
        'eventDescription': description.trim(),
        'startingAt': AppDates.apiInstant(startingAt),
        'endingAt': AppDates.apiInstant(endingAt),
        'isActive': isActive,
        'eventImageKey': ?imageKey,
        if (link != null && link!.trim().isNotEmpty) 'eventLink': link!.trim(),
        if (contactName != null && contactName!.trim().isNotEmpty) 'contactPersonName': contactName!.trim(),
        if (contactPhone != null && contactPhone!.trim().isNotEmpty) 'contactPersonPhone': contactPhone!.trim(),
      };
}

class EventRemoteDataSource {
  EventRemoteDataSource(this._dio);

  final Dio _dio;

  /// The events list ignores page/pageSize today (it returns everything),
  /// so the app asks for the maximum and doesn't page.
  Future<List<HostelEventModel>> list({required bool activeOnly, String? search}) async {
    final res = await _dio.get<dynamic>(
      ApiEndpoints.events,
      queryParameters: query({
        'page': 1,
        'pageSize': 100,
        'is_active': activeOnly ? 'true' : null,
        'by_event_name': search,
      }),
    );
    return res.dataList.map(HostelEventModel.fromJson).toList();
  }

  Future<HostelEventModel> get(int id) async =>
      HostelEventModel.fromJson((await _dio.get<dynamic>(ApiEndpoints.event(id))).dataMap);

  Future<HostelEventModel> create(EventDraft draft) async {
    final body = draft.toJson()..remove('isActive'); // create doesn't accept isActive
    return HostelEventModel.fromJson((await _dio.post<dynamic>(ApiEndpoints.events, data: body)).dataMap);
  }

  Future<HostelEventModel> update(int id, EventDraft draft) async =>
      HostelEventModel.fromJson((await _dio.patch<dynamic>(ApiEndpoints.event(id), data: draft.toJson())).dataMap);
}

class EventRepositoryImpl implements EventRepository {
  EventRepositoryImpl(this._remote);

  final EventRemoteDataSource _remote;

  @override
  Future<List<HostelEvent>> list({required bool activeOnly, String? search}) => guardApi(() async {
        final events = await _remote.list(activeOnly: activeOnly, search: search);
        return events..sort((a, b) => a.startingAt.compareTo(b.startingAt));
      });

  @override
  Future<HostelEvent> get(int id) => guardApi(() => _remote.get(id));

  @override
  Future<HostelEvent> create(EventDraft draft) => guardApi(() => _remote.create(draft));

  @override
  Future<HostelEvent> update(int id, EventDraft draft) => guardApi(() => _remote.update(id, draft));
}
