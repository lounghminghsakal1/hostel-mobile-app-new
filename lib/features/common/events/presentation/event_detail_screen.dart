import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/app_dates.dart';
import '../../../../core/utils/launcher.dart';
import '../../../../core/utils/text_utils.dart';
import '../../../../core/widgets/widgets.dart';
import '../domain/hostel_event.dart';
import 'event_providers.dart';
import 'event_widgets.dart';

/// Shared by students and admins. Admins get an edit button via [onEdit].
class EventDetailScreen extends ConsumerWidget {
  const EventDetailScreen({super.key, required this.id, this.onEdit});

  final int id;
  final void Function(HostelEvent event)? onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(eventProvider(id));
    final event = value.value;
    return Scaffold(
      backgroundColor: context.colors.surface,
      body: AsyncValueView(
        value: value,
        onRetry: () => ref.invalidate(eventProvider(id)),
        data: (e) => _Body(event: e, onEdit: onEdit),
      ),
      bottomNavigationBar: event?.link == null
          ? null
          : BottomActionBar(children: [
              AppButton(
                label: 'Register on event page',
                icon: Icons.open_in_new_rounded,
                variant: ButtonVariant.accent,
                onPressed: () => Launcher.openLink(event!.link!),
              ),
            ]),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.event, this.onEdit});

  final HostelEvent event;
  final void Function(HostelEvent event)? onEdit;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final p = context.colors;
    final e = event;
    final relative = AppDates.daysFromNow(AppDates.ist(e.startingAt));

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Stack(
            children: [
              EventCover(event: e, height: 290, showDate: false),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      AppIconButton(icon: Icons.arrow_back_rounded, tooltip: 'Back', onPressed: () => context.pop()),
                      const Spacer(),
                      if (onEdit != null)
                        AppIconButton(icon: Icons.edit_outlined, tooltip: 'Edit event', onPressed: () => onEdit!(e)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SliverToBoxAdapter(
          child: Transform.translate(
            offset: const Offset(0, -28),
            child: Container(
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(spacing: 8, children: [
                    if (e.isOngoing) const StatusBadge(label: 'Happening now', tone: Tone.success),
                    if (!e.isOngoing && relative != null) StatusBadge(label: relative, tone: Tone.accent),
                    if (!e.isActive) const StatusBadge(label: 'Hidden from students', tone: Tone.neutral),
                    if (e.isActive && e.hasEnded) const StatusBadge(label: 'Ended', tone: Tone.neutral),
                  ]),
                  const SizedBox(height: 10),
                  Text(e.name, style: t.display.copyWith(fontSize: 28)),
                  const SizedBox(height: 18),
                  GroupedCard(children: [
                    InfoRow(
                      icon: Icons.calendar_today_rounded,
                      tone: Tone.accent,
                      label: 'Starts ${AppDates.time(e.startingAt)} · Ends ${AppDates.time(e.endingAt)}',
                      value: AppDates.fullDate(AppDates.ist(e.startingAt)),
                    ),
                    if (e.contactName != null || e.contactPhone != null)
                      InfoRow(
                        icon: Icons.person_outline_rounded,
                        label: e.contactPhone == null ? 'Organiser' : 'Organiser · ${e.contactPhone!.asPhone}',
                        value: e.contactName ?? 'Contact',
                        trailing: e.contactPhone == null
                            ? null
                            : AppButton(
                                label: 'Call',
                                icon: Icons.call_outlined,
                                variant: ButtonVariant.tonal,
                                compact: true,
                                onPressed: () => Launcher.call(e.contactPhone!),
                              ),
                      ),
                  ]),
                  const SizedBox(height: 20),
                  Text('ABOUT', style: t.overline),
                  const SizedBox(height: 8),
                  Text(e.description, style: t.body),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
