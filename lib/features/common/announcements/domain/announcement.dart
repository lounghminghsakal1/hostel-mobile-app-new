import '../../../../core/models/paginated.dart';
import '../../../../core/utils/app_dates.dart';

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

/// Whether students can see an announcement right now. Same rule as the backend
/// (`notice-visibility.utils.js`): live = switched on and today (India time)
/// is between the start and end dates, both included.
enum AnnouncementVisibility {
  live('live', 'Live now'),
  scheduled('scheduled', 'Scheduled'),
  expired('expired', 'Expired'),
  hidden('off', 'Hidden');

  const AnnouncementVisibility(this.apiValue, this.label);

  /// The backend's `visibility` filter value.
  final String apiValue;
  final String label;
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

  AnnouncementVisibility visibility([DateTime? today]) {
    if (!isActive) return AnnouncementVisibility.hidden;
    final day = today ?? AppDates.todayIst();
    if (day.isBefore(startDate)) return AnnouncementVisibility.scheduled;
    if (day.isAfter(endDate)) return AnnouncementVisibility.expired;
    return AnnouncementVisibility.live;
  }
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
/// Students always get live announcements only (the server enforces it);
/// [visibility] is the admin's filter (null = all).
typedef AnnouncementQuery = ({
  AnnouncementVisibility? visibility,
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
