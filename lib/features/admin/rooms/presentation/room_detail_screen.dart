import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/utils/text_utils.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../common/media/presentation/signed_image.dart';
import '../domain/room.dart';
import 'room_providers.dart';
import 'widgets/room_form_sheet.dart';

class RoomDetailScreen extends ConsumerWidget {
  const RoomDetailScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(roomDetailProvider(id));
    final detail = value.value;
    return Scaffold(
      appBar: AppTopBar(
        title: detail == null ? 'Room' : 'Room ${detail.room.number}',
        showBack: true,
        actions: [
          if (detail != null)
            AppIconButton(
              icon: Icons.edit_outlined,
              tooltip: 'Edit room',
              onPressed: () async {
                final saved = await showRoomFormSheet(context, existing: detail.room);
                if (saved != null) {
                  ref.invalidate(roomDetailProvider(id));
                  ref.invalidate(allRoomsProvider);
                }
              },
            ),
        ],
      ),
      body: AsyncValueView(
        value: value,
        onRetry: () => ref.invalidate(roomDetailProvider(id)),
        data: (d) => _Body(detail: d),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.detail});

  final RoomDetail detail;

  @override
  Widget build(BuildContext context) {
    final p = context.colors;
    final t = context.text;
    final room = detail.room;
    final occupants = detail.occupants;

    Widget bed(int index) {
      final taken = index < occupants.length;
      return Expanded(
        child: Container(
          height: 86,
          decoration: BoxDecoration(
            color: taken ? p.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: taken ? null : Border.all(color: p.onPrimary.withValues(alpha: 0.6), width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (taken) InitialsAvatar(name: occupants[index].name, size: 36) else Icon(Icons.add_rounded, color: p.onPrimary),
              const SizedBox(height: 6),
              Text(
                taken ? 'Bed ${index + 1}' : 'Free',
                style: t.caption.copyWith(color: taken ? p.primaryDeep : p.onPrimary, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      );
    }

    return ScreenList(
      gap: 18,
      children: [
        HeroPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('OCCUPANCY', style: t.overline.copyWith(color: p.onPrimaryMuted)),
                        Text.rich(
                          TextSpan(children: [
                            TextSpan(text: '${room.occupied}'),
                            TextSpan(text: '/${room.capacity}', style: t.number.copyWith(fontSize: 26, color: p.onPrimaryMuted)),
                          ]),
                          style: t.number.copyWith(fontSize: 44, color: p.onPrimary),
                        ),
                      ],
                    ),
                  ),
                  GlassChip(child: Text(room.isFull ? 'Full' : '${room.free} bed${room.free == 1 ? '' : 's'} free')),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  for (var i = 0; i < room.capacity.clamp(1, 6); i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    bed(i),
                  ],
                ],
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionHeader(title: 'Students in this room'),
            const SizedBox(height: 10),
            if (occupants.isEmpty)
              const EmptyView(icon: Icons.bed_outlined, title: 'Nobody here yet', message: 'Assign a student from their profile.')
            else
              GroupedCard(children: [
                for (final o in occupants)
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: PersonAvatar(name: o.name, imageKey: o.imageKey),
                    title: Text(o.name, style: t.label),
                    subtitle: Text(
                      [o.rollNumber, o.departmentName, o.contactNumber?.asPhone].whereType<String>().join(' · '),
                      style: t.small,
                    ),
                    trailing: o.studentId == null ? null : Icon(Icons.chevron_right_rounded, color: p.subtle),
                    onTap: o.studentId == null ? null : () => context.push(Routes.student(o.studentId!)),
                  ),
              ]),
          ],
        ),
        if (!room.isFull)
          AppButton(
            label: 'Assign a student to a free bed',
            icon: Icons.add_rounded,
            variant: ButtonVariant.outline,
            expand: true,
            onPressed: () => context.go(Routes.students),
          ),
      ],
    );
  }
}
