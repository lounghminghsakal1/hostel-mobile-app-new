import 'package:flutter/material.dart';

import '../../../../../core/utils/app_dates.dart';
import '../../../../../core/widgets/widgets.dart';

/// Inline month calendar for picking a date range. First tap picks the
/// start, the second picks the end; tapping before the start restarts.
class RangeCalendar extends StatefulWidget {
  const RangeCalendar({super.key, required this.start, required this.end, required this.onChanged, required this.firstDay});

  final DateTime? start;
  final DateTime? end;
  final DateTime firstDay;
  final void Function(DateTime? start, DateTime? end) onChanged;

  @override
  State<RangeCalendar> createState() => _RangeCalendarState();
}

class _RangeCalendarState extends State<RangeCalendar> {
  late DateTime _month = DateTime((widget.start ?? widget.firstDay).year, (widget.start ?? widget.firstDay).month);

  void _tap(DateTime day) {
    final start = widget.start;
    final end = widget.end;
    if (start == null || end != null || day.isBefore(start)) {
      widget.onChanged(day, null);
    } else {
      widget.onChanged(start, day);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.colors;
    final t = context.text;
    final daysInMonth = DateUtils.getDaysInMonth(_month.year, _month.month);
    final leading = DateTime(_month.year, _month.month).weekday % 7; // Sunday first
    final today = AppDates.todayIst();
    final canGoBack = _month.isAfter(DateTime(widget.firstDay.year, widget.firstDay.month));

    Widget cell(int day) {
      final date = DateTime(_month.year, _month.month, day);
      final disabled = date.isBefore(widget.firstDay);
      final start = widget.start;
      final end = widget.end ?? widget.start;
      final isStart = start != null && AppDates.isSameDay(date, start);
      final isEnd = end != null && AppDates.isSameDay(date, end);
      final inRange = start != null && end != null && !date.isBefore(start) && !date.isAfter(end);
      final isToday = AppDates.isSameDay(date, today);
      final selected = isStart || isEnd;

      final band = inRange && !(isStart && isEnd)
          ? BoxDecoration(
              gradient: LinearGradient(
                colors: [isStart ? Colors.transparent : p.primaryTint, isEnd ? Colors.transparent : p.primaryTint],
                stops: const [0.5, 0.5],
              ),
            )
          : null;

      return Semantics(
        button: !disabled,
        selected: selected,
        label: AppDates.fullDate(date),
        child: GestureDetector(
          onTap: disabled ? null : () => _tap(date),
          child: Container(
            height: 40,
            decoration: band,
            alignment: Alignment.center,
            child: Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? p.primary : Colors.transparent,
                shape: BoxShape.circle,
                border: isToday && !selected ? Border.all(color: p.primary, width: 1.5) : null,
              ),
              child: Text(
                '$day',
                style: t.label.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: selected ? p.onPrimary : (disabled ? p.subtle : (isToday ? p.primaryDark : p.ink)),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      child: Column(
        children: [
          Row(
            children: [
              AppIconButton(
                icon: Icons.chevron_left_rounded,
                tooltip: 'Previous month',
                style: IconButtonStyle.plain,
                onPressed: canGoBack ? () => setState(() => _month = DateTime(_month.year, _month.month - 1)) : null,
              ),
              Expanded(child: Text(AppDates.monthYear(_month), textAlign: TextAlign.center, style: t.heading)),
              AppIconButton(
                icon: Icons.chevron_right_rounded,
                tooltip: 'Next month',
                style: IconButtonStyle.plain,
                onPressed: () => setState(() => _month = DateTime(_month.year, _month.month + 1)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (final d in const ['S', 'M', 'T', 'W', 'T', 'F', 'S'])
                Expanded(child: Text(d, textAlign: TextAlign.center, style: t.caption.copyWith(fontWeight: FontWeight.w700))),
            ],
          ),
          const SizedBox(height: 6),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 4,
            childAspectRatio: 1.15,
            children: [
              for (var i = 0; i < leading; i++) const SizedBox.shrink(),
              for (var day = 1; day <= daysInMonth; day++) cell(day),
            ],
          ),
        ],
      ),
    );
  }
}
