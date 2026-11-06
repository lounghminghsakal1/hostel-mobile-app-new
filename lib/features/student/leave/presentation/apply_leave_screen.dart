import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/utils/app_dates.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../common/leave/leave_application.dart';
import '../domain/student_leave.dart';
import 'student_leave_providers.dart';
import 'widgets/range_calendar.dart';

/// Apply for leave, or edit a pending request when [editingId] is set.
class ApplyLeaveScreen extends ConsumerWidget {
  const ApplyLeaveScreen({super.key, this.editingId});

  final int? editingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = editingId;
    if (id == null) return const _LeaveForm();
    final existing = ref.watch(myLeaveProvider(id));
    return existing.when(
      data: (leave) => _LeaveForm(existing: leave),
      loading: () => const Scaffold(body: LoadingView()),
      error: (e, _) => Scaffold(appBar: const AppTopBar(showBack: true), body: ErrorView(error: e)),
    );
  }
}

class _LeaveForm extends ConsumerStatefulWidget {
  const _LeaveForm({this.existing});

  final LeaveApplication? existing;

  @override
  ConsumerState<_LeaveForm> createState() => _LeaveFormState();
}

class _LeaveFormState extends ConsumerState<_LeaveForm> {
  late DateTime? _start = widget.existing?.fromDate;
  late DateTime? _end = widget.existing?.toDate;
  late final _reason = TextEditingController(text: widget.existing?.reason);
  bool _saving = false;
  AppException? _error;

  bool get _editing => widget.existing != null;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final start = _start;
    if (start == null) {
      setState(() => _error = const AppException('Pick the days you will be away.'));
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(submitLeaveRequestProvider)(
        LeaveRequest(fromDate: start, toDate: _end ?? start, reason: _reason.text),
        editingId: widget.existing?.id,
      );
      ref.invalidate(myLeavesProvider);
      if (_editing) ref.invalidate(myLeaveProvider(widget.existing!.id));
      if (!mounted) return;
      context.showMessage(_editing ? 'Changes saved.' : 'Request sent. Your warden has been notified.');
      context.pop();
    } on Object catch (e) {
      if (mounted) setState(() => _error = toAppException(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.colors;
    final t = context.text;
    final start = _start;
    final end = _end ?? _start;
    final days = start == null ? 0 : AppDates.daysInclusive(start, end!);

    Widget dateBox(String label, DateTime? date) => Expanded(
          child: AppCard(
            radius: 16,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: t.caption),
                Text(date == null ? 'Pick a day' : AppDates.weekdayDayMonth(date), style: t.label),
              ],
            ),
          ),
        );

    return Scaffold(
      appBar: AppTopBar(title: _editing ? 'Edit request' : 'Apply for leave', showBack: true),
      bottomNavigationBar: BottomActionBar(children: [
        AppButton(
          label: _editing ? 'Save changes' : 'Send request',
          icon: _editing ? null : Icons.send_rounded,
          loading: _saving,
          onPressed: _submit,
        ),
      ]),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          RangeCalendar(
            start: _start,
            end: _end,
            firstDay: AppDates.todayIst(),
            onChanged: (s, e) => setState(() {
              _start = s;
              _end = e;
              _error = null;
            }),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              dateBox('From', start),
              const SizedBox(width: 10),
              dateBox('To', end),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(color: p.primary, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    Text('Days', style: t.caption.copyWith(color: p.onPrimaryMuted)),
                    Text('$days', style: t.number.copyWith(fontSize: 18, color: p.onPrimary)),
                  ],
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            InfoCallout(message: _error!.message, tone: Tone.danger, icon: Icons.error_outline_rounded),
          ],
          const SizedBox(height: 18),
          AppTextField(
            label: 'Reason',
            controller: _reason,
            hint: 'Where are you going, and who is picking you up?',
            maxLines: 4,
            minLines: 3,
            maxLength: 500,
            helperText: 'Your warden sees this',
          ),
        ],
      ),
    );
  }
}
