import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/router/routes.dart';
import '../../../../../core/utils/app_dates.dart';
import '../../../../../core/utils/launcher.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../../common/media/presentation/signed_image.dart';
import '../../domain/attendance_report.dart';

/// Green from 65%, yellow from 30%, red below 30%.
Tone faceMatchTone(double? percent) => switch (FaceMatchLevel.of(percent)) {
      FaceMatchLevel.trusted => Tone.success,
      FaceMatchLevel.check => Tone.warning,
      FaceMatchLevel.mismatch => Tone.danger,
      FaceMatchLevel.unknown => Tone.neutral,
    };

String faceMatchVerdict(double? percent) => switch (FaceMatchLevel.of(percent)) {
      FaceMatchLevel.trusted => 'Same person',
      FaceMatchLevel.check => 'Check the photos',
      FaceMatchLevel.mismatch => 'Likely not the same person',
      FaceMatchLevel.unknown => 'Not checked',
    };

String distanceLabel(double? meters) {
  if (meters == null) return 'Outside';
  return meters >= 1000 ? '${(meters / 1000).toStringAsFixed(1)} km away' : '${meters.round()} m away';
}

/// Photo on file next to tonight's selfie, with the match score and location.
Future<void> showAttendanceRecordSheet(BuildContext context, PresentRecord record) {
  return showAppSheet<void>(context, builder: (sheetContext) => _RecordSheet(record: record));
}

class _RecordSheet extends StatelessWidget {
  const _RecordSheet({required this.record});

  final PresentRecord record;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final p = context.colors;
    final r = record;
    final tone = faceMatchTone(r.faceMatchPercent);
    final match = r.faceMatchPercent;

    Widget photo(String caption, String? key, {bool dark = false, Color? border}) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: border ?? p.line, width: border == null ? 1 : 2.5),
                ),
                padding: const EdgeInsets.all(2),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(17),
                  child: AspectRatio(
                    aspectRatio: 3 / 4,
                    child: SignedImage(
                      objectKey: key,
                      placeholder: Container(
                        color: dark ? p.inkSoft : p.primaryTint,
                        child: Icon(Icons.person_outline_rounded, size: 64, color: dark ? p.primaryTint : p.primary),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(caption, style: t.caption),
            ],
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            PersonAvatar(name: r.studentName, imageKey: r.studentImageKey, size: 56),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.studentName, style: t.heading),
                  Text(
                    [r.rollNumber, r.departmentName, if (r.roomNumber != null) 'Room ${r.roomNumber}'].whereType<String>().join(' · '),
                    style: t.small,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(children: [
          photo('Photo on file', r.studentImageKey),
          const SizedBox(width: 10),
          photo('Selfie · ${AppDates.time(r.reportedTime)}', r.capturedImageKey, dark: true, border: tone.solid(p)),
        ]),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(color: tone.background(p), borderRadius: BorderRadius.circular(18)),
          child: Column(
            children: [
              Row(children: [
                Expanded(
                  child: Text(
                    'Face match · ${faceMatchVerdict(match)}',
                    style: t.label.copyWith(fontSize: 13.5, color: tone.foreground(p)),
                  ),
                ),
                Text(match == null ? '—' : '${match.round()}%', style: t.number.copyWith(fontSize: 24, color: tone.foreground(p))),
              ]),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: LinearProgressIndicator(
                  value: (match ?? 0) / 100,
                  minHeight: 8,
                  color: tone.solid(p),
                  backgroundColor: p.surface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '65% and above is trusted · 30–65% check the photos · below 30% likely someone else',
                style: t.caption.copyWith(color: tone.foreground(p)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GroupedCard(children: [
          InfoRow(
            icon: Icons.location_on_outlined,
            tone: r.insideRadius ? Tone.success : Tone.warning,
            label: 'Location',
            value: r.insideRadius
                ? 'Inside hostel radius${r.distanceMeters == null ? '' : ' · ${r.distanceMeters!.round()} m'}'
                : distanceLabel(r.distanceMeters),
            trailing: StatusBadge(label: r.insideRadius ? 'OK' : 'Outside', tone: r.insideRadius ? Tone.success : Tone.warning),
          ),
          InfoRow(
            icon: Icons.schedule_rounded,
            label: 'Reported at',
            value: '${AppDates.weekdayDayMonth(r.attendanceDate)} · ${AppDates.time(r.reportedTime)}',
          ),
        ]),
        const SizedBox(height: 18),
        Row(
          children: [
            if (r.contactNumber != null) ...[
              Expanded(
                child: AppButton(
                  label: 'Call',
                  icon: Icons.call_outlined,
                  variant: ButtonVariant.outline,
                  onPressed: () => Launcher.call(r.contactNumber!),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              flex: 2,
              child: AppButton(
                label: 'View student',
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push(Routes.student(r.studentId));
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
