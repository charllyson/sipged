// lib/screens/modules/contracts/measurement/adjustment/payment/adjustment_payment_summary_text.dart

import 'package:flutter/material.dart';

import 'package:sipged/_utils/formatters/sipged_format_money.dart';

class AdjustmentPaymentSummaryText extends StatelessWidget {
  const AdjustmentPaymentSummaryText({
    super.key,
    required this.totalAdjustment,
    required this.totalPaid,
    required this.totalRetentions,
  });

  final double totalAdjustment;
  final double totalPaid;
  final double totalRetentions;

  double _roundMoney(double value) {
    if (!value.isFinite) return 0.0;

    final rounded = (value * 100).roundToDouble() / 100;

    if (rounded == 0.0) return 0.0;

    return rounded;
  }

  @override
  Widget build(BuildContext context) {
    final paid = _roundMoney(totalPaid);
    final retentions = _roundMoney(totalRetentions);
    final total = _roundMoney(totalAdjustment);
    final balance = _roundMoney(total - paid - retentions);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Wrap(
        spacing: 18,
        runSpacing: 8,
        children: [
          _Item(
            label: 'Valor do reajuste',
            value: SipGedFormatMoney.doubleToText(total),
          ),
          _Item(
            label: 'Pago',
            value: SipGedFormatMoney.doubleToText(paid),
          ),
          _Item(
            label: 'Retenções',
            value: SipGedFormatMoney.doubleToText(retentions),
          ),
          _Item(
            label: 'Saldo',
            value: SipGedFormatMoney.doubleToText(balance),
            strong: true,
            color: balance < 0 ? Colors.red : const Color(0xFF091D68),
          ),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.label,
    required this.value,
    this.strong = false,
    this.color,
  });

  final String label;
  final String value;
  final bool strong;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: strong ? FontWeight.w800 : FontWeight.w700,
            color: color ?? const Color(0xFF111827),
          ),
        ),
      ],
    );
  }
}