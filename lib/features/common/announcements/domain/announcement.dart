import '../../../../core/models/paginated.dart';

enum AnnouncementType {
  hostel('HOSTEL_ANNOUNCEMENT', 'Hostel'),
  college('COLLEGE_ANNOUNCEMENT', 'College'),
  other('OTHER', 'Other');

  const AnnouncementType(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static AnnouncementType fromApi(Object? v) =>
      AnnouncementType.values.firstWhere((t) => t.apiValue == v, orElse: () => AnnouncementType.other);
}

class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.description,
    required this.isActive,
    required this.startDate,
    required this.endDate,
    required this.type,
    required this.isImportant,
    required this.pushNotification,
    this.linkUrl,
  });

  final int id;
  final String title;
  final String description;
  final String? linkUrl;
  final bool isActive;

  /// Calendar dates (no time zone).
  final DateTime startDate;
  final DateTime endDate;
  final AnnouncementType type;
  final bool isImportant;
  final bool pushNotification;
}

/// What an admin fills in to create or edit an announcement.
class AnnouncementDraft {
  const AnnouncementDraft({
    required this.title,
    required this.description,
    required this.isActive,
    required this.startDate,
    required this.endDate,
    required this.type,
    required this.isImportant,
    required this.pushNotification,
    this.linkUrl,
  });

  final String title;
  final String description;
  final String? linkUrl;
  final bool isActive;
  final DateTime startDate;
  final DateTime endDate;
  final AnnouncementType type;
  final bool isImportant;
  final bool pushNotification;
}

/// Filters for the announcement list. A record, so it works as a provider key.
typedef AnnouncementQuery = ({
  bool? activeOnly,
  AnnouncementType? type,
  bool importantOnly,
  String? search,
  int page,
});

abstract interface class AnnouncementRepository {
  Future<PageResult<Announcement>> list(AnnouncementQuery query);
  Future<Announcement> get(int id);
  Future<Announcement> create(AnnouncementDraft draft);
  Future<Announcement> update(int id, AnnouncementDraft draft);
}
