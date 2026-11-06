import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

/// Semantic colour families used by badges, callouts and icon tiles.
enum Tone { primary, accent, success, warning, danger, neutral }

extension ToneColors on Tone {
  Color background(AppPalette p) => switch (this) {
        Tone.primary => p.primarySoft,
        Tone.accent => p.accentSoft,
        Tone.success => p.successSoft,
        Tone.warning => p.warningSoft,
        Tone.danger => p.dangerSoft,
        Tone.neutral => p.neutralSoft,
      };

  Color foreground(AppPalette p) => switch (this) {
        Tone.primary => p.primaryDark,
        Tone.accent => p.accentInk,
        Tone.success => p.successInk,
        Tone.warning => p.warningInk,
        Tone.danger => p.dangerInk,
        Tone.neutral => p.inkSoft,
      };

  Color solid(AppPalette p) => switch (this) {
        Tone.primary => p.primary,
        Tone.accent => p.accent,
        Tone.success => p.success,
        Tone.warning => p.warning,
        Tone.danger => p.danger,
        Tone.neutral => p.subtle,
      };
}
