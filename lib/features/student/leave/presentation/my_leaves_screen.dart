import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/utils/app_dates.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../common/leave/leave_application.dart';
import '../../../common/leave/leave_widgets.dart';
import 'student_leave_providers.dart';

class MyLeavesScreen extends ConsumerStatefulWidget {
  const MyLeavesScreen({super.key});

  @override
  ConsumerState<MyLeavesScreen> createState() => _MyLeavesScreenState();
}

class _MyLeavesScreenState extends ConsumerState<MyLeavesScreen> {
  LeaveStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final leaves = ref.watch(myLeavesProvider);
    return Scaffold(
      appBar: const AppTopBar(title: 'Leave', subtitle: 'Plan trips home without the paperwork'),
      body: AsyncValueView(
        value: leaves,
        onRetry: () => ref.invalidate(myLeavesProvider),
        data: (all) {
          final pending = all.where((l) => l.isPending).firstOrNull;
          final history = all.where((l) => !l.isPending && (_filter == null || l.status == _filter)).toList();
          final pastCount = all.where((l) => !l.isPending).length;

          return ScreenList(
            gap: 18,
            onRefresh: () async {
              ref.invalidate(myLeavesProvider);
              await ref.read(myLeavesProvider.future);
            },
            children: [
              if (pending != null) _PendingCard(leave: pending) else const _ApplyHero(),
              if (pending != null)
                const InfoCallout(message: 'One request at a time. Edit or cancel this one to ask for different dates.'),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionHeader(title: 'History'),
                  const SizedBox(height: 10),
                  FilterChipBar<LeaveStatus?>(
                    selected: _filter,
                    onSelected: (v) => setState(() => _filter = v),
                    options: [
                      FilterOption(null, 'All', count: pastCount),
                      const FilterOption(LeaveStatus.approved, 'Approved'),
                      const FilterOption(LeaveStatus.rejected, 'Rejected'),
                      const FilterOption(LeaveStatus.cancelled, 'Cancelled'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (history.isEmpty)
                    const EmptyView(
                      icon: Icons.event_available_outlined,
                      title: 'No past requests',
                      message: 'Requests you make will be listed here.',
                    )
                  else
                    GroupedCard(children: [for (final leave in history) _HistoryRow(leave: leave)]),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PendingCard extends StatelessWidget {
  const _PendingCard({required this.leave});

  final LeaveApplication leave;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final submitted = leave.createdAt == null ? '' : ' · Sent ${AppDates.dayMonth(AppDates.ist(leave.createdAt!))}';
    return AppCard(
      lifted: true,
      borderColor: const Color(0xFFFBE3B0),
      padding: const EdgeInsets.all(18),
      onTap: () => context.push(Routes.leaveDetail(leave.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text('CURRENT REQUEST', style: t.overline)),
            LeaveStatusBadge(status: leave.status, long: true),
          ]),
          const SizedBox(height: 14),
          Row(
            children: [
              LeaveDateTile(leave: leave),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(leave.reason, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.heading),
                    Text('${AppDates.dayCount(leave.days)}$submitted', style: t.small),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: context.colors.subtle),
            ],
          ),
        ],
      ),
    );
  }
}

class _ApplyHero extends StatelessWidget {
  const _ApplyHero();

  @override
  Widget build(BuildContext context) {
    final p = context.colors;
    return HeroPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Going home soon?', style: context.text.title.copyWith(color: p.onPrimary)),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 250),
            child: Text(
              'Send a request and your warden gets it instantly.',
              style: context.text.body.copyWith(color: p.onPrimaryMuted, fontSize: 14),
            ),
          ),
          const SizedBox(height: 14),
          AppButton(
            label: 'Apply for leave',
            icon: Icons.add_rounded,
            variant: ButtonVariant.accent,
            onPressed: () => context.push(Routes.applyLeave),
          ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.leave});

  final LeaveApplication leave;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final p = context.colors;
    return InkWell(
      onTap: () => context.push(Routes.leaveDetail(leave.id)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LeaveDateTile(leave: leave),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(leave.reason, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.label),
                  Text(AppDates.dayCount(leave.days), style: t.small),
                  if (leave.status == LeaveStatus.rejected && leave.rejectionReason != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(color: p.dangerSoft, borderRadius: BorderRadius.circular(10)),
                      child: Text('"${leave.rejectionReason}"', style: t.caption.copyWith(color: p.dangerInk, fontSize: 12.5)),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            LeaveStatusBadge(status: leave.status),
          ],
        ),
      ),
    );
  }
}
