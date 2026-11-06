import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_palette.dart';

/// Type scale from the design: Bricolage Grotesque for display text,
/// Plus Jakarta Sans for everything else.
class AppTextStyles {
  const AppTextStyles(this.palette);

  final AppPalette palette;

  static TextStyle displayFont(TextStyle style) => GoogleFonts.bricolageGrotesque(textStyle: style);

  static TextStyle bodyFont(TextStyle style) => GoogleFonts.plusJakartaSans(textStyle: style);

  TextStyle get display => displayFont(TextStyle(
        fontSize: 30,
        height: 1.12,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.75,
        color: palette.ink,
      ));

  TextStyle get title => displayFont(TextStyle(
        fontSize: 24,
        height: 1.18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: palette.ink,
      ));

  TextStyle get number => displayFont(TextStyle(
        fontSize: 26,
        height: 1.1,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: palette.ink,
        fontFeatures: const [FontFeature.tabularFigures()],
      ));

  TextStyle get heading => bodyFont(TextStyle(
        fontSize: 17,
        height: 1.3,
        fontWeight: FontWeight.w700,
        color: palette.ink,
      ));

  TextStyle get label => bodyFont(TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: palette.ink,
      ));

  TextStyle get body => bodyFont(TextStyle(
        fontSize: 15,
        height: 1.55,
        fontWeight: FontWeight.w500,
        color: palette.inkSoft,
      ));

  TextStyle get small => bodyFont(TextStyle(
        fontSize: 13,
        height: 1.45,
        fontWeight: FontWeight.w500,
        color: palette.muted,
      ));

  TextStyle get caption => bodyFont(TextStyle(
        fontSize: 12,
        height: 1.4,
        fontWeight: FontWeight.w600,
        color: palette.muted,
      ));

  TextStyle get overline => bodyFont(TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: palette.muted,
      ));
}
