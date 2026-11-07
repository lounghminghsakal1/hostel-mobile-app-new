import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/models/paginated.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../common/announcements/domain/announcement.dart';
import '../../../common/announcements/presentation/announcement_card.dart';
import '../../../common/announcements/presentation/announcement_providers.dart';
import '../../../common/events/presentation/event_providers.dart';
import '../../../common/events/presentation/event_widgets.dart';

enum _AnnouncementFilter { all, important, hostel, college, other }

/// Student "Notices" tab: Announcements and Events. Read-only, so it uses
/// the shared announcement and event modules directly.
class NoticesScreen extends ConsumerStatefulWidget {
  const NoticesScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  ConsumerState<NoticesScreen> createState() => _NoticesScreenState();
}

class _NoticesScreenState extends ConsumerState<NoticesScreen> {
  late int _tab = widget.initialTab;
  _AnnouncementFilter _filter = _AnnouncementFilter.all;

  @override
  void didUpdateWidget(NoticesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) _tab = widget.initialTab;
  }

  Future<PageResult<Announcement>> _fetch(int page) {
    return ref.read(announcementRepositoryProvider).list((
      visibility: AnnouncementVisibility.live,
      importantOnly: _filter == _AnnouncementFilter.important,
      type: switch (_filter) {
        _AnnouncementFilter.hostel => AnnouncementType.hostel,
        _AnnouncementFilter.college => AnnouncementType.college,
        _AnnouncementFilter.other => AnnouncementType.other,
        _ => null,
      },
      search: null,
      page: page,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final tabs = Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
      child: SegmentedTabs(
        labels: const ['Announcements', 'Events'],
        selected: _tab,
        onChanged: (i) => setState(() => _tab = i),
      ),
    );

    return Scaffold(
      appBar: const AppTopBar(title: 'Notices'),
      body: Column(
        children: [
          tabs,
          const SizedBox(height: 14),
          Expanded(child: _tab == 0 ? _announcements() : const _EventsList()),
        ],
      ),
    );
  }

  Widget _announcements() {
    return PagedList<Announcement>(
      key: ValueKey(_filter),
      fetch: _fetch,
      header: [
        FilterChipBar<_AnnouncementFilter>(
          selected: _filter,
          onSelected: (f) => setState(() => _filter = f),
          options: const [
            FilterOption(_AnnouncementFilter.all, 'All'),
            FilterOption(_AnnouncementFilter.important, 'Important'),
            FilterOption(_AnnouncementFilter.hostel, 'Hostel'),
            FilterOption(_AnnouncementFilter.college, 'College'),
            FilterOption(_AnnouncementFilter.other, 'Other'),
          ],
        ),
      ],
      empty: const EmptyView(
        icon: Icons.campaign_outlined,
        title: 'No announcements',
        message: 'When your hostel posts something, it shows up here.',
      ),
      itemBuilder: (context, a) => AnnouncementCard(
        announcement: a,
        onTap: () => context.push(Routes.studentAnnouncement(a.id)),
      ),
    );
  }
}

class _EventsList extends ConsumerWidget {
  const _EventsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(eventsProvider(true));
    return AsyncValueView(
      value: events,
      onRetry: () => ref.invalidate(eventsProvider(true)),
      data: (list) => list.isEmpty
          ? const EmptyView(
              icon: Icons.celebration_outlined,
              title: 'No upcoming events',
              message: 'New events from your hostel will show up here.',
            )
          : ScreenList(
              gap: 14,
              onRefresh: () async => ref.invalidate(eventsProvider(true)),
              children: [
                for (final e in list) EventCard(event: e, onTap: () => context.push(Routes.studentEvent(e.id))),
              ],
            ),
    );
  }
}
