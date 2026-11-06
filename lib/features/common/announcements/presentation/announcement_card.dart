import 'package:flutter/material.dart';

import '../../../../core/utils/app_dates.dart';
import '../../../../core/widgets/widgets.dart';
import '../domain/announcement.dart';

class AnnouncementCard extends StatelessWidget {
  const AnnouncementCard({super.key, required this.announcement, required this.onTap, this.compact = false, this.showStatus = false});

  final Announcement announcement;
  final VoidCallback onTap;

  /// Home-screen style: icon tile and one-line preview.
  final bool compact;

  /// Admin lists show Active / Inactive.
  final bool showStatus;

  @override
  Widget build(BuildContext context) {
    final p = context.colors;
    final t = context.text;
    final a = announcement;
    final tags = Row(
      children: [
        if (a.isImportant) ...[
          const StatusBadge(label: 'Important', tone: Tone.accent, showDot: false, small: true),
          const SizedBox(width: 6),
        ],
        StatusBadge(
          label: a.type.label,
          tone: a.type == AnnouncementType.hostel ? Tone.primary : Tone.neutral,
          showDot: false,
          small: true,
        ),
        const Spacer(),
        if (showStatus)
          StatusBadge(label: a.isActive ? 'Active' : 'Inactive', tone: a.isActive ? Tone.success : Tone.neutral, small: true)
        else
          Text('Till ${AppDates.dayMonth(a.endDate)}', style: t.caption),
      ],
    );

    if (compact) {
      return AppCard(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconTile(
              icon: a.type == AnnouncementType.college ? Icons.apartment_rounded : Icons.campaign_outlined,
              tone: a.isImportant ? Tone.accent : Tone.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  tags,
                  const SizedBox(height: 6),
                  Text(a.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.label),
                  const SizedBox(height: 2),
                  Text(a.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.small),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return AppCard(
      onTap: onTap,
      borderColor: a.isImportant ? p.accentSoft : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          tags,
          const SizedBox(height: 10),
          Text(a.title, style: t.heading),
          const SizedBox(height: 6),
          Text(a.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: t.small),
          if (a.linkUrl != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.open_in_new_rounded, size: 15, color: p.primary),
                const SizedBox(width: 6),
                Text('Has a link', style: t.caption.copyWith(color: p.primary, fontWeight: FontWeight.w700)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
