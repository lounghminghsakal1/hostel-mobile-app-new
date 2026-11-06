import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/utils/app_dates.dart';
import '../../../../core/utils/text_utils.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../common/mess_bills/mess_bill.dart';
import '../domain/mess_bills.dart';
import 'mess_bills_providers.dart';

class MessBillsScreen extends ConsumerWidget {
  const MessBillsScreen({super.key});

  Future<void> _openForm(BuildContext context, WidgetRef ref, List<MessBill> bills, {MessBill? existing}) async {
    // Months that already have a bill (other than the one being edited).
    final taken = {for (final b in bills) if (b.id != existing?.id) b.billMonth};
    final allowed = allowedBillMonths();
    if (existing == null && allowed.every(taken.contains)) {
      context.showMessage('${billMonthLabel(allowed.first)} and ${billMonthLabel(allowed.last)} already have bills. Edit the drafts instead.');
      return;
    }
    final saved = await showAppSheet<bool>(context, builder: (_) => _BillForm(existing: existing, takenMonths: taken));
    if (saved == true) ref.invalidate(messBillsProvider);
  }

  Future<void> _publish(BuildContext context, WidgetRef ref, MessBill bill) async {
    final ok = await confirmAction(
      context,
      title: "Publish ${AppDates.monthYear(bill.monthDate).split(' ').first}'s bill?",
      message: "Every student will see ${bill.amount.asRupees} due ${AppDates.dayMonth(bill.lastDate)} right away. Published bills can't be edited or deleted.",
      confirmLabel: 'Publish bill',
      icon: Icons.send_rounded,
    );
    if (!ok || !context.mounted) return;
    try {
      await ref.read(messBillRepositoryProvider).publish(bill.id);
      ref.invalidate(messBillsProvider);
      if (context.mounted) context.showMessage('Bill published.');
    } on Object catch (e) {
      if (context.mounted) context.showError(e);
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, MessBill bill) async {
    final ok = await confirmAction(
      context,
      title: 'Delete this draft?',
      message: 'The ${bill.title} draft will be removed.',
      confirmLabel: 'Delete',
      icon: Icons.delete_outline_rounded,
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    try {
      await ref.read(messBillRepositoryProvider).delete(bill.id);
      ref.invalidate(messBillsProvider);
    } on Object catch (e) {
      if (context.mounted) context.showError(e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bills = ref.watch(messBillsProvider);
    final t = context.text;
    final p = context.colors;
    return Scaffold(
      appBar: const AppTopBar(title: 'Mess bills', subtitle: 'This month and next only', showBack: true),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, ref, bills.value ?? const []),
        backgroundColor: p.accent,
        foregroundColor: p.onAccent,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Create bill'),
      ),
      body: AsyncValueView(
        value: bills,
        onRetry: () => ref.invalidate(messBillsProvider),
        data: (list) {
          final allowed = allowedBillMonths();
          final rule = 'You can set bills for ${billMonthLabel(allowed.first)} and ${billMonthLabel(allowed.last)} only.';
          if (list.isEmpty) {
            return EmptyView(icon: Icons.receipt_long_outlined, title: 'No bills yet', message: '$rule Create one with the button below.');
          }
          final drafts = list.where((b) => b.status == MessBillStatus.draft);
          final published = list.where((b) => b.status == MessBillStatus.published);
          final expired = list.where((b) => b.status == MessBillStatus.expired).toList();
          return ScreenList(
            gap: 14,
            bottomPadding: 96,
            onRefresh: () async => ref.invalidate(messBillsProvider),
            children: [
              InfoCallout(message: '$rule Published bills are locked.', icon: Icons.event_available_outlined),
              for (final bill in drafts)
                AppCard(
                  lifted: true,
                  borderColor: p.primaryTint,
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [Expanded(child: Text(bill.title.toUpperCase(), style: t.overline)), const StatusBadge(label: 'Draft', tone: Tone.neutral)]),
                      const SizedBox(height: 8),
                      Text.rich(TextSpan(children: [
                        TextSpan(text: bill.amount.asRupees, style: t.number.copyWith(fontSize: 34)),
                        TextSpan(text: '   due ${AppDates.dayMonth(bill.lastDate)}', style: t.small),
                      ])),
                      const SizedBox(height: 6),
                      Text(
                        bill.canEdit
                            ? 'Only you can see drafts. Publish to show it to every student.'
                            : "This month has passed, so the draft can't be edited or published. Delete it if you don't need it.",
                        style: t.small,
                      ),
                      const SizedBox(height: 14),
                      Row(children: [
                        if (bill.canDelete)
                          AppIconButton(
                            icon: Icons.delete_outline_rounded,
                            tooltip: 'Delete draft',
                            color: p.dangerInk,
                            onPressed: () => _delete(context, ref, bill),
                          ),
                        if (bill.canEdit) ...[
                          const SizedBox(width: 8),
                          Expanded(child: AppButton(label: 'Edit', variant: ButtonVariant.outline, compact: true, onPressed: () => _openForm(context, ref, list, existing: bill))),
                        ],
                        if (bill.canPublish) ...[
                          const SizedBox(width: 8),
                          Expanded(flex: 2, child: AppButton(label: 'Publish', compact: true, onPressed: () => _publish(context, ref, bill))),
                        ],
                      ]),
                    ],
                  ),
                ),
              for (final bill in published)
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [Expanded(child: Text(bill.title.toUpperCase(), style: t.overline)), const StatusBadge(label: 'Published', tone: Tone.success)]),
                      const SizedBox(height: 8),
                      Text.rich(TextSpan(children: [
                        TextSpan(text: bill.amount.asRupees, style: t.number.copyWith(fontSize: 28)),
                        TextSpan(text: '   due ${AppDates.dayMonth(bill.lastDate)}', style: t.small),
                      ])),
                    ],
                  ),
                ),
              if (expired.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SectionHeader(title: 'Earlier'),
                    const SizedBox(height: 8),
                    GroupedCard(children: [
                      for (final bill in expired)
                        ListTile(
                          leading: Container(
                            width: 46,
                            height: 46,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: p.neutralSoft, borderRadius: BorderRadius.circular(14)),
                            child: Text(AppDates.shortMonth(bill.monthDate), style: t.caption.copyWith(fontWeight: FontWeight.w800, color: p.inkSoft)),
                          ),
                          title: Text(bill.title, style: t.label),
                          subtitle: Text('${bill.amount.asRupees} · due ${AppDates.dayMonth(bill.lastDate)}', style: t.small),
                          trailing: const StatusBadge(label: 'Expired', tone: Tone.neutral),
                        ),
                    ]),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

class _BillForm extends ConsumerStatefulWidget {
  const _BillForm({this.existing, this.takenMonths = const {}});

  final MessBill? existing;

  /// Months that already have another bill.
  final Set<BillMonth> takenMonths;

  @override
  ConsumerState<_BillForm> createState() => _BillFormState();
}

class _BillFormState extends ConsumerState<_BillForm> {
  final _allowed = allowedBillMonths();
  late BillMonth _month = widget.existing?.billMonth ??
      _allowed.firstWhere((m) => !widget.takenMonths.contains(m), orElse: () => _allowed.last);
  late final _amount = TextEditingController(text: widget.existing == null ? '' : widget.existing!.amount.toStringAsFixed(0));
  late DateTime _lastDate = widget.existing?.lastDate ?? _defaultLastDate(_month);
  bool _saving = false;
  String? _error;

  /// The earliest last date allowed: today, or the 1st of the bill's month.
  DateTime _firstLastDate(BillMonth m) {
    final today = AppDates.todayIst();
    final monthStart = DateTime(m.year, m.month);
    return monthStart.isAfter(today) ? monthStart : today;
  }

  /// The 10th of the month, unless that's already gone.
  DateTime _defaultLastDate(BillMonth m) {
    final tenth = DateTime(m.year, m.month, 10);
    final first = _firstLastDate(m);
    return tenth.isBefore(first) ? first : tenth;
  }

  void _pickMonth(BillMonth m) {
    setState(() {
      _month = m;
      _error = null;
      if (_lastDate.isBefore(_firstLastDate(m))) _lastDate = _defaultLastDate(m);
    });
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(saveMessBillProvider)(
        MessBillDraft(month: _month.month, year: _month.year, amount: double.tryParse(_amount.text) ?? 0, lastDate: _lastDate),
        id: widget.existing?.id,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on Object catch (e) {
      if (mounted) setState(() => _error = toAppException(e).message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final firstDate = _firstLastDate(_month);
    // Up to the end of the month after the bill's month.
    final lastDate = DateTime(_month.year, _month.month + 2, 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.existing == null ? 'New mess bill' : 'Edit ${widget.existing!.title}', style: t.title.copyWith(fontSize: 22)),
        const SizedBox(height: 4),
        Text('Bills can be set for this month and next month only.', style: t.small),
        const SizedBox(height: 18),
        LabeledField(
          label: 'Month',
          child: Row(
            children: [
              for (var i = 0; i < _allowed.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(
                  child: _MonthOption(
                    title: billMonthLabel(_allowed[i]),
                    caption: widget.takenMonths.contains(_allowed[i]) ? 'Bill already exists' : (i == 0 ? 'This month' : 'Next month'),
                    selected: _month == _allowed[i],
                    enabled: !widget.takenMonths.contains(_allowed[i]),
                    onTap: () => _pickMonth(_allowed[i]),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        AppTextField(
          label: 'Amount (₹)',
          controller: _amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
          prefixIcon: Icons.currency_rupee_rounded,
        ),
        const SizedBox(height: 14),
        LabeledField(
          label: 'Last date to pay',
          child: OutlinedButton.icon(
            onPressed: () async {
              final initial = _lastDate.isBefore(firstDate) ? firstDate : (_lastDate.isAfter(lastDate) ? lastDate : _lastDate);
              final picked = await showDatePicker(
                context: context,
                initialDate: initial,
                firstDate: firstDate,
                lastDate: lastDate,
              );
              if (picked != null) setState(() => _lastDate = picked);
            },
            icon: const Icon(Icons.calendar_today_rounded, size: 18),
            label: Text(AppDates.fullDate(_lastDate)),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 14),
          InfoCallout(message: _error!, tone: Tone.danger, icon: Icons.error_outline_rounded),
        ],
        const SizedBox(height: 20),
        AppButton(label: widget.existing == null ? 'Save as draft' : 'Save changes', expand: true, loading: _saving, onPressed: _save),
      ],
    );
  }
}

class _MonthOption extends StatelessWidget {
  const _MonthOption({
    required this.title,
    required this.caption,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String title;
  final String caption;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final p = context.colors;
    final radius = BorderRadius.circular(14);
    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      child: Material(
        color: selected ? p.primaryTint : p.surface,
        borderRadius: radius,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: radius,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: selected ? p.primary : p.line, width: selected ? 1.6 : 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: t.label.copyWith(color: enabled ? p.ink : p.subtle)),
                const SizedBox(height: 2),
                Text(caption, style: t.caption.copyWith(color: enabled ? (selected ? p.primary : p.muted) : p.subtle)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
