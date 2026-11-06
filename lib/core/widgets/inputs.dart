import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/validators.dart';

/// Bold label above any input, with an optional "(optional)" hint.
class LabeledField extends StatelessWidget {
  const LabeledField({super.key, required this.label, required this.child, this.optional = false, this.trailing});

  final String label;
  final Widget child;
  final bool optional;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(text: label),
                  if (optional) TextSpan(text: '  (optional)', style: t.small.copyWith(fontSize: 12.5)),
                ]),
                style: t.caption.copyWith(fontSize: 13, fontWeight: FontWeight.w700, color: context.colors.inkSoft),
              ),
            ),
            ?trailing,
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.optional = false,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.obscure = false,
    this.prefixIcon,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.inputFormatters,
    this.onChanged,
    this.enabled = true,
    this.autofillHints,
    this.errorText,
    this.helperText,
    this.labelTrailing,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final bool optional;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscure;
  final IconData? prefixIcon;
  final int maxLines;
  final int? minLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final Iterable<String>? autofillHints;
  final String? errorText;
  final String? helperText;
  final Widget? labelTrailing;
  final ValueChanged<String>? onSubmitted;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _hidden = widget.obscure;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    return LabeledField(
      label: widget.label,
      optional: widget.optional,
      trailing: widget.labelTrailing,
      child: TextFormField(
        controller: widget.controller,
        validator: widget.validator,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        obscureText: _hidden,
        maxLines: widget.obscure ? 1 : widget.maxLines,
        minLines: widget.minLines,
        maxLength: widget.maxLength,
        inputFormatters: widget.inputFormatters,
        onChanged: widget.onChanged,
        onFieldSubmitted: widget.onSubmitted,
        enabled: widget.enabled,
        autofillHints: widget.autofillHints,
        style: t.body.copyWith(color: context.colors.ink),
        decoration: InputDecoration(
          hintText: widget.hint,
          errorText: widget.errorText,
          helperText: widget.helperText,
          helperStyle: t.caption,
          helperMaxLines: 2,
          prefixIcon: widget.prefixIcon == null ? null : Icon(widget.prefixIcon, size: 20),
          suffixIcon: widget.obscure
              ? IconButton(
                  tooltip: _hidden ? 'Show password' : 'Hide password',
                  icon: Icon(_hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
                  onPressed: () => setState(() => _hidden = !_hidden),
                )
              : null,
        ),
      ),
    );
  }
}

class PasswordStrengthBar extends StatelessWidget {
  const PasswordStrengthBar({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final p = context.colors;
    final score = passwordStrength(password);
    final (color, label) = switch (score) {
      0 => (p.line, 'Use at least 8 characters with a number'),
      1 || 2 => (p.warning, 'Okay. Add a capital letter or symbol to make it stronger.'),
      3 => (p.success, 'Strong password'),
      _ => (p.success, 'Very strong password'),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < 4; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 5,
                  decoration: BoxDecoration(
                    color: i < score ? color : p.line,
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: context.text.caption.copyWith(
            color: score >= 3 ? p.successInk : (score > 0 ? p.warningInk : p.muted),
          ),
        ),
      ],
    );
  }
}

/// Pill-style segmented control (Present / Absent, Announcements / Events).
class SegmentedTabs extends StatelessWidget {
  const SegmentedTabs({super.key, required this.labels, required this.selected, required this.onChanged});

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.colors;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: const Color(0xFFECEAF6), borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: Semantics(
                selected: i == selected,
                button: true,
                child: GestureDetector(
                  onTap: () => onChanged(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i == selected ? p.surface : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: i == selected
                          ? [BoxShadow(color: p.ink.withValues(alpha: 0.12), blurRadius: 3, offset: const Offset(0, 1))]
                          : null,
                    ),
                    child: Text(
                      labels[i],
                      style: AppTextStyles.bodyFont(TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: i == selected ? p.ink : p.muted,
                      )),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class FilterOption<T> {
  const FilterOption(this.value, this.label, {this.count});

  final T value;
  final String label;
  final int? count;
}

/// Horizontally scrolling single-select chips.
class FilterChipBar<T> extends StatelessWidget {
  const FilterChipBar({super.key, required this.options, required this.selected, required this.onSelected});

  final List<FilterOption<T>> options;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final p = context.colors;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (final option in options) ...[
            if (option != options.first) const SizedBox(width: 8),
            Builder(builder: (context) {
              final on = option.value == selected;
              return Material(
                color: on ? p.ink : p.surface,
                shape: StadiumBorder(side: BorderSide(color: on ? p.ink : p.line)),
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: () => onSelected(option.value),
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    child: Row(
                      children: [
                        Text(
                          option.label,
                          style: AppTextStyles.bodyFont(TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: on ? p.surface : p.inkSoft,
                          )),
                        ),
                        if (option.count != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                            decoration: BoxDecoration(
                              color: on ? p.surface.withValues(alpha: 0.18) : p.background,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${option.count}',
                              style: AppTextStyles.bodyFont(TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: on ? p.surface : p.muted,
                              )),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
