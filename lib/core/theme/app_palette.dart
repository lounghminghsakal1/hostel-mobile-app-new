import 'package:flutter/material.dart';

/// Every colour the app uses, in one place.
///
/// Widgets read colours through `context.colors` (see `app_colors.dart`) and
/// never hard-code hex values, so swapping the active palette re-themes the
/// whole app. A palette can be serialised with [toJson]/[fromJson], which is
/// what a future "hostel admin picks the theme" feature would store and fetch.
@immutable
class AppPalette {
  const AppPalette({
    required this.id,
    required this.name,
    required this.primary,
    required this.primaryDark,
    required this.primaryDeep,
    required this.primaryLight,
    required this.primarySoft,
    required this.primaryTint,
    required this.onPrimary,
    required this.onPrimaryMuted,
    required this.accent,
    required this.accentSoft,
    required this.accentInk,
    required this.onAccent,
    required this.success,
    required this.successSoft,
    required this.successInk,
    required this.onSuccess,
    required this.warning,
    required this.warningSoft,
    required this.warningInk,
    required this.danger,
    required this.dangerSoft,
    required this.dangerInk,
    required this.ink,
    required this.inkSoft,
    required this.muted,
    required this.subtle,
    required this.line,
    required this.neutralSoft,
    required this.background,
    required this.surface,
  });

  final String id;
  final String name;

  /// Brand colour: buttons, active tabs, links, hero panels.
  final Color primary;
  final Color primaryDark;
  final Color primaryDeep;
  final Color primaryLight;
  final Color primarySoft;
  final Color primaryTint;
  final Color onPrimary;
  final Color onPrimaryMuted;

  /// Highlight colour: the one big action per screen, Important tags, unread dots.
  final Color accent;
  final Color accentSoft;
  final Color accentInk;
  final Color onAccent;

  /// Good news: present, approved, paid, done.
  final Color success;
  final Color successSoft;
  final Color successInk;
  final Color onSuccess;

  final Color warning;
  final Color warningSoft;
  final Color warningInk;

  final Color danger;
  final Color dangerSoft;
  final Color dangerInk;

  final Color ink;
  final Color inkSoft;
  final Color muted;
  final Color subtle;
  final Color line;
  final Color neutralSoft;
  final Color background;
  final Color surface;

  Color get scrim => ink.withValues(alpha: 0.5);

  /// The default theme: Iris + Coral + Mint.
  static const AppPalette ourHostel = AppPalette(
    id: 'our_hostel',
    name: 'Iris, Coral and Mint',
    primary: Color(0xFF5B47E0),
    primaryDark: Color(0xFF4634C4),
    primaryDeep: Color(0xFF33259A),
    primaryLight: Color(0xFF6E5BF2),
    primarySoft: Color(0xFFF1EEFF),
    primaryTint: Color(0xFFE3DEFF),
    onPrimary: Color(0xFFFFFFFF),
    onPrimaryMuted: Color(0xFFECE9FF),
    accent: Color(0xFFFF7A59),
    accentSoft: Color(0xFFFFF0EB),
    accentInk: Color(0xFFB23A1C),
    onAccent: Color(0xFF17153A),
    success: Color(0xFF12B886),
    successSoft: Color(0xFFE6FAF3),
    successInk: Color(0xFF0B7A5A),
    onSuccess: Color(0xFF17153A),
    warning: Color(0xFFF5A524),
    warningSoft: Color(0xFFFFF6E0),
    warningInk: Color(0xFF8A5A00),
    danger: Color(0xFFE5484D),
    dangerSoft: Color(0xFFFDECEC),
    dangerInk: Color(0xFFB4232A),
    ink: Color(0xFF17153A),
    inkSoft: Color(0xFF3A3758),
    muted: Color(0xFF64617D),
    subtle: Color(0xFFB5B3C7),
    line: Color(0xFFE8E6F2),
    neutralSoft: Color(0xFFEFEEF4),
    background: Color(0xFFF6F5FB),
    surface: Color(0xFFFFFFFF),
  );

