import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_palette.dart';

/// The Our Hostel logo: a ribbon-style house with an "H" inside, in a
/// mint-to-lavender gradient on deep indigo. Drawn from the palette, so it
/// follows the theme. The launcher icons are exported from the same painter
/// by `tool/app_icon_generator_test.dart`.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 52});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Our Hostel logo',
      child: CustomPaint(
        size: Size.square(size),
        painter: OurHostelLogoPainter.fromPalette(context.colors),
      ),
    );
  }
}

class OurHostelLogoPainter extends CustomPainter {
  const OurHostelLogoPainter({
    required this.backgroundTop,
    required this.backgroundBottom,
    required this.ribbonStart,
    required this.ribbonEnd,
    required this.shadow,
    this.cornerRadius = 0.26,
    this.contentScale = 1,
    this.drawBackground = true,
  });

  /// Background: primary deep → ink. Ribbon: light mint → light iris.
  factory OurHostelLogoPainter.fromPalette(
    AppPalette p, {
    double cornerRadius = 0.26,
    double contentScale = 1,
    bool drawBackground = true,
  }) =>
      OurHostelLogoPainter(
        backgroundTop: p.primaryDeep,
        backgroundBottom: p.ink,
        ribbonStart: Color.lerp(p.success, p.surface, 0.12)!,
        ribbonEnd: Color.lerp(p.primaryLight, p.surface, 0.3)!,
        shadow: p.ink,
        cornerRadius: cornerRadius,
        contentScale: contentScale,
        drawBackground: drawBackground,
      );

  final Color backgroundTop;
  final Color backgroundBottom;
  final Color ribbonStart;
  final Color ribbonEnd;
  final Color shadow;

  /// Corner radius as a fraction of the width; 0 for full-bleed app icons.
  final double cornerRadius;

  /// Shrinks the drawing inside the square (adaptive-icon safe zone).
  final double contentScale;
  final bool drawBackground;

  static const _ribbon = 9.6;

  @override
  void paint(Canvas canvas, Size size) {
    if (drawBackground) paintBackground(canvas, size);

    // Drawn on a 100 × 100 grid.
    canvas
      ..save()
      ..translate(size.width / 2, size.height / 2)
      ..scale(size.width / 100 * contentScale)
      ..translate(-50, -50);

    final diagonal = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [ribbonStart, ribbonEnd],
    ).createShader(const Rect.fromLTWH(17, 15, 66, 68));
    final vertical = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [ribbonStart, ribbonEnd],
    ).createShader(const Rect.fromLTWH(30, 36, 40, 44));

    Paint ribbon(Shader shader) => Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = _ribbon
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // The "H": two legs whose tops follow the roof, and a crossbar.
    // Filled, then stroked thinly with round joins to soften the corners.
    final h = Path()
      ..moveTo(32.5, 44.5)
      ..lineTo(41.5, 38.4)
      ..lineTo(41.5, 50.5)
      ..lineTo(58.5, 50.5)
      ..lineTo(58.5, 38.4)
      ..lineTo(67.5, 44.5)
      ..lineTo(67.5, 76)
      ..lineTo(58.5, 76)
      ..lineTo(58.5, 58)
      ..lineTo(41.5, 58)
      ..lineTo(41.5, 76)
      ..lineTo(32.5, 76)
      ..close();
    canvas
      ..drawPath(h, Paint()..shader = vertical)
      ..drawPath(
        h,
        Paint()
          ..shader = vertical
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeJoin = StrokeJoin.round,
      );

    // House outline in one stroke: bottom-left cap → left wall → roof →
    // right wall → bottom-right cap. The gap between the caps is the door.
    final outline = Path()
      ..moveTo(43.5, 78.4)
      ..lineTo(35.5, 78.4)
      ..arcToPoint(const Offset(21.8, 64.7), radius: const Radius.circular(13.7))
      ..lineTo(21.8, 42)
      ..quadraticBezierTo(21.8, 37.6, 25.4, 35.1)
      ..lineTo(46.6, 20.6)
      ..quadraticBezierTo(50, 18.3, 53.4, 20.6)
      ..lineTo(74.6, 35.1)
      ..quadraticBezierTo(78.2, 37.6, 78.2, 42)
      ..lineTo(78.2, 64.7)
      ..arcToPoint(const Offset(64.5, 78.4), radius: const Radius.circular(13.7))
      ..lineTo(56.5, 78.4);
    canvas.drawPath(outline, ribbon(diagonal));

    // Fold: the right roof passes over the left one at the apex. A soft
    // shadow, then the start of the right roof again with a flat end.
    canvas.drawPath(
      Path()
        ..moveTo(52.6, 21.4)
        ..lineTo(59, 25.8),
      Paint()
        ..color = shadow.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _ribbon * 0.7
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.8),
    );
    canvas
      ..drawPath(
        Path()
          ..moveTo(50, 19.45)
          ..quadraticBezierTo(51.7, 19.45, 53.4, 20.6)
          ..lineTo(64, 27.85),
        ribbon(diagonal)..strokeCap = StrokeCap.butt,
      )
      ..restore();
  }

  /// The indigo tile alone (also exported as the adaptive-icon background).
  void paintBackground(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(size.width * cornerRadius)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [backgroundTop, backgroundBottom],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(OurHostelLogoPainter old) =>
      old.backgroundTop != backgroundTop ||
      old.backgroundBottom != backgroundBottom ||
      old.ribbonStart != ribbonStart ||
      old.ribbonEnd != ribbonEnd ||
      old.shadow != shadow ||
      old.cornerRadius != cornerRadius ||
      old.contentScale != contentScale ||
      old.drawBackground != drawBackground;
}

/// Solid colour with a soft dot grid; stands in for event images.
class DottedCover extends StatelessWidget {
  const DottedCover({super.key, required this.color, this.child, this.height});

  final Color color;
  final Widget? child;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _DotsPainter(color: color, dot: context.colors.surface.withValues(alpha: 0.38)),
        child: child,
      ),
    );
  }
}

class _DotsPainter extends CustomPainter {
  _DotsPainter({required this.color, required this.dot});

  final Color color;
  final Color dot;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = color);
    final paint = Paint()..color = dot;
    for (var y = 7.0; y < size.height; y += 14) {
      for (var x = 7.0; x < size.width; x += 14) {
        canvas.drawCircle(Offset(x, y), 1.4, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotsPainter old) => old.color != color || old.dot != dot;
}
