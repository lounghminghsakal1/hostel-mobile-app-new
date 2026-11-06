import 'package:flutter/material.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/widgets/widgets.dart';

/// Shown while the saved session is read. The router moves on by itself.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.colors;
    return Scaffold(
      backgroundColor: p.primary,
      body: Stack(
        children: [
          Positioned(
            top: -150,
            right: -190,
            child: Container(width: 420, height: 420, decoration: BoxDecoration(color: p.primaryLight, shape: BoxShape.circle)),
          ),
          Positioned(
            bottom: -120,
            left: -90,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: p.primaryDark, width: 34)),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const BrandMark(size: 96),
                const SizedBox(height: 18),
                Text(AppConfig.appName, style: context.text.display.copyWith(fontSize: 44, color: p.onPrimary)),
                const SizedBox(height: 6),
                Text('Hostel life, sorted.', style: context.text.body.copyWith(color: p.onPrimaryMuted, fontSize: 16)),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 72,
            child: Center(
              child: SizedBox.square(
                dimension: 26,
                child: CircularProgressIndicator(strokeWidth: 2.6, color: p.onPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
