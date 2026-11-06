import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_dimens.dart';
import 'app_palette.dart';
import 'app_text_styles.dart';

/// Builds the whole Material theme from one [AppPalette].
ThemeData buildAppTheme(AppPalette p) {
  final text = AppTextStyles(p);

  OutlineInputBorder border(Color color, [double width = 1.5]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: color, width: width),
      );

  final buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md));
  final buttonText = AppTextStyles.bodyFont(const TextStyle(fontSize: 15, fontWeight: FontWeight.w700));

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: p.primary,
      onPrimary: p.onPrimary,
      primaryContainer: p.primaryTint,
      onPrimaryContainer: p.primaryDeep,
      secondary: p.accent,
      onSecondary: p.onAccent,
      secondaryContainer: p.accentSoft,
      onSecondaryContainer: p.accentInk,
      tertiary: p.success,
      onTertiary: p.onSuccess,
      error: p.danger,
      onError: p.onPrimary,
      surface: p.surface,
      onSurface: p.ink,
      onSurfaceVariant: p.muted,
      outline: p.line,
      outlineVariant: p.line,
    ),
    scaffoldBackgroundColor: p.background,
    // google_fonts 9 builds its TextTheme helpers on the separate material_ui
    // package, so set the family here; app text uses AppTextStyles directly.
    fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
    extensions: [AppColors(p)],
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: p.background,
      surfaceTintColor: Colors.transparent,
      foregroundColor: p.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: text.title.copyWith(fontSize: 20),
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: p.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      hintStyle: text.body.copyWith(color: p.subtle),
      prefixIconColor: p.muted,
      suffixIconColor: p.muted,
      border: border(p.line),
      enabledBorder: border(p.line),
      focusedBorder: border(p.primary),
      errorBorder: border(p.danger),
      focusedErrorBorder: border(p.danger),
      errorStyle: text.caption.copyWith(color: p.dangerInk),
      errorMaxLines: 3,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.primary,
        foregroundColor: p.onPrimary,
        disabledBackgroundColor: p.neutralSoft,
        disabledForegroundColor: p.muted,
        minimumSize: const Size(64, 52),
        shape: buttonShape,
        textStyle: buttonText,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: p.ink,
        backgroundColor: p.surface,
        minimumSize: const Size(64, 52),
        side: BorderSide(color: p.line, width: 1.5),
        shape: buttonShape,
        textStyle: buttonText,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: p.primary,
        minimumSize: const Size(44, 44),
        textStyle: buttonText.copyWith(fontSize: 13.5),
      ),
    ),
    cardTheme: CardThemeData(
      color: p.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: p.line),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      modalBarrierColor: p.scrim,
      showDragHandle: true,
      dragHandleColor: p.line,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: p.primaryTint,
      height: 72,
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => text.caption.copyWith(
          fontSize: 11.5,
          color: states.contains(WidgetState.selected) ? p.primaryDark : p.muted,
          fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected) ? p.primaryDark : p.muted,
          size: 24,
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: p.ink,
      contentTextStyle: text.body.copyWith(color: p.surface, fontSize: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
    ),
    dividerTheme: DividerThemeData(color: p.line, thickness: 1, space: 1),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: p.primary),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      rangeSelectionBackgroundColor: p.primaryTint,
      headerBackgroundColor: p.primary,
      headerForegroundColor: p.onPrimary,
    ),
    timePickerTheme: TimePickerThemeData(
      backgroundColor: p.surface,
      dialHandColor: p.primary,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.all(p.surface),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? p.primary : p.subtle,
      ),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: p.primary,
      inactiveTrackColor: p.line,
      thumbColor: p.primary,
    ),
  );
}
