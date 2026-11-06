import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import 'buttons.dart';
import 'cards.dart';
import 'tone.dart';

/// Opens a bottom sheet that resizes with the keyboard and scrolls when tall.
Future<T?> showAppSheet<T>(BuildContext context, {required WidgetBuilder builder}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.gutter, 24),
        child: builder(sheetContext),
      ),
    ),
  );
}

/// Asks the user to confirm a hard-to-undo action. Resolves to true on confirm.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
  IconData icon = Icons.help_outline_rounded,
  Tone tone = Tone.primary,
  bool destructive = false,
}) async {
  final result = await showAppSheet<bool>(
    context,
    builder: (sheetContext) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        IconTile(icon: icon, tone: destructive ? Tone.danger : tone, size: 52),
        const SizedBox(height: 16),
        Text(title, style: sheetContext.text.title.copyWith(fontSize: 22)),
        const SizedBox(height: 6),
        Text(message, style: sheetContext.text.body),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: cancelLabel,
                variant: ButtonVariant.outline,
                onPressed: () => Navigator.of(sheetContext).pop(false),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: AppButton(
                label: confirmLabel,
                variant: destructive ? ButtonVariant.dangerSolid : ButtonVariant.primary,
                onPressed: () => Navigator.of(sheetContext).pop(true),
              ),
            ),
          ],
        ),
      ],
    ),
  );
  return result ?? false;
}
