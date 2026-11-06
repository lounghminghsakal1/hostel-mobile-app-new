import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import 'buttons.dart';

/// The custom top bar from the design: optional back button, a title with an
/// optional subtitle, and trailing actions.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    this.title,
    this.subtitle,
    this.titleWidget,
    this.showBack = false,
    this.backIcon = Icons.arrow_back_rounded,
    this.onBack,
    this.actions = const [],
    this.large = false,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String? title;
  final String? subtitle;
  final Widget? titleWidget;
  final bool showBack;
  final IconData backIcon;
  final VoidCallback? onBack;
  final List<Widget> actions;
  final bool large;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Size get preferredSize => const Size.fromHeight(76);

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final fg = foregroundColor ?? context.colors.ink;
    return Material(
      color: backgroundColor ?? context.colors.background,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 14, AppSpacing.gutter, 10),
          child: Row(
            children: [
              if (showBack) ...[
                AppIconButton(
                  icon: backIcon,
                  tooltip: 'Back',
                  style: foregroundColor == null ? IconButtonStyle.surface : IconButtonStyle.glass,
                  onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: titleWidget ??
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (title != null)
                          Text(
                            title!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.title.copyWith(fontSize: large || !showBack ? 22 : 20, color: fg),
                          ),
                        if (subtitle != null) Text(subtitle!, style: t.small.copyWith(color: fg.withValues(alpha: 0.75))),
                      ],
                    ),
              ),
              for (final action in actions) ...[const SizedBox(width: 10), action],
            ],
          ),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.actionLabel, this.onAction, this.trailing});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Semantics(header: true, child: Text(title, style: context.text.heading))),
        ?trailing,
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(padding: const EdgeInsets.only(left: 8)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [Text(actionLabel!), const Icon(Icons.chevron_right_rounded, size: 18)],
            ),
          ),
      ],
    );
  }
}

/// The primary-coloured panel with soft decorative circles.
class HeroPanel extends StatelessWidget {
  const HeroPanel({super.key, required this.child, this.padding = const EdgeInsets.all(20)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final p = context.colors;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: p.primary,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [BoxShadow(color: p.primary.withValues(alpha: 0.28), blurRadius: 28, spreadRadius: -12, offset: const Offset(0, 14))],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -80,
            top: -100,
            child: Container(width: 230, height: 230, decoration: BoxDecoration(color: p.primaryLight, shape: BoxShape.circle)),
          ),
          Positioned(
            right: 28,
            bottom: -84,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: p.primaryDark, width: 20)),
            ),
          ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

/// Glassy chip used on top of [HeroPanel].
class GlassChip extends StatelessWidget {
  const GlassChip({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: p.onPrimary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.onPrimary.withValues(alpha: 0.2)),
      ),
      child: DefaultTextStyle.merge(
        style: context.text.caption.copyWith(color: p.onPrimary, fontWeight: FontWeight.w700),
        child: child,
      ),
    );
  }
}

/// Standard scrollable screen body with the 20px gutter.
class ScreenList extends StatelessWidget {
  const ScreenList({super.key, required this.children, this.onRefresh, this.bottomPadding = 24, this.gap = 20});

  final List<Widget> children;
  final Future<void> Function()? onRefresh;
  final double bottomPadding;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final list = ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(AppSpacing.gutter, 4, AppSpacing.gutter, bottomPadding),
      itemCount: children.length,
      separatorBuilder: (_, _) => SizedBox(height: gap),
      itemBuilder: (_, i) => children[i],
    );
    if (onRefresh == null) return list;
    return RefreshIndicator(onRefresh: onRefresh!, child: list);
  }
}

/// White footer that holds the main action of a form screen.
class BottomActionBar extends StatelessWidget {
  const BottomActionBar({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: context.colors.surface, border: Border(top: BorderSide(color: context.colors.line))),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 12, AppSpacing.gutter, 12),
          child: Row(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                Expanded(flex: i == children.length - 1 && children.length > 1 ? 3 : 2, child: children[i]),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
