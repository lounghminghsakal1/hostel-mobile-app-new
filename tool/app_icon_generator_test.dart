// Exports the launcher icon PNGs from the same painter the app uses.
//
//   flutter test tool/app_icon_generator_test.dart
//   dart run flutter_launcher_icons
//
// Lives in tool/ so a normal `flutter test` doesn't rewrite the icons.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:our_hostel/core/theme/app_palette.dart';
import 'package:our_hostel/core/widgets/brand.dart';

Future<void> _export(String path, int size, void Function(Canvas canvas, Size size) paint) async {
  final recorder = ui.PictureRecorder();
  paint(Canvas(recorder), Size.square(size.toDouble()));
  final image = await recorder.endRecording().toImage(size, size);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const p = AppPalette.ourHostel;

  test('export launcher icons', () async {
    // iOS and legacy Android: full-bleed square, the OS rounds the corners.
    await _export('assets/icon/app_icon.png', 1024, OurHostelLogoPainter.fromPalette(p, cornerRadius: 0).paint);
    // Android adaptive icon: gradient background + transparent foreground (flutter_launcher_icons adds a 16% inset).
    await _export(
      'assets/icon/app_icon_background.png',
      1024,
      OurHostelLogoPainter.fromPalette(p, cornerRadius: 0).paintBackground,
    );
    await _export(
      'assets/icon/app_icon_foreground.png',
      1024,
      OurHostelLogoPainter.fromPalette(p, drawBackground: false).paint,
    );
    // Rounded preview for docs and stores.
    await _export('assets/icon/app_icon_rounded.png', 512, OurHostelLogoPainter.fromPalette(p).paint);
  });
}
