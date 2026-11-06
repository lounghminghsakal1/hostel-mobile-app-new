import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import 'tone.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
    this.borderColor,
    this.color,
    this.lifted = false,
    this.radius = AppRadius.lg,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? borderColor;
  final Color? color;
  final bool lifted;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final p = context.colors;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(color: borderColor ?? p.line),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: lifted
            ? [BoxShadow(color: p.ink.withValues(alpha: 0.10), blurRadius: 28, spreadRadius: -14, offset: const Offset(0, 10))]
            : null,
      ),
      child: Material(
        color: color ?? p.surface,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// A card whose children are separated by hairlines (lists, detail rows).
class GroupedCard extends StatelessWidget {
  const GroupedCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            children[i],
          ],
        ],
      ),
    );
  }
}

class IconTile extends StatelessWidget {
  const IconTile({super.key, required this.icon, this.tone = Tone.primary, this.size = 40});

  final IconData icon;
  final Tone tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.colors;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: tone.background(p), borderRadius: BorderRadius.circular(size * 0.3)),
      child: Icon(icon, size: size * 0.48, color: tone.foreground(p)),
    );
  }
}

/// Icon + label + value row used on detail screens.
class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.tone = Tone.primary,
    this.trailing,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Tone tone;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            if (icon != null) ...[IconTile(icon: icon!, tone: tone), const SizedBox(width: 12)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: t.caption),
                  const SizedBox(height: 2),
                  Text(value, style: t.label.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ],
        ),
      ),
    );
  }
}
