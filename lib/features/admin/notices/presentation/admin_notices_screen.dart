import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../common/announcements/domain/announcement.dart';
import '../../../common/announcements/presentation/announcement_card.dart';
import '../../../common/announcements/presentation/announcement_providers.dart';
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
  bool? _active = true;
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
      key: ValueKey((_active, _reload)),
      bottomPadding: 96,
      fetch: (page) => repo.list((activeOnly: _active, type: null, importantOnly: false, search: null, page: page)),
      header: [
        FilterChipBar<bool?>(
          selected: _active,
          onSelected: (v) => setState(() => _active = v),
          options: const [FilterOption(true, 'Active'), FilterOption(false, 'Inactive'), FilterOption(null, 'All')],
        ),
      ],
      empty: const EmptyView(
        icon: Icons.campaign_outlined,
        title: 'No announcements',
        message: 'Post one with the button below. Students see it on their home screen.',
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
                for (final e in list.reversed)
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
}
