import 'package:flutter/material.dart';

import '../error/app_exception.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'tone.dart';

class InfoCallout extends StatelessWidget {
  const InfoCallout({
    super.key,
    required this.message,
    this.title,
    this.tone = Tone.primary,
    this.icon = Icons.info_outline_rounded,
    this.action,
  });

  final String message;
  final String? title;
  final Tone tone;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final p = context.colors;
    final fg = tone == Tone.primary ? p.primaryDeep : tone.foreground(p);
    final style = AppTextStyles.bodyFont(TextStyle(fontSize: 13.5, height: 1.5, color: fg, fontWeight: FontWeight.w500));
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: tone.background(p), borderRadius: BorderRadius.circular(16)),
      child: Row(
        crossAxisAlignment: action == null ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                if (title != null) TextSpan(text: '$title ', style: style.copyWith(fontWeight: FontWeight.w700)),
                TextSpan(text: message),
              ]),
              style: style,
            ),
          ),
          if (action != null) ...[const SizedBox(width: 8), action!],
        ],
      ),
    );
  }
}

extension SnackbarX on BuildContext {
  void showMessage(String message) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void showError(Object error) => showMessage(toAppException(error).message);
}
