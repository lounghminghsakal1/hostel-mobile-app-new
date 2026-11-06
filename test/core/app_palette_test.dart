import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:our_hostel/core/theme/app_palette.dart';

void main() {
  test('a palette survives a JSON round trip', () {
    final restored = AppPalette.fromJson(AppPalette.ourHostel.toJson());

    expect(restored.primary, AppPalette.ourHostel.primary);
    expect(restored.accent, AppPalette.ourHostel.accent);
    expect(restored.success, AppPalette.ourHostel.success);
    expect(restored.background, AppPalette.ourHostel.background);
  });

  test('missing or bad colours fall back to the default palette', () {
    final custom = AppPalette.fromJson({'id': 'teal', 'primary': '#0F766E', 'accent': 'not-a-colour'});

    expect(custom.id, 'teal');
    expect(custom.primary, const Color(0xFF0F766E));
    expect(custom.accent, AppPalette.ourHostel.accent);
    expect(custom.ink, AppPalette.ourHostel.ink);
  });
}
