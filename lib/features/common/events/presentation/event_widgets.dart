import 'package:flutter/material.dart';

import '../../../../core/utils/app_dates.dart';
import '../../../../core/widgets/widgets.dart';
import '../../media/presentation/signed_image.dart';
import '../domain/hostel_event.dart';

/// Event image, or a dotted colour block when there is none.
class EventCover extends StatelessWidget {
  const EventCover({super.key, required this.event, required this.height, this.showDate = true, this.trailing});

  final HostelEvent event;
  final double height;
  final bool showDate;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = context.colors;
    final color = [p.accent, p.primary, p.success][event.id % 3];
    final fallback = DottedCover(color: color, height: height);
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          SignedImage(objectKey: event.imageKey, placeholder: fallback),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showDate) DateBox(date: AppDates.ist(event.startingAt)),
                const Spacer(),
                ?trailing,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EventCard extends StatelessWidget {
  const EventCard({super.key, required this.event, required this.onTap, this.width, this.coverHeight = 128, this.showStatus = false});

  final HostelEvent event;
  final VoidCallback onTap;
  final double? width;
  final double coverHeight;
  final bool showStatus;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final p = context.colors;
    Widget? badge;
    if (showStatus && !event.isActive) {
      badge = const StatusBadge(label: 'Hidden', tone: Tone.neutral);
    } else if (event.isOngoing) {
      badge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: p.ink, borderRadius: BorderRadius.circular(999)),
        child: Text('Ongoing', style: t.caption.copyWith(color: p.surface, fontWeight: FontWeight.w700)),
      );
    }

    return SizedBox(
      width: width,
      child: AppCard(
        padding: EdgeInsets.zero,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EventCover(event: event, height: coverHeight, trailing: badge),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.label),
                  const SizedBox(height: 2),
                  Text(
                    AppDates.eventWhen(event.startingAt, event.endingAt),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.small,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
