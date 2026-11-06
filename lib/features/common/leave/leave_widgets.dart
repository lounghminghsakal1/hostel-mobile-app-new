import 'package:flutter/material.dart';

import '../../../core/utils/app_dates.dart';
import '../../../core/widgets/widgets.dart';
import 'leave_application.dart';

/// Small calendar tile: month on top, day range below.
class LeaveDateTile extends StatelessWidget {
  const LeaveDateTile({super.key, required this.leave, this.size = 54});

  final LeaveApplication leave;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.colors;
    final (bg, fg) = switch (leave.status) {
      LeaveStatus.pending => (p.warningSoft, p.warningInk),
      LeaveStatus.rejected => (p.dangerSoft, p.dangerInk),
      LeaveStatus.cancelled => (p.neutralSoft, p.inkSoft),
      LeaveStatus.approved => (p.primarySoft, p.primaryDeep),
    };
    final from = leave.fromDate;
    final to = leave.toDate;
    final days = from.month == to.month
        ? (from.day == to.day ? '${from.day}' : '${from.day}–${to.day}')
        : '${from.day}+';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(15)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            AppDates.shortMonth(from),
            style: AppTextStyles.bodyFont(TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: fg)),
          ),
          FittedBox(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(days, style: context.text.number.copyWith(fontSize: 17, color: fg)),
            ),
          ),
        ],
      ),
    );
  }
}

class LeaveStatusBadge extends StatelessWidget {
  const LeaveStatusBadge({super.key, required this.status, this.long = false});

  final LeaveStatus status;

  /// "Waiting for approval" instead of "Pending".
  final bool long;

  @override
  Widget build(BuildContext context) => StatusBadge(
        label: long && status == LeaveStatus.pending ? 'Waiting for approval' : status.label,
        tone: status.tone,
      );
}
