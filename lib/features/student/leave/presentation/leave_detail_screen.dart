import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/utils/app_dates.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../common/leave/leave_application.dart';
import '../../../common/leave/leave_widgets.dart';
import 'student_leave_providers.dart';

class LeaveDetailScreen extends ConsumerStatefulWidget {
  const LeaveDetailScreen({super.key, required this.id});

  final int id;

  @override
  ConsumerState<LeaveDetailScreen> createState() => _LeaveDetailScreenState();
}

class _LeaveDetailScreenState extends ConsumerState<LeaveDetailScreen> {
  bool _cancelling = false;

  Future<void> _cancel() async {
    final ok = await confirmAction(
      context,
      title: 'Cancel this request?',
      message: "Your warden won't see it anymore. You can apply again for any dates afterwards.",
      confirmLabel: 'Yes, cancel',
      cancelLabel: 'Keep it',
      icon: Icons.event_busy_outlined,
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _cancelling = true);
    try {
      await ref.read(cancelLeaveRequestProvider)(widget.id);
      ref.invalidate(myLeavesProvider);
      if (!mounted) return;
      context.showMessage('Request cancelled.');
      context.pop();
    } on Object catch (e) {
      if (mounted) context.showError(e);
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(myLeaveProvider(widget.id));
    final leave = value.value;
    return Scaffold(
      appBar: const AppTopBar(title: 'Leave request', showBack: true),
      bottomNavigationBar: leave == null || !leave.isPending
          ? null
          : BottomActionBar(children: [
              AppButton(label: 'Cancel request', variant: ButtonVariant.danger, loading: _cancelling, onPressed: _cancel),
              AppButton(
                label: 'Edit',
                icon: Icons.edit_outlined,
                onPressed: () => context.push(Routes.editLeave(widget.id)),
              ),
            ]),
      body: AsyncValueView(
        value: value,
        onRetry: () => ref.invalidate(myLeaveProvider(widget.id)),
        data: (l) => _Body(leave: l),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.leave});

  final LeaveApplication leave;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final from = leave.fromDate;
    final to = leave.toDate;
    final title = AppDates.isSameDay(from, to)
        ? AppDates.dayMonthYear(from)
        : '${AppDates.dayMonth(from)} – ${AppDates.dayMonthYear(to)}';

    return ScreenList(
      gap: 16,
      children: [
        AppCard(
          lifted: true,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LeaveStatusBadge(status: leave.status, long: true),
              const SizedBox(height: 12),
              Text(title, style: t.display.copyWith(fontSize: 28)),
              const SizedBox(height: 12),
              Wrap(spacing: 8, children: [
                StatusBadge(label: AppDates.dayCount(leave.days), tone: Tone.primary, showDot: false),
                StatusBadge(
                  label: '${AppDates.weekdayShort(from)} → ${AppDates.weekdayShort(to)}',
                  tone: Tone.neutral,
                  showDot: false,
                ),
              ]),
            ],
          ),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('REASON', style: t.overline),
              const SizedBox(height: 8),
              Text(leave.reason, style: t.body.copyWith(color: context.colors.ink)),
            ],
          ),
        ),
        if (leave.status == LeaveStatus.rejected)
          InfoCallout(
            title: "Warden's note:",
            message: leave.rejectionReason == null ? 'No reason given.' : '"${leave.rejectionReason}"',
            tone: Tone.danger,
            icon: Icons.campaign_outlined,
          ),
        if (leave.status == LeaveStatus.approved)
          const InfoCallout(
            title: 'Have a safe trip!',
            message: "You won't need to mark attendance on these days.",
            tone: Tone.success,
            icon: Icons.check_rounded,
          ),
        _Timeline(leave: leave),
      ],
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.leave});

  final LeaveApplication leave;

  @override
  Widget build(BuildContext context) {
    final p = context.colors;
    final t = context.text;
    String when(DateTime? moment) =>
        moment == null ? '' : '${AppDates.weekdayDayMonth(AppDates.ist(moment))} · ${AppDates.time(moment)}';

    final (title, subtitle, icon, bg, fg) = switch (leave.status) {
      LeaveStatus.pending => ('Waiting for your warden', 'Usually answered within a day', Icons.schedule_rounded, p.warningSoft, p.warningInk),
      LeaveStatus.approved => ('Approved by your warden', when(leave.reviewedAt), Icons.check_rounded, p.success, p.onSuccess),
      LeaveStatus.rejected => ('Rejected by your warden', when(leave.reviewedAt), Icons.close_rounded, p.danger, p.onPrimary),
      LeaveStatus.cancelled => ('Cancelled by you', '', Icons.close_rounded, p.neutralSoft, p.inkSoft),
    };

    Widget node(IconData icon, Color bg, Color fg) => Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Icon(icon, size: 15, color: fg),
        );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TIMELINE', style: t.overline),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(children: [
                  node(Icons.send_rounded, p.primary, p.onPrimary),
                  Expanded(child: Container(width: 2, color: p.line)),
                ]),
                const SizedBox(width: 14),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [Text('Request sent', style: t.label.copyWith(fontSize: 14.5)), Text(when(leave.createdAt), style: t.small)],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              node(icon, bg, fg),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: t.label.copyWith(fontSize: 14.5)),
                    if (subtitle.isNotEmpty) Text(subtitle, style: t.small),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
