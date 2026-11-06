import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/preferences.dart';
import 'app_palette.dart';

/// Holds the active colour palette. The whole app rebuilds its theme from
/// this one value, so changing colours is a single [applyPalette] call.
///
/// Future "hostel admin picks the theme" feature: fetch the hostel's palette
/// JSON after login (for example `GET /hostels/{id}/theme`, not built yet)
/// and pass `AppPalette.fromJson(json)` to [applyPalette]. The choice is
/// cached so the next launch opens in the right colours straight away.
final themeControllerProvider = NotifierProvider<ThemeController, AppPalette>(ThemeController.new);

class ThemeController extends Notifier<AppPalette> {
  @override
  AppPalette build() {
    final cached = ref.read(sharedPreferencesProvider).getString(PrefKeys.palette);
    if (cached == null) return AppPalette.ourHostel;
    try {
      return AppPalette.fromJson(jsonDecode(cached) as Map<String, dynamic>);
    } on Object {
      return AppPalette.ourHostel;
    }
  }

  Future<void> applyPalette(AppPalette palette) async {
    state = palette;
    await ref.read(sharedPreferencesProvider).setString(PrefKeys.palette, jsonEncode(palette.toJson()));
  }

  Future<void> resetToDefault() async {
    state = AppPalette.ourHostel;
    await ref.read(sharedPreferencesProvider).remove(PrefKeys.palette);
  }
}
