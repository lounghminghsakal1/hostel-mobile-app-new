import '../../../../core/error/app_exception.dart';

/// Whether students see an event. They see events that are switched on and
/// haven't ended: live (between the start and end time) or upcoming.
enum EventVisibility {
  live('Live now'),
  upcoming('Upcoming'),
  ended('Ended'),
  hidden('Hidden');

  const EventVisibility(this.label);
  final String label;
}

class HostelEvent {
  const HostelEvent({
    required this.id,
    required this.name,
    required this.description,
    required this.startingAt,
    required this.endingAt,
    required this.isActive,
    this.imageKey,
    this.link,
    this.contactName,
    this.contactPhone,
  });

  final int id;
  final String name;
  final String description;

  /// Real moments (UTC); show them in IST.
  final DateTime startingAt;
  final DateTime endingAt;
  final bool isActive;
  final String? imageKey;
  final String? link;
  final String? contactName;
  final String? contactPhone;

  bool get isOngoing {
    final now = DateTime.now().toUtc();
    return !now.isBefore(startingAt) && now.isBefore(endingAt);
  }

  bool get hasEnded => DateTime.now().toUtc().isAfter(endingAt);

  EventVisibility visibility([DateTime? now]) {
    if (!isActive) return EventVisibility.hidden;
    final at = (now ?? DateTime.now()).toUtc();
    if (!at.isBefore(endingAt)) return EventVisibility.ended;
    if (!at.isBefore(startingAt)) return EventVisibility.live;
    return EventVisibility.upcoming;
  }
}

class EventDraft {
  const EventDraft({
    required this.name,
    required this.description,
    required this.startingAt,
    required this.endingAt,
    required this.isActive,
    this.imageKey,
    this.link,
    this.contactName,
    this.contactPhone,
  });

  final String name;
  final String description;
  final DateTime startingAt;
  final DateTime endingAt;
  final bool isActive;
  final String? imageKey;
  final String? link;
  final String? contactName;
  final String? contactPhone;
}

abstract interface class EventRepository {
  /// Students pass `activeOnly: true`; admins see everything.
  Future<List<HostelEvent>> list({required bool activeOnly, String? search});
  Future<HostelEvent> get(int id);
  Future<HostelEvent> create(EventDraft draft);
  Future<HostelEvent> update(int id, EventDraft draft);
}

/// The backend doesn't check that an event ends after it starts, so the app does.
class SaveEvent {
  const SaveEvent(this._repository);
  final EventRepository _repository;

  Future<HostelEvent> call(EventDraft draft, {int? id}) {
    if (!draft.endingAt.isAfter(draft.startingAt)) {
      throw const AppException('The event must end after it starts.', code: 'invalid_range');
    }
    return id == null ? _repository.create(draft) : _repository.update(id, draft);
  }
}
