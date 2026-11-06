import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../error/app_exception.dart';
import '../theme/app_colors.dart';
import 'buttons.dart';
import 'tone.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.padding = const EdgeInsets.all(40)});

  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Padding(
        padding: padding,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2.6)),
      );
}

class MessageView extends StatelessWidget {
  const MessageView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.tone = Tone.primary,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Tone tone;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final p = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: tone.background(p), borderRadius: BorderRadius.circular(22)),
            child: Icon(icon, size: 32, color: tone.foreground(p)),
          ),
          const SizedBox(height: 18),
          Text(title, textAlign: TextAlign.center, style: context.text.heading),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center, style: context.text.small),
          if (action != null) ...[const SizedBox(height: 18), action!],
        ],
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({super.key, required this.title, required this.message, this.icon = Icons.inbox_outlined, this.action});

  final String title;
  final String message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) =>
      MessageView(icon: icon, title: title, message: message, tone: Tone.neutral, action: action);
}

/// Shows an error with a retry button, or a friendly "coming soon" state
/// when the backend endpoint doesn't exist yet ([ApiPendingException]).
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final e = toAppException(error);
    if (e is ApiPendingException) {
      return MessageView(
        icon: Icons.hourglass_top_rounded,
        title: 'Coming soon',
        message: e.message,
        tone: Tone.primary,
      );
    }
    return MessageView(
      icon: e.isNetworkError ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
      title: e.isNetworkError ? "You're offline" : 'Something went wrong',
      message: e.message,
      tone: e.isNetworkError ? Tone.warning : Tone.danger,
      action: onRetry == null
          ? null
          : AppButton(label: 'Try again', onPressed: onRetry, variant: ButtonVariant.tonal, compact: true),
    );
  }
}

/// Loading / error / data switch for a Riverpod [AsyncValue].
class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({super.key, required this.value, required this.data, this.onRetry, this.loading});

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;
  final Widget? loading;

  @override
  Widget build(BuildContext context) => value.when(
        data: data,
        loading: () => loading ?? const LoadingView(),
        error: (error, _) => ErrorView(error: error, onRetry: onRetry),
      );
}
