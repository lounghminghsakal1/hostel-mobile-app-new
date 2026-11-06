import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';

enum ButtonVariant { primary, accent, success, outline, tonal, danger, dangerSolid, light }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = ButtonVariant.primary,
    this.icon,
    this.loading = false,
    this.expand = false,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final IconData? icon;
  final bool loading;
  final bool expand;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = context.colors;
    final (bg, fg, border) = switch (variant) {
      ButtonVariant.primary => (p.primary, p.onPrimary, null),
      ButtonVariant.accent => (p.accent, p.onAccent, null),
      ButtonVariant.success => (p.success, p.onSuccess, null),
      ButtonVariant.outline => (p.surface, p.ink, p.line),
      ButtonVariant.tonal => (p.primarySoft, p.primaryDark, null),
      ButtonVariant.danger => (p.dangerSoft, p.dangerInk, null),
      ButtonVariant.dangerSolid => (p.danger, p.onPrimary, null),
      ButtonVariant.light => (p.surface, p.primaryDark, null),
    };

    final child = loading
        ? SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: fg))
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            ],
          );

    return FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        disabledBackgroundColor: loading ? bg : p.neutralSoft,
        disabledForegroundColor: loading ? fg : p.muted,
        minimumSize: Size(expand ? double.infinity : 64, compact ? 44 : 52),
        padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 20),
        side: border == null ? null : BorderSide(color: border, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(compact ? 13 : AppRadius.md)),
        textStyle: AppTextStyles.bodyFont(TextStyle(fontSize: compact ? 14 : 15, fontWeight: FontWeight.w700)),
      ),
      child: child,
    );
  }
}

enum IconButtonStyle { surface, plain, glass, tonal }

/// 44×44 rounded icon button from the design. [tooltip] doubles as the
/// accessibility label, so always give one.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.style = IconButtonStyle.surface,
    this.showDot = false,
    this.size = 44,
    this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final IconButtonStyle style;
  final bool showDot;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = context.colors;
    final (bg, fg, border) = switch (style) {
      IconButtonStyle.surface => (p.surface, p.ink, p.line),
      IconButtonStyle.plain => (Colors.transparent, p.ink, Colors.transparent),
      IconButtonStyle.glass => (p.onPrimary.withValues(alpha: 0.14), p.onPrimary, p.onPrimary.withValues(alpha: 0.22)),
      IconButtonStyle.tonal => (p.primarySoft, p.primaryDark, p.primarySoft),
    };

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          icon: Icon(icon, size: 22),
          style: IconButton.styleFrom(
            backgroundColor: bg,
            foregroundColor: color ?? fg,
            fixedSize: Size.square(size),
            minimumSize: Size.square(size),
            side: BorderSide(color: border),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(size * 0.32)),
          ),
        ),
        if (showDot)
          Positioned(
            top: 10,
            right: 11,
            child: IgnorePointer(
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: p.accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: p.surface, width: 2),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
