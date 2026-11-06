import 'package:flutter/material.dart';

import '../../../../core/widgets/widgets.dart';

/// Big double circle with an icon, used on success / expired screens.
class ResultIllustration extends StatelessWidget {
  const ResultIllustration({super.key, required this.icon, this.tone = Tone.success, this.size = 120});

  final IconData icon;
  final Tone tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.colors;
    final solid = tone.solid(p);
    final onSolid = tone == Tone.danger ? p.onPrimary : p.ink;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: tone.background(p), shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Container(
        width: size * 0.68,
        height: size * 0.68,
        decoration: BoxDecoration(color: solid, shape: BoxShape.circle),
        child: Icon(icon, size: size * 0.34, color: onSolid),
      ),
    );
  }
}
