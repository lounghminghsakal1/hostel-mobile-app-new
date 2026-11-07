import 'package:dio/dio.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/models/paginated.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_guard.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/utils/app_dates.dart';
import '../../../../core/utils/json.dart';
import '../domain/announcement.dart';

class AnnouncementModel extends Announcement {
  const AnnouncementModel({
    required super.id,
    required super.title,
    required super.description,
    required super.isActive,
    required super.startDate,
    required super.endDate,
    required super.type,
    required super.isImportant,
    required super.pushNotification,
    super.linkUrl,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    final start = JsonRead.calendarDate(json['startDate']) ?? AppDates.todayIst();
    return AnnouncementModel(
      id: JsonRead.integer(json['id']),
      title: JsonRead.string(json['title']),
      description: JsonRead.string(json['description']),
      linkUrl: JsonRead.stringOrNull(json['linkUrl']),
      isActive: json['status'] == 'ACTIVE',
      startDate: start,
      endDate: JsonRead.calendarDate(json['endDate']) ?? start,
      type: AnnouncementType.fromApi(json['announcementType']),
      isImportant: JsonRead.boolean(json['isImportant']),
      pushNotification: JsonRead.boolean(json['pushNotification']),
    );
  }
}

extension AnnouncementDraftJson on AnnouncementDraft {
  Map<String, Object> toJson() => {
        'title': title.trim(),
        'description': description.trim(),
        'status': isActive ? 'ACTIVE' : 'INACTIVE',
        'announcementType': type.apiValue,
        'startDate': AppDates.apiDate(startDate),
        'endDate': AppDates.apiDate(endDate),
        'isImportant': isImportant,
        'pushNotification': pushNotification,
        // An empty link must be omitted; the backend rejects "" and null.
        if (linkUrl != null && linkUrl!.trim().isNotEmpty) 'linkUrl': linkUrl!.trim(),
      };
}

class AnnouncementRemoteDataSource {
  AnnouncementRemoteDataSource(this._dio);

  final Dio _dio;

  Future<PageResult<AnnouncementModel>> list(AnnouncementQuery q) async {
    final res = await _dio.get<dynamic>(
      ApiEndpoints.announcements,
      queryParameters: query({
        'page': q.page,
        'pageSize': AppConfig.pageSize,
        'visibility': q.visibility?.apiValue,
        'by_announcement_type': q.type?.apiValue,
        'only_important': q.importantOnly ? 'true' : null,
        'by_announcement_title': q.search,
      }),
    );
    return (items: res.dataList.map(AnnouncementModel.fromJson).toList(), hasMore: res.meta.hasMore);
  }

  Future<AnnouncementModel> get(int id) async =>
      AnnouncementModel.fromJson((await _dio.get<dynamic>(ApiEndpoints.announcement(id))).dataMap);

  Future<AnnouncementModel> create(AnnouncementDraft draft) async =>
      AnnouncementModel.fromJson((await _dio.post<dynamic>(ApiEndpoints.announcements, data: draft.toJson())).dataMap);

  Future<AnnouncementModel> update(int id, AnnouncementDraft draft) async => AnnouncementModel.fromJson(
      (await _dio.patch<dynamic>(ApiEndpoints.announcement(id), data: draft.toJson())).dataMap);
}

class AnnouncementRepositoryImpl implements AnnouncementRepository {
  AnnouncementRepositoryImpl(this._remote);

  final AnnouncementRemoteDataSource _remote;

  @override
  Future<PageResult<Announcement>> list(AnnouncementQuery query) => guardApi(() => _remote.list(query));

  @override
  Future<Announcement> get(int id) => guardApi(() => _remote.get(id));

  @override
  Future<Announcement> create(AnnouncementDraft draft) => guardApi(() => _remote.create(draft));

  @override
  Future<Announcement> update(int id, AnnouncementDraft draft) => guardApi(() => _remote.update(id, draft));
}
