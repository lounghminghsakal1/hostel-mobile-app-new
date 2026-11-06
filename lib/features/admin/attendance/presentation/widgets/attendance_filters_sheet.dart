import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/utils/app_dates.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../rooms/presentation/room_providers.dart';
import '../../../students/presentation/admin_student_providers.dart';
import '../../domain/attendance_report.dart';

/// Returns the new filters, or null if the sheet was dismissed.
Future<AttendanceFilters?> showAttendanceFiltersSheet(BuildContext context, AttendanceFilters current) {
  return showAppSheet<AttendanceFilters>(context, builder: (_) => _FiltersSheet(initial: current));
}

class _FiltersSheet extends ConsumerStatefulWidget {
  const _FiltersSheet({required this.initial});

  final AttendanceFilters initial;

  @override
  ConsumerState<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends ConsumerState<_FiltersSheet> {
  late DateTime _from = widget.initial.from;
  late DateTime _to = widget.initial.to;
  late bool _range = !widget.initial.isSingleDay;
  late int? _departmentId = widget.initial.departmentId;
  late int? _roomId = widget.initial.roomId;
  late final _roll = TextEditingController(text: widget.initial.rollNumber);
  late bool _faceFilter = widget.initial.faceMatchPercent != null;
  late double _face = widget.initial.faceMatchPercent ?? FaceMatchLevel.trustedFrom;
  late FaceMatchOperator _op = widget.initial.faceMatchOperator;
  late bool _outside = widget.initial.outsideOnly;

  @override
  void dispose() {
    _roll.dispose();
    super.dispose();
  }

  Future<void> _pickDates() async {
    final today = AppDates.todayIst();
    if (_range) {
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(today.year - 1),
        lastDate: today,
        initialDateRange: DateTimeRange(start: _from, end: _to),
      );
      if (picked != null) {
        setState(() {
          _from = picked.start;
          _to = picked.end;
        });
      }
    } else {
      final picked = await showDatePicker(context: context, firstDate: DateTime(today.year - 1), lastDate: today, initialDate: _from);
      if (picked != null) setState(() => _from = _to = picked);
    }
  }

  void _apply() {
    final roll = _roll.text.trim();
    Navigator.of(context).pop(AttendanceFilters(
      from: _from,
      to: _range ? _to : _from,
      departmentId: _departmentId,
      roomId: _roomId,
      rollNumber: roll.isEmpty ? null : roll,
      faceMatchPercent: _faceFilter ? _face.roundToDouble() : null,
      faceMatchOperator: _op,
      outsideOnly: _outside,
    ));
  }

  void _reset() {
    final today = AppDates.todayIst();
    setState(() {
      _from = _to = today;
      _range = false;
      _departmentId = null;
      _roomId = null;
      _roll.clear();
      _faceFilter = false;
      _face = FaceMatchLevel.trustedFrom;
      _op = FaceMatchOperator.below;
      _outside = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final departments = ref.watch(departmentsProvider).value ?? const [];
    final rooms = ref.watch(allRoomsProvider).value ?? const [];
    final dateLabel = _range ? '${AppDates.dayMonth(_from)} – ${AppDates.dayMonth(_to)}' : AppDates.weekdayDayMonth(_from);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(children: [
          Expanded(child: Text('Filters', style: t.title.copyWith(fontSize: 22))),
          AppButton(label: 'Reset', variant: ButtonVariant.tonal, compact: true, onPressed: _reset),
        ]),
        const SizedBox(height: 18),
        LabeledField(
          label: 'Dates',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedTabs(
                labels: const ['Single day', 'Date range'],
                selected: _range ? 1 : 0,
                onChanged: (i) => setState(() {
                  _range = i == 1;
                  if (!_range) _to = _from;
                }),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _pickDates,
                icon: const Icon(Icons.calendar_today_rounded, size: 18),
                label: Text(dateLabel),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: LabeledField(
              label: 'Department',
              child: DropdownButtonFormField<int?>(
                initialValue: _departmentId,
                isExpanded: true,
                items: [
                  const DropdownMenuItem(value: null, child: Text('All')),
                  for (final d in departments) DropdownMenuItem(value: d.id, child: Text(d.name, overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (v) => setState(() => _departmentId = v),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: LabeledField(
              label: 'Room',
              child: DropdownButtonFormField<int?>(
                initialValue: _roomId,
                isExpanded: true,
                items: [
                  const DropdownMenuItem(value: null, child: Text('All rooms')),
                  for (final r in rooms) DropdownMenuItem(value: r.id, child: Text(r.number)),
                ],
                onChanged: (v) => setState(() => _roomId = v),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        AppTextField(label: 'Roll number', controller: _roll, hint: 'Exact roll number, e.g. 22CS1043'),
        const SizedBox(height: 16),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _faceFilter,
          onChanged: (v) => setState(() => _faceFilter = v),
          title: Text('Custom face match', style: t.label),
          subtitle: Text(
            'Present list only. For the usual check, tap "Face match below 65%" on the home screen.',
            style: t.small,
          ),
        ),
        if (_faceFilter) ...[
          Row(children: [
            SizedBox(
              width: 190,
              child: SegmentedTabs(
                labels: const ['Below', 'At least'],
                selected: _op == FaceMatchOperator.below ? 0 : 1,
                onChanged: (i) => setState(() => _op = i == 0 ? FaceMatchOperator.below : FaceMatchOperator.atLeast),
              ),
            ),
            const Spacer(),
            Text('${_face.round()}%', style: t.number.copyWith(fontSize: 22)),
          ]),
          Slider(value: _face, min: 0, max: 100, divisions: 20, label: '${_face.round()}%', onChanged: (v) => setState(() => _face = v)),
        ],
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _outside,
          onChanged: (v) => setState(() => _outside = v),
          title: Text('Only outside the hostel', style: t.label),
          subtitle: Text('Checked in away from the hostel radius', style: t.small),
        ),
        const SizedBox(height: 12),
        AppButton(label: 'Show results', expand: true, onPressed: _apply),
      ],
    );
  }
}
