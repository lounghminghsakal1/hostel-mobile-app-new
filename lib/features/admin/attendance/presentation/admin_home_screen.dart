import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/utils/app_dates.dart';
import '../../../../core/utils/launcher.dart';
import '../../../../core/utils/text_utils.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../common/media/presentation/signed_image.dart';
import '../../home/presentation/admin_providers.dart';
import '../../shell/admin_top_bar.dart';
import '../domain/attendance_report.dart';
import 'attendance_report_providers.dart';
import 'widgets/attendance_filters_sheet.dart';
import 'widgets/attendance_record_sheet.dart';

/// Admin home: who checked in, who didn't, for a day or a date range.
class AdminHomeScreen extends ConsumerStatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  ConsumerState<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends ConsumerState<AdminHomeScreen> {
  int _tab = 0; // 0 present, 1 absent
  String _search = '';
  final _searchController = TextEditingController();
  AttendanceSummary? _summary;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openFilters() async {
    final current = ref.read(attendanceFiltersProvider);
    final next = await showAttendanceFiltersSheet(context, current);
    if (next != null) ref.read(attendanceFiltersProvider.notifier).apply(next);
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(attendanceFiltersProvider);
    final profile = ref.watch(adminProfileProvider).value;
    final t = context.text;
    final repo = ref.read(attendanceReportRepositoryProvider);
    final search = _search.isEmpty ? null : _search;

    final header = <Widget>[
      _WeekStrip(filters: filters, onSelect: (d) => ref.read(attendanceFiltersProvider.notifier).selectDay(d)),
      if (!filters.isSingleDay)
        InfoCallout(
          message: 'Showing ${AppDates.dayMonth(filters.from)} – ${AppDates.dayMonth(filters.to)}',
          icon: Icons.date_range_rounded,
          action: AppButton(
            label: 'Today',
            compact: true,
            variant: ButtonVariant.light,
            onPressed: () => ref.read(attendanceFiltersProvider.notifier).selectDay(AppDates.todayIst()),
          ),
        ),
      _SummaryTiles(summary: _summary, singleDay: filters.isSingleDay),
      SegmentedTabs(
        labels: [
          'Present${_summary == null ? '' : ' · ${_summary!.presentCount}'}',
          'Absent${_summary == null ? '' : ' · ${_summary!.completelyAbsentCount}'}',
        ],
        selected: _tab,
        onChanged: (i) => setState(() => _tab = i),
      ),
      Row(
        children: [
          Expanded(
            child: SearchField(
              controller: _searchController,
              hint: 'Search by name',
              onSearch: (v) => setState(() => _search = v),
            ),
          ),
          const SizedBox(width: 10),
          AppIconButton(
            icon: Icons.tune_rounded,
            tooltip: filters.extraCount == 0 ? 'Filters' : 'Filters, ${filters.extraCount} on',
            showDot: filters.extraCount > 0,
            size: 52,
            onPressed: _openFilters,
          ),
        ],
      ),
    ];

    final faceChips = FilterChipBar<_FaceChip>(
      selected: filters.isLowFaceMatchOnly ? _FaceChip.low : (filters.hasCustomFaceMatch ? _FaceChip.custom : _FaceChip.all),
      onSelected: (chip) {
        final notifier = ref.read(attendanceFiltersProvider.notifier);
        switch (chip) {
          case _FaceChip.all:
            notifier.apply(filters.withFaceMatch(null));
          case _FaceChip.low:
            notifier.apply(filters.withFaceMatch(FaceMatchLevel.trustedFrom));
          case _FaceChip.custom:
            _openFilters();
        }
      },
      options: [
        const FilterOption(_FaceChip.all, 'All check-ins'),
        FilterOption(_FaceChip.low, 'Face match below ${FaceMatchLevel.trustedFrom.round()}%'),
        FilterOption(
          _FaceChip.custom,
          filters.hasCustomFaceMatch
              ? 'Face ${filters.faceMatchOperator == FaceMatchOperator.below ? 'below' : 'at least'} ${filters.faceMatchPercent!.round()}%'
              : 'Custom…',
        ),
      ],
    );

    void keepSummary(AttendanceSummary s) {
      if (mounted &&
          (_summary == null ||
              _summary!.totalStudents != s.totalStudents ||
              _summary!.presentCount != s.presentCount ||
              _summary!.completelyAbsentCount != s.completelyAbsentCount)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _summary = s);
        });
      }
    }

    return Scaffold(
      appBar: AdminTopBar(
        title: profile?.hostelName ?? 'Attendance',
        titleWidget: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Hi, ${profile?.name.firstName ?? 'there'}', style: t.small.copyWith(fontWeight: FontWeight.w600)),
            Text(profile?.hostelName ?? 'Attendance', maxLines: 1, overflow: TextOverflow.ellipsis, style: t.title),
          ],
        ),
        actions: [AppIconButton(icon: Icons.calendar_month_outlined, tooltip: 'Pick dates', onPressed: _openFilters)],
      ),
      body: _tab == 0
          ? PagedList<PresentRecord>(
              key: const ValueKey('present'),
              query: (filters, search),
              header: [...header, faceChips],
              grouped: true,
              fetch: (page) async {
                final result = await repo.present(filters, search: search, page: page);
                keepSummary(result.summary);
                return result.page;
              },
              empty: filters.faceMatchPercent != null
                  ? const EmptyView(
                      icon: Icons.verified_user_outlined,
                      title: 'No low face matches',
                      message: 'Every check-in for these dates is above the face match limit.',
                    )
                  : const EmptyView(
                      icon: Icons.nights_stay_outlined,
                      title: 'No check-ins yet',
                      message: 'Students show up here as they mark attendance.',
                    ),
              itemBuilder: (context, r) => _PresentRow(record: r, showDate: !filters.isSingleDay),
            )
          : PagedList<AbsentRecord>(
              key: const ValueKey('absent'),
              query: (filters, search),
              header: [
                ...header,
                if (!filters.isSingleDay)
                  Text(
                    'The list shows anyone absent on at least one day. The Absent count above only counts students absent every day.',
                    style: t.small,
                  ),
              ],
              grouped: true,
              fetch: (page) async {
                final result = await repo.absent(filters, search: search, page: page);
                keepSummary(result.summary);
                return result.page;
              },
              empty: const EmptyView(
                icon: Icons.celebration_outlined,
                title: 'Everyone is in!',
                message: 'No one is absent for these dates.',
              ),
              itemBuilder: (context, r) => _AbsentRow(record: r, showDates: !filters.isSingleDay),
            ),
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.filters, required this.onSelect});

  final AttendanceFilters filters;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final p = context.colors;
    final t = context.text;
    final today = AppDates.todayIst();
    final days = [for (var i = 6; i >= 0; i--) today.subtract(Duration(days: i))];
    return Row(
      children: [
        for (final day in days) ...[
          if (day != days.first) const SizedBox(width: 6),
          Expanded(
            child: Builder(
              builder: (context) {
                final on = filters.isSingleDay && AppDates.isSameDay(filters.from, day);
                return Material(
                  color: on ? p.primary : p.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: BorderSide(color: on ? p.primary : p.line),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(15),
                    onTap: () => onSelect(day),
                    child: SizedBox(
                      height: 58,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            AppDates.isSameDay(day, today) ? 'Today' : AppDates.weekdayShort(day),
                            style: t.caption.copyWith(
                              fontSize: 10.5,
                              color: on ? p.onPrimaryMuted : p.muted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text('${day.day}', style: t.number.copyWith(fontSize: 17, color: on ? p.onPrimary : p.ink)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _SummaryTiles extends StatelessWidget {
  const _SummaryTiles({required this.summary, required this.singleDay});

  final AttendanceSummary? summary;
  final bool singleDay;

  @override
  Widget build(BuildContext context) {
    final p = context.colors;
    final t = context.text;
    final s = summary;

    Widget tile(String label, String value, Color bg, Color fg, {Widget? info}) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: bg == p.surface ? Border.all(color: p.line) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(label, style: t.caption.copyWith(color: fg)),
                if (info != null) ...[const SizedBox(width: 4), info],
              ],
            ),
            Text(value, style: t.number.copyWith(color: fg == p.muted ? p.ink : fg)),
          ],
        ),
      ),
    );

    final total = s?.totalStudents ?? 0;
    final present = s?.presentCount ?? 0;
    final absent = s?.completelyAbsentCount ?? 0;
    final rate = total == 0 ? 0 : (present / total * 100).round();

    return Column(
      children: [
        Row(
          children: [
            tile('Students', s == null ? '–' : '$total', p.surface, p.muted),
            const SizedBox(width: 10),
            tile('Present', s == null ? '–' : '$present', p.successSoft, p.successInk),
            const SizedBox(width: 10),
            tile(
              'Absent',
              s == null ? '–' : '$absent',
              p.accentSoft,
              p.accentInk,
              info: Tooltip(
                message: singleDay ? 'Not checked in on this day' : 'Absent on every day in the range',
                triggerMode: TooltipTriggerMode.tap,
                child: Icon(Icons.info_outline_rounded, size: 14, color: p.accentInk),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 10,
            child: Row(
              children: [
                Expanded(
                  flex: present == 0 && absent == 0 ? 1 : present,
                  child: Container(color: total == 0 ? p.line : p.success),
                ),
                if (absent > 0) ...[
                  const SizedBox(width: 3),
                  Expanded(
                    flex: absent,
                    child: Container(color: p.accent),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [Expanded(child: Text(s == null ? 'Loading…' : '$rate% checked in', style: t.caption))],
        ),
      ],
    );
  }
}

class _PresentRow extends StatelessWidget {
  const _PresentRow({required this.record, required this.showDate});

  final PresentRecord record;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final p = context.colors;
    final r = record;
    final tone = faceMatchTone(r.faceMatchPercent);
    final when = showDate
        ? '${AppDates.dayMonth(r.attendanceDate)}, ${AppDates.time(r.reportedTime)}'
        : AppDates.time(r.reportedTime);
    return InkWell(
      onTap: () => showAttendanceRecordSheet(context, r),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _SelfieThumb(record: r, borderColor: tone.solid(p)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(r.studentName, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.label),
                      ),
                      if (!r.insideRadius) ...[
                        const SizedBox(width: 6),
                        StatusBadge(
                          label: distanceLabel(r.distanceMeters),
                          tone: Tone.warning,
                          showDot: false,
                          small: true,
                        ),
                      ],
                    ],
                  ),
                  Text(
                    [r.rollNumber, r.roomNumber, when].whereType<String>().join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.small,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (r.faceMatchPercent != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: tone.background(p), borderRadius: BorderRadius.circular(8)),
                child: Text(
                  '${r.faceMatchPercent!.round()}%',
                  style: t.caption.copyWith(color: tone.foreground(p), fontWeight: FontWeight.w800),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

enum _FaceChip { all, low, custom }

/// Tonight's selfie, framed in the face match colour. Falls back to the
/// student's avatar when there's no selfie.
class _SelfieThumb extends StatelessWidget {
  const _SelfieThumb({required this.record, required this.borderColor});

  final PresentRecord record;
  final Color borderColor;

  static const _size = 52.0;

  @override
  Widget build(BuildContext context) {
    final r = record;
    final avatar = PersonAvatar(name: r.studentName, imageKey: r.studentImageKey, size: _size - 6);
    return Semantics(
      image: true,
      label: '${r.studentName}, check-in selfie',
      child: Container(
        width: _size,
        height: _size,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: r.capturedImageKey == null
              ? Center(child: avatar)
              : SignedImage(objectKey: r.capturedImageKey, placeholder: Center(child: avatar)),
        ),
      ),
    );
  }
}

class _AbsentRow extends StatelessWidget {
  const _AbsentRow({required this.record, required this.showDates});

  final AbsentRecord record;
  final bool showDates;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final r = record;
    return InkWell(
      onTap: r.studentId == null ? null : () => context.push(Routes.student(r.studentId!)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PersonAvatar(name: r.studentName, imageKey: r.studentImageKey),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.studentName, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.label),
                  Text(
                    [
                      r.rollNumber,
                      r.roomNumber,
                      if (r.parentMobileNumber != null) 'Parent ${r.parentMobileNumber!.asPhone}',
                    ].whereType<String>().join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.small,
                  ),
                  if (showDates && r.absentDates.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final d in r.absentDates)
                          StatusBadge(label: AppDates.dayMonth(d), tone: Tone.accent, showDot: false, small: true),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (r.parentMobileNumber != null)
              AppIconButton(
                icon: Icons.call_outlined,
                tooltip: "Call ${r.studentName.firstName}'s parent",
                onPressed: () => Launcher.call(r.parentMobileNumber!),
              ),
          ],
        ),
      ),
    );
  }
}
