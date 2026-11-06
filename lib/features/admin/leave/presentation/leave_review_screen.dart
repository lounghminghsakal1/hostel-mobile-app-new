import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/utils/app_dates.dart';
import '../../../../core/utils/launcher.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../common/leave/leave_application.dart';
import '../../../common/leave/leave_widgets.dart';
import '../../../common/media/presentation/signed_image.dart';
import '../domain/admin_leave.dart';
import 'admin_leave_providers.dart';

/// Approve or reject a request. Pops with `true` when something changed.
class LeaveReviewScreen extends ConsumerStatefulWidget {
  const LeaveReviewScreen({super.key, required this.id});

  final int id;

  @override
  ConsumerState<LeaveReviewScreen> createState() => _LeaveReviewScreenState();
}

class _LeaveReviewScreenState extends ConsumerState<LeaveReviewScreen> {
  bool _busy = false;

  Future<void> _approve() async {
    setState(() => _busy = true);
    try {
      await ref.read(reviewLeaveProvider).approve(widget.id);
      if (!mounted) return;
      context.showMessage('Approved. The student has been told.');
      context.pop(true);
    } on Object catch (e) {
      if (mounted) context.showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reject() async {
    final rejected = await showAppSheet<bool>(context, builder: (_) => _RejectSheet(id: widget.id));
    if (rejected == true && mounted) {
      context.showMessage('Rejected. The student can see your note.');
      context.pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(leaveReviewProvider(widget.id));
    final pending = value.value?.leave.isPending ?? false;
    return Scaffold(
      appBar: const AppTopBar(title: 'Review leave', showBack: true),
      bottomNavigationBar: !pending
          ? null
          : BottomActionBar(children: [
              AppButton(label: 'Reject', variant: ButtonVariant.danger, onPressed: _busy ? null : _reject),
              AppButton(label: 'Approve', icon: Icons.check_rounded, variant: ButtonVariant.success, loading: _busy, onPressed: _approve),
            ]),
      body: AsyncValueView(
        value: value,
        onRetry: () => ref.invalidate(leaveReviewProvider(widget.id)),
        data: (detail) => _Body(detail: detail),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.detail});

  final LeaveReviewDetail detail;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final leave = detail.leave;
    final student = leave.student;
    final title = AppDates.isSameDay(leave.fromDate, leave.toDate)
        ? AppDates.weekdayDayMonth(leave.fromDate)
        : '${AppDates.weekdayShort(leave.fromDate)} ${leave.fromDate.day} – ${AppDates.weekdayShort(leave.toDate)} ${AppDates.dayMonth(leave.toDate)}';

    return ScreenList(
      gap: 14,
      children: [
        AppCard(
          child: Row(children: [
            PersonAvatar(name: student?.name ?? 'Student', imageKey: student?.imageKey, size: 56),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(student?.name ?? 'Student #${leave.studentId}', style: t.heading),
                  if (student != null && student.subtitle.isNotEmpty) Text(student.subtitle, style: t.small),
                ],
              ),
            ),
            if (student?.contactNumber != null)
              AppIconButton(icon: Icons.call_outlined, tooltip: 'Call student', onPressed: () => Launcher.call(student!.contactNumber!)),
          ]),
        ),
        AppCard(
          lifted: true,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [Expanded(child: Text('REQUESTED DATES', style: t.overline)), LeaveStatusBadge(status: leave.status)]),
              const SizedBox(height: 10),
              Text(title, style: t.display.copyWith(fontSize: 26)),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 6, children: [
                StatusBadge(label: AppDates.dayCount(leave.days), tone: Tone.primary, showDot: false),
                if (leave.createdAt != null)
                  StatusBadge(
                    label: 'Sent ${AppDates.dayMonth(AppDates.ist(leave.createdAt!))}, ${AppDates.time(leave.createdAt!)}',
                    tone: Tone.neutral,
                    showDot: false,
                  ),
              ]),
              const SizedBox(height: 14),
              const Divider(),
              const SizedBox(height: 14),
              Text(leave.reason, style: t.body.copyWith(color: context.colors.ink)),
            ],
          ),
        ),
        if (leave.status == LeaveStatus.approved)
          const InfoCallout(message: 'You approved this request.', tone: Tone.success, icon: Icons.check_rounded),
        if (leave.status == LeaveStatus.rejected)
          InfoCallout(
            title: 'Your note:',
            message: leave.rejectionReason == null ? '—' : '"${leave.rejectionReason}"',
            tone: Tone.danger,
            icon: Icons.campaign_outlined,
          ),
        if (leave.status == LeaveStatus.cancelled)
          const InfoCallout(message: 'The student cancelled this request.', tone: Tone.neutral),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('LEAVES IN THE LAST 2 MONTHS', style: t.overline),
            const SizedBox(height: 8),
            if (detail.recent.isEmpty)
              AppCard(child: Text('No other leave in the last two months.', style: t.small))
            else
              GroupedCard(children: [
                for (final l in detail.recent)
                  ListTile(
                    leading: LeaveDateTile(leave: l, size: 44),
                    title: Text(l.reason, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.label.copyWith(fontSize: 14)),
                    subtitle: Text(l.rangeLabel, style: t.small),
                    trailing: LeaveStatusBadge(status: l.status),
                  ),
              ]),
          ],
        ),
      ],
    );
  }
}

class _RejectSheet extends ConsumerStatefulWidget {
  const _RejectSheet({required this.id});

  final int id;

  @override
  ConsumerState<_RejectSheet> createState() => _RejectSheetState();
}

class _RejectSheetState extends ConsumerState<_RejectSheet> {
  final _reason = TextEditingController();
  bool _busy = false;
  String? _error;

  static const _quickReasons = ['Exams that week', 'Too many days', "Need a parent's call first"];

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(reviewLeaveProvider).reject(widget.id, _reason.text);
      if (mounted) Navigator.of(context).pop(true);
    } on Object catch (e) {
      if (mounted) setState(() => _error = toAppException(e).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Why are you rejecting it?', style: t.title.copyWith(fontSize: 22)),
        const SizedBox(height: 6),
        Text('The student will see this note, so keep it kind and clear.', style: t.small),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final r in _quickReasons)
              ActionChip(label: Text(r), onPressed: () => setState(() => _reason.text = r)),
          ],
        ),
        const SizedBox(height: 14),
        AppTextField(label: 'Reason', controller: _reason, maxLines: 4, minLines: 3, errorText: _error),
        const SizedBox(height: 18),
        Row(children: [
          Expanded(child: AppButton(label: 'Back', variant: ButtonVariant.outline, onPressed: () => Navigator.of(context).pop(false))),
          const SizedBox(width: 12),
          Expanded(flex: 3, child: AppButton(label: 'Reject request', variant: ButtonVariant.dangerSolid, loading: _busy, onPressed: _submit)),
        ]),
      ],
    );
  }
}
