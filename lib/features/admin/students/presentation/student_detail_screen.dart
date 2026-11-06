import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/models/account_status.dart';
import '../../../../core/utils/app_dates.dart';
import '../../../../core/utils/launcher.dart';
import '../../../../core/utils/text_utils.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../common/media/presentation/signed_image.dart';
import '../../../common/students/student_profile.dart';
import '../../attendance/presentation/attendance_report_providers.dart';
import '../../rooms/presentation/room_providers.dart';
import 'admin_student_providers.dart';

class StudentDetailScreen extends ConsumerWidget {
  const StudentDetailScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(adminStudentProvider(id));
    return Scaffold(
      appBar: AppTopBar(
        title: 'Student',
        showBack: true,
        actions: [
          if (value.hasValue)
            AppIconButton(icon: Icons.edit_outlined, tooltip: 'Edit profile', onPressed: () => context.push(Routes.editStudent(id))),
        ],
      ),
      body: AsyncValueView(
        value: value,
        onRetry: () => ref.invalidate(adminStudentProvider(id)),
        data: (s) => _Body(student: s),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.student});

  final StudentProfile student;

  Future<void> _changeRoom(BuildContext context, WidgetRef ref) async {
    final rooms = await ref.read(allRoomsProvider.future);
    if (!context.mounted) return;
    final picked = await showAppSheet<int>(
      context,
      builder: (sheetContext) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Move ${student.name.firstName} to', style: sheetContext.text.title.copyWith(fontSize: 22)),
          const SizedBox(height: 6),
          Text('Full rooms are greyed out.', style: sheetContext.text.small),
          const SizedBox(height: 14),
          for (final r in rooms)
            ListTile(
              enabled: !r.isFull && r.id != student.roomId,
              leading: const Icon(Icons.bed_outlined),
              title: Text('Room ${r.number}'),
              subtitle: Text(r.isFull ? 'Full' : '${r.free} of ${r.capacity} beds free'),
              trailing: r.id == student.roomId ? const StatusBadge(label: 'Current', tone: Tone.primary, showDot: false) : null,
              onTap: () => Navigator.of(sheetContext).pop(r.id),
            ),
        ],
      ),
    );
    if (picked == null || !context.mounted) return;
    try {
      await ref.read(adminStudentRepositoryProvider).changeRoom(student.id, picked);
      ref
        ..invalidate(adminStudentProvider(student.id))
        ..invalidate(allRoomsProvider);
      if (context.mounted) context.showMessage('Room updated.');
    } on Object catch (e) {
      if (context.mounted) context.showError(e);
    }
  }

  Future<void> _changeStatus(BuildContext context, WidgetRef ref) async {
    final picked = await showAppSheet<AccountStatus>(
      context,
      builder: (sheetContext) {
        final t = sheetContext.text;
        Widget option(AccountStatus status, IconData icon, Tone tone, String subtitle) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                onTap: () => Navigator.of(sheetContext).pop(status),
                child: Row(children: [
                  IconTile(icon: icon, tone: tone),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [Text(status.label, style: t.label), Text(subtitle, style: t.small)],
                    ),
                  ),
                ]),
              ),
            );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Change ${student.name.firstName}'s status", style: t.title.copyWith(fontSize: 22)),
            const SizedBox(height: 6),
            Text("Inactive or suspended students are signed out and can't mark attendance or apply for leave.", style: t.small),
            const SizedBox(height: 16),
            option(AccountStatus.active, Icons.check_circle_outline_rounded, Tone.success, 'Can use the app normally'),
            option(AccountStatus.inactive, Icons.remove_circle_outline_rounded, Tone.neutral, 'Moved out or graduated'),
            option(AccountStatus.suspended, Icons.warning_amber_rounded, Tone.danger, 'Access paused for a disciplinary reason'),
          ],
        );
      },
    );
    if (picked == null || !context.mounted) return;
    if (picked != AccountStatus.active) {
      final ok = await confirmAction(
        context,
        title: 'Mark as ${picked.label.toLowerCase()}?',
        message: '${student.name.firstName} will be signed out straight away.',
        confirmLabel: 'Yes, ${picked.label.toLowerCase()}',
        destructive: true,
        icon: Icons.warning_amber_rounded,
      );
      if (!ok || !context.mounted) return;
    }
    try {
      await ref.read(adminStudentRepositoryProvider).changeStatus(student.id, picked);
      ref.invalidate(adminStudentProvider(student.id));
      if (context.mounted) context.showMessage('Status changed to ${picked.label.toLowerCase()}.');
    } on Object catch (e) {
      if (context.mounted) context.showError(e);
    }
  }

  Future<void> _resendActivation(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(adminStudentRepositoryProvider).resendActivation(student.id);
      if (context.mounted) context.showMessage('Activation link sent to ${student.email ?? 'their email'}.');
    } on Object catch (e) {
      if (context.mounted) context.showError(e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.text;
    final p = context.colors;
    final s = student;
    final statusBadge = switch (s.status) {
      AccountStatus.unknown => null,
      final status => StatusBadge(
          label: status.label,
          tone: switch (status) {
            AccountStatus.active => Tone.success,
            AccountStatus.pendingActivation => Tone.primary,
            AccountStatus.suspended => Tone.danger,
            _ => Tone.neutral,
          },
        ),
    };

    Widget quickAction(IconData icon, String label, VoidCallback onTap) => Expanded(
          child: Column(
            children: [
              AppIconButton(icon: icon, tooltip: label, style: IconButtonStyle.tonal, size: 52, onPressed: onTap),
              const SizedBox(height: 6),
              Text(label, style: t.caption.copyWith(color: p.inkSoft, fontWeight: FontWeight.w700)),
            ],
          ),
        );

    return ScreenList(
      gap: 14,
      onRefresh: () async => ref.invalidate(adminStudentProvider(s.id)),
      children: [
        AppCard(
          lifted: true,
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Row(children: [
                PersonAvatar(name: s.name, imageKey: s.imageKey, imageUrl: s.imageUrl, size: 64),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.name, style: t.heading.copyWith(fontSize: 19)),
                      Text([s.rollNumber, s.departmentName].whereType<String>().join(' · '), style: t.small),
                      if (statusBadge != null) ...[const SizedBox(height: 8), statusBadge],
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                quickAction(Icons.call_outlined, 'Call', () => Launcher.call(s.contactNumber)),
                quickAction(Icons.family_restroom_outlined, 'Parent', () => Launcher.call(s.parentMobileNumber)),
                quickAction(Icons.bed_outlined, 'Room', () => _changeRoom(context, ref)),
                quickAction(Icons.event_note_outlined, 'Leaves', () => context.go('${Routes.adminLeaves}?roll=${Uri.encodeComponent(s.rollNumber)}')),
              ]),
            ],
          ),
        ),
        if (s.status == AccountStatus.pendingActivation)
          InfoCallout(
            message: "Not activated yet. They need the emailed link to set a password.",
            icon: Icons.mark_email_unread_outlined,
            action: AppButton(label: 'Resend', compact: true, onPressed: () => _resendActivation(context, ref)),
          ),
        if (s.status == AccountStatus.suspended)
          const InfoCallout(
            message: "Suspended. They can't sign in until you set them back to active.",
            tone: Tone.danger,
            icon: Icons.warning_amber_rounded,
          ),
        if (s.imageKey == null && s.imageUrl == null)
          InfoCallout(
            message: 'No reference photo yet, so attendance check-ins will fail.',
            tone: Tone.warning,
            icon: Icons.no_photography_outlined,
            action: AppButton(
              label: 'Add',
              compact: true,
              variant: ButtonVariant.light,
              onPressed: () => context.push(Routes.editStudent(s.id)),
            ),
          ),
        _LastWeek(rollNumber: s.rollNumber),
        GroupedCard(children: [
          InfoRow(icon: Icons.bed_outlined, label: 'Room', value: s.roomNumber ?? 'Not assigned', onTap: () => _changeRoom(context, ref)),
          InfoRow(icon: Icons.call_outlined, label: 'Phone · Parent', value: '${s.contactNumber.asPhone} · ${s.parentMobileNumber.asPhone}'),
          InfoRow(icon: Icons.mail_outline_rounded, label: 'Email', value: s.email ?? '—'),
        ]),
        GroupedCard(children: [
          ListTile(
            minTileHeight: 60,
            leading: const IconTile(icon: Icons.forward_to_inbox_outlined),
            title: Text('Resend activation email', style: t.label),
            subtitle: Text("Only needed if they haven't set a password yet", style: t.small),
            onTap: () => _resendActivation(context, ref),
          ),
          ListTile(
            minTileHeight: 60,
            leading: const IconTile(icon: Icons.manage_accounts_outlined, tone: Tone.danger),
            title: Text('Change status', style: t.label.copyWith(color: p.dangerInk)),
            subtitle: Text('Active, inactive or suspended', style: t.small),
            onTap: () => _changeStatus(context, ref),
          ),
        ]),
      ],
    );
  }
}

