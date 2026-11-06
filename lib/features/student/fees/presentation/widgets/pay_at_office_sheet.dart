import 'package:flutter/material.dart';

import '../../../../../core/utils/app_dates.dart';
import '../../../../../core/utils/text_utils.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../../common/mess_bills/mess_bill.dart';
import '../../domain/student_fees_repository.dart';

/// Shown when a student taps "Pay": online payment isn't available yet, so
/// it tells them to pay at the hostel office and when it's open.
Future<void> showPayAtOfficeSheet(BuildContext context, {required MessFeePaymentInfo info, MessBill? bill}) {
  return showAppSheet<void>(context, builder: (_) => _PayAtOfficeSheet(info: info, bill: bill));
}

class _PayAtOfficeSheet extends StatelessWidget {
  const _PayAtOfficeSheet({required this.info, this.bill});

  final MessFeePaymentInfo info;
  final MessBill? bill;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final p = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: IconTile(icon: Icons.storefront_outlined, tone: Tone.accent, size: 52),
        ),
        const SizedBox(height: 16),
        Text('Pay at the hostel office', style: t.title.copyWith(fontSize: 22)),
        const SizedBox(height: 6),
        Text(info.message, style: t.body),
        if (bill != null) ...[
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: p.accentSoft, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mess fee · ${bill!.title}', style: t.caption.copyWith(color: p.accentInk)),
                      const SizedBox(height: 2),
                      Text('Last date ${AppDates.dayMonthYear(bill!.lastDate)}', style: t.small.copyWith(color: p.accentInk)),
                    ],
                  ),
                ),
                Text(bill!.amount.asRupees, style: t.number.copyWith(fontSize: 24, color: p.accentInk)),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        Text('Office hours for payment', style: t.label),
        const SizedBox(height: 10),
        GroupedCard(children: [
          for (final h in info.officeHours)
            InfoRow(
              icon: Icons.schedule_rounded,
              label: h.label,
              value: '${AppDates.clockLabel(h.opensAt)} – ${AppDates.clockLabel(h.closesAt)}',
            ),
        ]),
        const SizedBox(height: 22),
        AppButton(label: 'Got it', expand: true, onPressed: () => Navigator.of(context).pop()),
      ],
    );
  }
}