  /// Palettes a user (or hostel admin, later) can choose from.
  static const List<AppPalette> presets = [ourHostel];

  Map<String, Object> toJson() => {
        'id': id,
        'name': name,
        for (final entry in _colors.entries) entry.key: _hex(entry.value),
      };

  /// Builds a palette from JSON, falling back to [ourHostel] for any missing
  /// or malformed colour, so a partial theme from the server never breaks the UI.
  factory AppPalette.fromJson(Map<String, dynamic> json) {
    Color pick(String key, Color fallback) => _parseHex(json[key]) ?? fallback;
    const d = ourHostel;
    return AppPalette(
      id: json['id'] as String? ?? 'custom',
      name: json['name'] as String? ?? 'Custom',
      primary: pick('primary', d.primary),
      primaryDark: pick('primaryDark', d.primaryDark),
      primaryDeep: pick('primaryDeep', d.primaryDeep),
      primaryLight: pick('primaryLight', d.primaryLight),
      primarySoft: pick('primarySoft', d.primarySoft),
      primaryTint: pick('primaryTint', d.primaryTint),
      onPrimary: pick('onPrimary', d.onPrimary),
      onPrimaryMuted: pick('onPrimaryMuted', d.onPrimaryMuted),
      accent: pick('accent', d.accent),
      accentSoft: pick('accentSoft', d.accentSoft),
      accentInk: pick('accentInk', d.accentInk),
      onAccent: pick('onAccent', d.onAccent),
      success: pick('success', d.success),
      successSoft: pick('successSoft', d.successSoft),
      successInk: pick('successInk', d.successInk),
      onSuccess: pick('onSuccess', d.onSuccess),
      warning: pick('warning', d.warning),
      warningSoft: pick('warningSoft', d.warningSoft),
      warningInk: pick('warningInk', d.warningInk),
      danger: pick('danger', d.danger),
      dangerSoft: pick('dangerSoft', d.dangerSoft),
      dangerInk: pick('dangerInk', d.dangerInk),
      ink: pick('ink', d.ink),
      inkSoft: pick('inkSoft', d.inkSoft),
      muted: pick('muted', d.muted),
      subtle: pick('subtle', d.subtle),
      line: pick('line', d.line),
      neutralSoft: pick('neutralSoft', d.neutralSoft),
      background: pick('background', d.background),
      surface: pick('surface', d.surface),
    );
  }

  Map<String, Color> get _colors => {
        'primary': primary,
        'primaryDark': primaryDark,
        'primaryDeep': primaryDeep,
        'primaryLight': primaryLight,
        'primarySoft': primarySoft,
        'primaryTint': primaryTint,
        'onPrimary': onPrimary,
        'onPrimaryMuted': onPrimaryMuted,
        'accent': accent,
        'accentSoft': accentSoft,
        'accentInk': accentInk,
        'onAccent': onAccent,
        'success': success,
        'successSoft': successSoft,
        'successInk': successInk,
        'onSuccess': onSuccess,
        'warning': warning,
        'warningSoft': warningSoft,
        'warningInk': warningInk,
        'danger': danger,
        'dangerSoft': dangerSoft,
        'dangerInk': dangerInk,
        'ink': ink,
        'inkSoft': inkSoft,
        'muted': muted,
        'subtle': subtle,
        'line': line,
        'neutralSoft': neutralSoft,
        'background': background,
        'surface': surface,
      };

  static String _hex(Color c) =>
      '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  static Color? _parseHex(Object? value) {
    if (value is! String) return null;
    final hex = value.replaceFirst('#', '');
    if (hex.length != 6) return null;
    final parsed = int.tryParse(hex, radix: 16);
    return parsed == null ? null : Color(0xFF000000 | parsed);
  }
}
