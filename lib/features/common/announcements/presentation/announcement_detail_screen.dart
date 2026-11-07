import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/app_dates.dart';
import '../../../../core/utils/launcher.dart';
import '../../../../core/widgets/widgets.dart';
import '../domain/announcement.dart';
import 'announcement_card.dart';
import 'announcement_providers.dart';

/// Shared by students and admins. Admins get an edit button via [onEdit].
class AnnouncementDetailScreen extends ConsumerWidget {
  const AnnouncementDetailScreen({super.key, required this.id, this.onEdit});

  final int id;
  final void Function(Announcement announcement)? onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(announcementProvider(id));
    final surface = context.colors.surface;
    return Scaffold(
      backgroundColor: surface,
      appBar: AppTopBar(
        showBack: true,
        backgroundColor: surface,
        actions: [
          if (onEdit != null && value.hasValue)
            AppIconButton(icon: Icons.edit_outlined, tooltip: 'Edit announcement', onPressed: () => onEdit!(value.requireValue)),
        ],
      ),
      body: AsyncValueView(
        value: value,
        onRetry: () => ref.invalidate(announcementProvider(id)),
        data: (a) => _Body(announcement: a),
      ),
      bottomNavigationBar: value.value?.linkUrl == null
          ? null
          : BottomActionBar(children: [
              AppButton(
                label: 'Open link',
                icon: Icons.open_in_new_rounded,
                onPressed: () => Launcher.openLink(value.value!.linkUrl!),
              ),
            ]),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.announcement});

  final Announcement announcement;

  @override
  Widget build(BuildContext context) {
    final a = announcement;
    final t = context.text;
    final p = context.colors;
    Widget dateTile(String label, DateTime date) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(color: p.background, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Text(label, style: t.caption), Text(AppDates.weekdayDayMonth(date), style: t.label)],
            ),
          ),
        );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (a.isImportant) const StatusBadge(label: 'Important', tone: Tone.accent, showDot: false),
            StatusBadge(label: '${a.type.label} announcement', tone: Tone.primary, showDot: false),
            // Students only ever see live ones; admins see why others are not shown
            if (a.visibility() != AnnouncementVisibility.live) AnnouncementVisibilityBadge(announcement: a),
          ],
        ),
        const SizedBox(height: 16),
        Text(a.title, style: t.display),
        const SizedBox(height: 20),
        Row(children: [dateTile('Starts', a.startDate), const SizedBox(width: 10), dateTile('Ends', a.endDate)]),
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 20),
        Text(a.description, style: t.body.copyWith(fontSize: 16, height: 1.65)),
      ],
    );
  }
}