class _LastWeek extends ConsumerWidget {
  const _LastWeek({required this.rollNumber});

  final String rollNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.text;
    final p = context.colors;
    final presence = ref.watch(lastWeekPresenceProvider(rollNumber));
    final today = AppDates.todayIst();
    final days = [for (var i = 6; i >= 0; i--) today.subtract(Duration(days: i))];
    final present = presence.value ?? const <DateTime>{};

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text('LAST 7 NIGHTS', style: t.overline)),
            if (presence.hasValue) Text('${present.length} of 7 present', style: t.caption.copyWith(color: p.successInk)),
          ]),
          const SizedBox(height: 12),
          if (presence.isLoading)
            const LinearProgressIndicator(minHeight: 2)
          else
            Row(
              children: [
                for (final day in days) ...[
                  if (day != days.first) const SizedBox(width: 6),
                  Expanded(
                    child: Column(children: [
                      Text(AppDates.weekdayShort(day), style: t.caption.copyWith(fontSize: 11)),
                      const SizedBox(height: 4),
                      Builder(builder: (context) {
                        final isPresent = present.any((d) => AppDates.isSameDay(d, day));
                        return Semantics(
                          label: '${AppDates.weekdayDayMonth(day)}: ${isPresent ? 'present' : 'absent'}',
                          child: Container(
                            height: 34,
                            decoration: BoxDecoration(
                              color: isPresent ? p.successSoft : p.accentSoft,
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Icon(
                              isPresent ? Icons.check_rounded : Icons.close_rounded,
                              size: 18,
                              color: isPresent ? p.successInk : p.accentInk,
                            ),
                          ),
                        );
                      }),
                    ]),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}
