import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/text_utils.dart';
import 'tone.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.tone,
    this.showDot = true,
    this.small = false,
  });

  final String label;
  final Tone tone;
  final bool showDot;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final p = context.colors;
    final fg = tone.foreground(p);
    return Container(
      height: small ? 22 : 26,
      padding: EdgeInsets.symmetric(horizontal: small ? 8 : 10),
      decoration: BoxDecoration(color: tone.background(p), borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(width: 6, height: 6, decoration: BoxDecoration(color: fg, shape: BoxShape.circle)),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: AppTextStyles.bodyFont(TextStyle(fontSize: small ? 11 : 12, fontWeight: FontWeight.w700, color: fg)),
          ),
        ],
      ),
    );
  }
}

/// Small white calendar tile shown on event covers.
class DateBox extends StatelessWidget {
  const DateBox({super.key, required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final p = context.colors;
    return Container(
      width: 50,
      padding: const EdgeInsets.fromLTRB(0, 6, 0, 7),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(13),
        boxShadow: [BoxShadow(color: p.ink.withValues(alpha: 0.18), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            const ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'][date.month - 1],
            style: AppTextStyles.bodyFont(
              TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: p.accentInk),
            ),
          ),
          Text(
            date.day.toString().padLeft(2, '0'),
            style: context.text.number.copyWith(fontSize: 21, height: 1.05),
          ),
        ],
      ),
    );
  }
}

/// Circle with initials, used until a signed photo URL has loaded.
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({super.key, required this.name, this.size = 40});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.colors;
    final tones = [Tone.primary, Tone.accent, Tone.success, Tone.warning];
    final tone = tones[name.codeUnits.fold<int>(0, (a, b) => a + b) % tones.length];
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tone == Tone.primary ? p.primaryTint : tone.background(p),
        shape: BoxShape.circle,
      ),
      child: Text(
        name.initials,
        style: AppTextStyles.bodyFont(TextStyle(
          fontSize: size * 0.34,
          fontWeight: FontWeight.w700,
          color: tone == Tone.primary ? p.primaryDeep : tone.foreground(p),
        )),
      ),
    );
  }
}
