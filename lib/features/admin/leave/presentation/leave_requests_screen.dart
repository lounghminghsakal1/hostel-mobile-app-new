
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/utils/app_dates.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../common/leave/leave_application.dart';
import '../../../common/leave/leave_widgets.dart';
import '../../../common/media/presentation/signed_image.dart';
import '../../shell/admin_top_bar.dart';
import '../domain/admin_leave.dart';
import 'admin_leave_providers.dart';

class LeaveRequestsScreen extends ConsumerStatefulWidget {
  const LeaveRequestsScreen({super.key, this.rollNumber});

  /// Opens filtered to one student (from the student detail screen).
  final String? rollNumber;

  @override
  ConsumerState<LeaveRequestsScreen> createState() => _LeaveRequestsScreenState();
}

class _LeaveRequestsScreenState extends ConsumerState<LeaveRequestsScreen> {
  LeaveStatus? _status = LeaveStatus.pending;
  String _search = '';
  late String? _roll = widget.rollNumber;
  LeaveCounts? _counts;
  final _searchController = TextEditingController();
  int _reload = 0;

  @override
  void initState() {
    super.initState();
    if (_roll != null) _status = null;
  }

  @override
  void didUpdateWidget(LeaveRequestsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.rollNumber != oldWidget.rollNumber) {
      _roll = widget.rollNumber;
      _status = _roll == null ? LeaveStatus.pending : null;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(adminLeaveRepositoryProvider);
    final pending = _counts?.pending ?? 0;

    return Scaffold(
      appBar: AdminTopBar(
        title: 'Leave requests',
        subtitle: _counts == null ? null : (pending == 0 ? 'All caught up' : '$pending waiting for you'),
      ),
      body: PagedList<LeaveApplication>(
        query: (_status, _search, _roll, _reload),
        grouped: true,
        fetch: (page) async {
          final result = await repo.list((status: _status, search: _search.isEmpty ? null : _search, rollNumber: _roll, page: page));
          if (page == 1) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _counts = result.counts);
            });
          }
          return result.page;
        },
        header: [
          Row(
            children: [
              for (final s in LeaveStatus.values) ...[
                if (s != LeaveStatus.values.first) const SizedBox(width: 8),
                Expanded(child: _CountTile(status: s, count: _counts?.of(s), selected: _status == s, onTap: () => setState(() => _status = _status == s ? null : s))),
              ],
            ],
          ),
          if (_roll != null)
            InfoCallout(
              message: 'Showing roll number $_roll',
              icon: Icons.filter_alt_outlined,
              action: AppButton(label: 'Clear', compact: true, variant: ButtonVariant.light, onPressed: () => setState(() => _roll = null)),
            ),
          SearchField(
            controller: _searchController,
            hint: 'Student name',
            onSearch: (v) => setState(() => _search = v),
          ),
        ],
        empty: EmptyView(
          icon: Icons.task_alt_rounded,
          title: _status == LeaveStatus.pending ? 'All caught up' : 'No requests',
          message: _status == LeaveStatus.pending ? 'New leave requests will show up here.' : 'Nothing matches these filters.',
        ),
        itemBuilder: (context, leave) => _LeaveRow(
          leave: leave,
          onTap: () async {
            final changed = await context.push<bool>(Routes.leaveReview(leave.id));
            if (changed == true && mounted) setState(() => _reload++);
          },
        ),
      ),
    );
  }
}

class _CountTile extends StatelessWidget {
  const _CountTile({required this.status, required this.count, required this.selected, required this.onTap});

  final LeaveStatus status;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.colors;
    final t = context.text;
    final fg = status.tone.foreground(p);
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: status.tone.background(p),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: selected ? fg : Colors.transparent, width: 1.5),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(children: [
              Text(count == null ? '–' : '$count', style: t.number.copyWith(fontSize: 22, color: fg)),
              Text(status.label, style: t.caption.copyWith(fontSize: 11.5, color: fg, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _LeaveRow extends StatelessWidget {
  const _LeaveRow({required this.leave, required this.onTap});

  final LeaveApplication leave;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final student = leave.student;
    final startsIn = leave.isPending ? AppDates.daysFromNow(leave.fromDate) : null;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              PersonAvatar(name: student?.name ?? 'Student', imageKey: student?.imageKey),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(student?.name ?? 'Student #${leave.studentId}', maxLines: 1, overflow: TextOverflow.ellipsis, style: t.label),
                    if (student != null && student.subtitle.isNotEmpty)
                      Text(student.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.small),
                  ],
                ),
              ),
              LeaveStatusBadge(status: leave.status),
            ]),
            Padding(
              padding: const EdgeInsets.only(left: 52, top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(spacing: 8, runSpacing: 6, children: [
                    StatusBadge(label: '${leave.rangeLabel} · ${AppDates.dayCount(leave.days)}', tone: Tone.primary, showDot: false),
                    if (startsIn != null && leave.fromDate.difference(AppDates.todayIst()).inDays <= 3)
                      StatusBadge(label: 'Starts ${startsIn.toLowerCase()}', tone: Tone.accent, showDot: false),
                  ]),
                  const SizedBox(height: 6),
                  Text(leave.reason, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.small),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
