import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../common/announcements/domain/announcement.dart';
import '../../../common/announcements/presentation/announcement_card.dart';
import '../../../common/announcements/presentation/announcement_providers.dart';
import '../../../common/events/domain/hostel_event.dart';
import '../../../common/events/presentation/event_providers.dart';
import '../../../common/events/presentation/event_widgets.dart';
import '../../shell/admin_top_bar.dart';

/// Manage announcements and events. Data and models are shared with the
/// student app (features/common); only the admin screens live here.
class AdminNoticesScreen extends ConsumerStatefulWidget {
  const AdminNoticesScreen({super.key});

  @override
  ConsumerState<AdminNoticesScreen> createState() => _AdminNoticesScreenState();
}

class _AdminNoticesScreenState extends ConsumerState<AdminNoticesScreen> {
  int _tab = 0;
  AnnouncementVisibility? _visibility = AnnouncementVisibility.live;
  int _reload = 0;

  Future<void> _create() async {
    await context.push(_tab == 0 ? Routes.newAnnouncement : Routes.newEvent);
    if (!mounted) return;
    setState(() => _reload++);
    ref.invalidate(eventsProvider(false));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.colors;
    return Scaffold(
      appBar: const AdminTopBar(title: 'Notices', subtitle: 'What students see on their home screen'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        backgroundColor: p.accent,
        foregroundColor: p.onAccent,
        icon: const Icon(Icons.add_rounded),
        label: Text(_tab == 0 ? 'New announcement' : 'New event'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
            child: SegmentedTabs(labels: const ['Announcements', 'Events'], selected: _tab, onChanged: (i) => setState(() => _tab = i)),
          ),
          const SizedBox(height: 14),
          Expanded(child: _tab == 0 ? _announcements() : _events()),
        ],
      ),
    );
  }

  Widget _announcements() {
    final repo = ref.read(announcementRepositoryProvider);
    return PagedList<Announcement>(
      query: (_visibility, _reload),
      bottomPadding: 96,
      fetch: (page) => repo.list((visibility: _visibility, type: null, importantOnly: false, search: null, page: page)),
      header: [
        const InfoCallout(
          icon: Icons.visibility_outlined,
          title: 'Live now',
          message: 'means students can see it: it is switched on and today is between its start and end dates. '
              'Scheduled ones appear on their start date; expired and hidden ones are never shown.',
        ),
        FilterChipBar<AnnouncementVisibility?>(
          selected: _visibility,
          onSelected: (v) => setState(() => _visibility = v),
          options: [
            for (final v in AnnouncementVisibility.values) FilterOption(v, v.label),
            const FilterOption(null, 'All'),
          ],
        ),
      ],
      empty: EmptyView(
        icon: Icons.campaign_outlined,
        title: _visibility == AnnouncementVisibility.live ? 'Nothing live right now' : 'No announcements',
        message: _visibility == AnnouncementVisibility.live
            ? 'Students see no announcements today. Post one, or check Scheduled and Expired.'
            : 'Post one with the button below. Students see it on their home screen while it is live.',
      ),
      itemBuilder: (context, a) => AnnouncementCard(
        announcement: a,
        showStatus: true,
        onTap: () async {
          await context.push(Routes.adminAnnouncement(a.id));
          if (mounted) setState(() => _reload++);
        },
      ),
    );
  }

  Widget _events() {
    final events = ref.watch(eventsProvider(false));
    return AsyncValueView(
      value: events,
      onRetry: () => ref.invalidate(eventsProvider(false)),
      data: (list) => list.isEmpty
          ? const EmptyView(icon: Icons.celebration_outlined, title: 'No events yet', message: 'Create one with the button below.')
          : ScreenList(
              gap: 14,
              bottomPadding: 96,
              onRefresh: () async => ref.invalidate(eventsProvider(false)),
              children: [
                const InfoCallout(
                  icon: Icons.visibility_outlined,
                  title: 'Live now',
                  message: 'means the event is happening: the current date and time are between its start and end. '
                      'Students see live and upcoming events that are switched on; ended and hidden ones are not shown.',
                ),
                for (final e in _adminOrder(list))
                  EventCard(
                    event: e,
                    showStatus: true,
                    onTap: () async {
                      await context.push(Routes.adminEvent(e.id));
                      ref.invalidate(eventsProvider(false));
                    },
                  ),
              ],
            ),
    );
  }

  /// Live first, then upcoming (soonest first), then ended (most recent first).
  /// Hidden events sit with their time group, marked Hidden.
  static List<HostelEvent> _adminOrder(List<HostelEvent> events) {
    int group(HostelEvent e) {
      final now = DateTime.now().toUtc();
      if (!now.isBefore(e.endingAt)) return 2;
      return now.isBefore(e.startingAt) ? 1 : 0;
    }

    return [...events]..sort((a, b) {
        final byGroup = group(a).compareTo(group(b));
        if (byGroup != 0) return byGroup;
        return group(a) == 2 ? b.endingAt.compareTo(a.endingAt) : a.startingAt.compareTo(b.startingAt);
      });
  }
}
