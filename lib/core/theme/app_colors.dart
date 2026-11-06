import 'package:flutter/material.dart';

import 'app_palette.dart';
import 'app_text_styles.dart';

/// Carries the active [AppPalette] inside [ThemeData] so any widget can
/// read it with `context.colors`.
class AppColors extends ThemeExtension<AppColors> {
  const AppColors(this.palette);

  final AppPalette palette;

  @override
  AppColors copyWith({AppPalette? palette}) => AppColors(palette ?? this.palette);

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return t < 0.5 ? this : other;
  }
}

extension ThemeContextX on BuildContext {
  AppPalette get colors => Theme.of(this).extension<AppColors>()?.palette ?? AppPalette.ourHostel;

  AppTextStyles get text => AppTextStyles(colors);
}
