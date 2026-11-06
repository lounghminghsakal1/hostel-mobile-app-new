import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../data/event_data.dart';
import '../domain/hostel_event.dart';

final eventRepositoryProvider = Provider<EventRepository>(
  (ref) => EventRepositoryImpl(EventRemoteDataSource(ref.watch(dioProvider))),
);

final saveEventProvider = Provider((ref) => SaveEvent(ref.watch(eventRepositoryProvider)));

/// `activeOnly: true` for students (upcoming and ongoing only).
final eventsProvider = FutureProvider.autoDispose.family<List<HostelEvent>, bool>((ref, activeOnly) async {
  final events = await ref.watch(eventRepositoryProvider).list(activeOnly: activeOnly);
  return activeOnly ? events.where((e) => !e.hasEnded).toList() : events;
});

final eventProvider = FutureProvider.autoDispose.family<HostelEvent, int>(
  (ref, id) => ref.watch(eventRepositoryProvider).get(id),
);
