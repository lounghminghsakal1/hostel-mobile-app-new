import 'package:flutter/material.dart';

import '../../../../../core/utils/app_dates.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../domain/student_home.dart';
import '../student_home_providers.dart';

/// The card at the top of the student home screen. It shows exactly one
/// state; "Mark attendance" only appears while the window is open.
class AttendanceCard extends StatelessWidget {
  const AttendanceCard({
    super.key,
    required this.state,
    required this.home,
    required this.checkIn,
    required this.onMark,
  });

  final AttendanceCardState state;
  final StudentHome home;
  final TodayAttendance? checkIn;
  final VoidCallback onMark;

  @override
  Widget build(BuildContext context) {
    final p = context.colors;
    final hostel = home.hostel;
    return switch (state) {
      AttendanceCardState.open => _OpenCard(hostel: hostel, onMark: onMark),
      AttendanceCardState.marked => _StatusCard(
          background: p.successSoft,
          iconBackground: p.success,
          iconColor: p.onSuccess,
          icon: Icons.check_rounded,
          label: 'Marked for today',
          labelColor: p.successInk,
          title: "You're in for tonight",
          body: _markedLine(checkIn),
        ),
      AttendanceCardState.notOpenYet => _StatusCard(
          background: p.surface,
          border: p.line,
          iconBackground: p.neutralSoft,
          iconColor: p.inkSoft,
          icon: Icons.schedule_rounded,
          label: 'Opens at ${hostel.startLabel}${_countdown(hostel)}',
          labelColor: p.muted,
          title: "Attendance isn't open yet",
          body: "Tonight's window is ${hostel.windowLabel}. The button appears here when it opens.",
        ),
      AttendanceCardState.missed => _StatusCard(
          background: p.surface,
          border: p.line,
          iconBackground: p.dangerSoft,
          iconColor: p.dangerInk,
          icon: Icons.highlight_off_rounded,
          label: 'Closed at ${hostel.endLabel}',
          labelColor: p.dangerInk,
          title: "You missed tonight's attendance",
          body: 'Your hostel admin can see this. Talk to them if you were in the hostel.',
        ),
      AttendanceCardState.photoNeeded => _StatusCard(
          background: p.accentSoft,
          iconBackground: p.surface,
          iconColor: p.accentInk,
          icon: Icons.photo_camera_outlined,
          label: 'Photo needed',
          labelColor: p.accentInk,
          title: 'Ask the hostel office to add your photo',
          body: "Attendance compares your selfie with your profile photo. Once it's added, you can check in here.",
        ),
      AttendanceCardState.onLeave => _StatusCard(
          background: p.primarySoft,
          iconBackground: p.surface,
          iconColor: p.primaryDark,
          icon: Icons.luggage_outlined,
          label: 'On approved leave',
          labelColor: p.primaryDark,
          title: 'Enjoy your time away',
          body: home.approvedLeaveToday == null
              ? "You don't need to mark attendance while you're on leave."
              : "Your leave runs ${AppDates.range(home.approvedLeaveToday!.from, home.approvedLeaveToday!.to)}. "
                  "You don't need to mark attendance until you're back.",
        ),
    };
  }

  static String _markedLine(TodayAttendance? checkIn) {
    if (checkIn == null) return 'Your check-in for tonight is saved.';
    final where = checkIn.insideHostelRadius ? 'at the hostel' : _distance(checkIn.distanceMeters);
    return 'Marked at ${AppDates.time(checkIn.reportedTime)} · $where';
  }

  static String _distance(double? meters) {
    if (meters == null) return 'away from the hostel';
    final label = meters >= 1000 ? '${(meters / 1000).toStringAsFixed(1)} km' : '${meters.round()} m';
    return '$label from the hostel';
  }

  static String _countdown(HostelSchedule hostel) {
    final parts = hostel.windowStart.split(':');
    final now = AppDates.ist(DateTime.now());
    final left = (int.tryParse(parts.first) ?? 0) * 60 + (int.tryParse(parts.last) ?? 0) - (now.hour * 60 + now.minute);
    if (left <= 0) return '';
    final h = left ~/ 60;
    final m = left % 60;
    return ' · in ${h > 0 ? '$h h ' : ''}$m min';
  }
}

class _OpenCard extends StatelessWidget {
  const _OpenCard({required this.hostel, required this.onMark});

  final HostelSchedule hostel;
  final VoidCallback onMark;

  @override
  Widget build(BuildContext context) {
    final p = context.colors;
    final t = context.text;
    return HeroPanel(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text('Window open · closes ${hostel.endLabel}', style: t.caption.copyWith(color: p.onPrimaryMuted, fontSize: 13)),
          ]),
          const SizedBox(height: 12),
          Text("Mark tonight's attendance", style: t.title.copyWith(color: p.onPrimary)),
          const SizedBox(height: 16),
          SizedBox(
            height: 56,
            child: AppButton(
              label: 'Mark attendance',
              icon: Icons.face_retouching_natural_outlined,
              variant: ButtonVariant.accent,
              expand: true,
              onPressed: onMark,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Takes a selfie and your location. About 10 seconds.',
            style: t.caption.copyWith(color: p.onPrimaryMuted, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.background,
    required this.iconBackground,
    required this.iconColor,
    required this.icon,
    required this.label,
    required this.labelColor,
    required this.title,
    required this.body,
    this.border,
  });

  final Color background;
  final Color? border;
  final Color iconBackground;
  final Color iconColor;
  final IconData icon;
  final String label;
  final Color labelColor;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    return Semantics(
      container: true,
      label: '$label. $title. $body',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(22),
          border: border == null ? null : Border.all(color: border!),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(color: iconBackground, shape: BoxShape.circle),
              child: Icon(icon, size: 26, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: t.caption.copyWith(color: labelColor, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(title, style: t.title.copyWith(fontSize: 21, height: 1.2)),
                  const SizedBox(height: 6),
                  Text(body, style: t.small.copyWith(color: context.colors.inkSoft)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
