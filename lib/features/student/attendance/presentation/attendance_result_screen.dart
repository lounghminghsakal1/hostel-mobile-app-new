import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/utils/app_dates.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/widgets/result_illustration.dart';
import 'attendance_providers.dart';

class AttendanceResultScreen extends StatelessWidget {
  const AttendanceResultScreen({super.key, required this.outcome});

  final AttendanceOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final surface = context.colors.surface;
    return Scaffold(
      backgroundColor: surface,
      appBar: AppTopBar(
        showBack: true,
        backIcon: Icons.close_rounded,
        backgroundColor: surface,
        onBack: () => context.go(Routes.studentHome),
      ),
      body: switch (outcome) {
        AttendanceMarked(:final mark) => _Marked(
            reportedTime: mark.reportedTime,
            inside: mark.insideHostelRadius,
            distance: mark.distanceFromHostelMeters,
          ),
        AttendanceNeedsPhoto() => const _NeedsPhoto(),
      },
      bottomNavigationBar: BottomActionBar(
        children: [AppButton(label: 'Back to home', onPressed: () => context.go(Routes.studentHome))],
      ),
    );
  }
}

class _Marked extends StatelessWidget {
  const _Marked({required this.reportedTime, required this.inside, this.distance});

  final DateTime reportedTime;
  final bool inside;
  final double? distance;

  String get _distanceLabel {
    final d = distance;
    if (d == null) return 'Away from the hostel';
    return d >= 1000 ? '${(d / 1000).toStringAsFixed(1)} km from hostel' : '${d.round()} m from hostel';
  }

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final p = context.colors;
    Widget confetti(double left, double top, Color color, {double w = 10, double h = 10, bool round = false}) => Positioned(
          left: left,
          top: top,
          child: Transform.rotate(
            angle: 0.4,
            child: Container(
              width: w,
              height: h,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(round ? 99 : 3)),
            ),
          ),
        );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Center(
          child: SizedBox(
            width: 200,
            height: 170,
            child: Stack(
              alignment: Alignment.center,
              children: [
                confetti(18, 30, p.accent, w: 12, h: 12),
                confetti(170, 18, p.primary, w: 9, h: 18),
                confetti(182, 104, p.warning, round: true),
                confetti(6, 118, p.success, w: 8, h: 16),
                confetti(52, 4, p.primary, w: 8, h: 8, round: true),
                const ResultIllustration(icon: Icons.check_rounded, size: 140),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text("You're checked in!", style: t.display, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(children: [
            const TextSpan(text: 'Attendance marked at '),
            TextSpan(text: AppDates.time(reportedTime), style: t.body.copyWith(color: p.ink, fontWeight: FontWeight.w700)),
            TextSpan(text: ', ${AppDates.fullDate(AppDates.ist(reportedTime))}.'),
          ]),
          style: t.body,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        GroupedCard(children: [
          InfoRow(
            icon: Icons.schedule_rounded,
            tone: Tone.success,
            label: 'Reported at',
            value: '${AppDates.time(reportedTime)} IST',
          ),
          InfoRow(
            icon: Icons.location_on_outlined,
            tone: inside ? Tone.success : Tone.warning,
            label: 'Location',
            value: inside ? 'Inside the hostel' : _distanceLabel,
            trailing: StatusBadge(label: inside ? 'Verified' : 'Outside', tone: inside ? Tone.success : Tone.warning),
          ),
        ]),
        if (!inside) ...[
          const SizedBox(height: 16),
          const InfoCallout(
            message: 'Your attendance is saved. You seem to be away from the hostel, so your warden will see the distance next to it.',
            tone: Tone.warning,
          ),
        ],
      ],
    );
  }
}

class _NeedsPhoto extends StatelessWidget {
  const _NeedsPhoto();

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
      children: [
        const Center(child: ResultIllustration(icon: Icons.person_off_outlined, tone: Tone.accent, size: 140)),
        const SizedBox(height: 24),
        Text("We can't verify you yet", style: t.display, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          "Your hostel hasn't added your reference photo, so tonight's check-in wasn't saved.",
          style: t.body,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        const InfoCallout(
          message: 'Ask the hostel office to upload your photo, then try again.',
          icon: Icons.support_agent_rounded,
        ),
      ],
    );
  }
}
