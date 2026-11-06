import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/app_dates.dart';
import '../../../../core/utils/text_utils.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../common/mess_bills/mess_bill.dart';
import '../../home/presentation/student_home_providers.dart';
import '../domain/student_fees_repository.dart';
import 'fees_providers.dart';
import 'widgets/pay_at_office_sheet.dart';

class FeesScreen extends ConsumerWidget {
  const FeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bills = ref.watch(myBillsProvider);
    final due = ref.watch(dueBillProvider);
    final hostelName = ref.watch(studentHomeProvider).value?.hostel.name;
    return Scaffold(
      appBar: AppTopBar(title: 'Mess fees', subtitle: hostelName == null ? null : '$hostelName mess'),
      body: AsyncValueView(
        value: bills,
        onRetry: () => ref.invalidate(myBillsProvider),
        data: (result) {
          final info = result.paymentInfo;
          final others = result.bills.where((b) => b != due).toList();
          void pay(MessBill bill) => showPayAtOfficeSheet(context, info: info, bill: bill);
          return ScreenList(
            onRefresh: () async => ref.invalidate(myBillsProvider),
            children: [
              if (due != null) _DueCard(bill: due, onPay: () => pay(due)) else _NothingDueCard(hasBills: result.bills.isNotEmpty),
              if (others.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SectionHeader(title: due == null ? 'Bills' : 'Earlier bills'),
                    const SizedBox(height: 10),
                    GroupedCard(children: [
                      for (final b in others) _BillRow(bill: b, onTap: b.isPaid ? null : () => pay(b)),
                    ]),
                  ],
                ),
              _HowToPayCard(info: info),
            ],
          );
        },
      ),
    );
  }
}

class _DueCard extends StatelessWidget {
  const _DueCard({required this.bill, required this.onPay});

  final MessBill bill;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final p = context.colors;
    final daysLeft = bill.lastDate.difference(AppDates.todayIst()).inDays;
    return AppCard(
      lifted: true,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DottedCover(color: p.accent, height: 10),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(child: Text(bill.title.toUpperCase(), style: t.overline)),
                  StatusBadge(
                    label: daysLeft <= 0 ? 'Last day today' : (daysLeft == 1 ? '1 day left' : '$daysLeft days left'),
                    tone: daysLeft <= 3 ? Tone.warning : Tone.neutral,
                  ),
                ]),
                const SizedBox(height: 16),
                Text(bill.amount.asRupees, style: t.number.copyWith(fontSize: 44)),
                const SizedBox(height: 8),
                Text.rich(
                  TextSpan(children: [
                    const TextSpan(text: 'Last date '),
                    TextSpan(text: AppDates.fullDate(bill.lastDate), style: t.small.copyWith(color: p.ink, fontWeight: FontWeight.w700)),
                  ]),
                  style: t.small,
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: 'Pay ${bill.amount.asRupees}',
                  variant: ButtonVariant.accent,
                  expand: true,
                  // TODO(api): online payment needs a payment gateway order API (see docs/API_GAPS.md).
                  onPressed: onPay,
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, size: 15, color: p.muted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text("Already paid at the office? Office payments don't show in the app yet, so keep your receipt.", style: t.small),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NothingDueCard extends StatelessWidget {
  const _NothingDueCard({required this.hasBills});

  final bool hasBills;

  @override
  Widget build(BuildContext context) {
    final p = context.colors;
    return AppCard(
      lifted: true,
      padding: const EdgeInsets.all(22),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(color: p.primaryTint, shape: BoxShape.circle),
            child: Icon(Icons.receipt_long_outlined, size: 28, color: p.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(hasBills ? 'Nothing due right now' : 'No mess bills yet', style: context.text.heading),
                Text("New bills show up here as soon as the hostel office publishes them.", style: context.text.small),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HowToPayCard extends StatelessWidget {
  const _HowToPayCard({required this.info});

  final MessFeePaymentInfo info;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final p = context.colors;
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const IconTile(icon: Icons.storefront_outlined, tone: Tone.accent),
            const SizedBox(width: 12),
            Expanded(child: Text('How to pay', style: t.label)),
          ]),
          const SizedBox(height: 10),
          Text(info.message, style: t.small),
          const SizedBox(height: 12),
          for (final h in info.officeHours)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(children: [
                Icon(Icons.schedule_rounded, size: 16, color: p.muted),
                const SizedBox(width: 8),
                Expanded(child: Text(h.label, style: t.small.copyWith(color: p.ink))),
                Text('${AppDates.clockLabel(h.opensAt)} – ${AppDates.clockLabel(h.closesAt)}', style: t.small.copyWith(color: p.ink, fontWeight: FontWeight.w700)),
              ]),
            ),
        ],
      ),
    );
  }
}

class _BillRow extends StatelessWidget {
  const _BillRow({required this.bill, this.onTap});

  final MessBill bill;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final p = context.colors;
    final lastDatePassed = bill.lastDate.isBefore(AppDates.todayIst());
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: bill.isPaid ? p.successSoft : p.neutralSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                AppDates.shortMonth(bill.monthDate),
                style: t.caption.copyWith(fontWeight: FontWeight.w800, color: bill.isPaid ? p.successInk : p.inkSoft),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(bill.title, style: t.label),
                  Text(
                    bill.isPaid
                        ? 'Paid on ${AppDates.dayMonth(AppDates.ist(bill.paidAt!))}'
                        : '${lastDatePassed ? 'Last date was' : 'Last date'} ${AppDates.dayMonth(bill.lastDate)}',
                    style: t.small,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(bill.amount.asRupees, style: t.label),
                if (bill.isPaid) ...[
                  const SizedBox(height: 4),
                  const StatusBadge(label: 'Paid', tone: Tone.success, small: true),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
