// lib/screens/modules/financial/payments/report/report_paid_list.dart

import 'package:flutter/material.dart';

import 'package:sipged/_blocs/modules/financial/payments/report/report_paid_data.dart';
import 'package:sipged/_utils/theme/sipged_theme.dart';
import 'package:sipged/screens/modules/financial/payments/report/report_paid_tile.dart';

class PaymentsList extends StatelessWidget {
  const PaymentsList({
    super.key,
    required this.payments,
    required this.selected,
    required this.onSelect,
    required this.onDelete,
  });

  final List<ReportPaidData> payments;
  final ReportPaidData? selected;
  final ValueChanged<ReportPaidData> onSelect;
  final ValueChanged<ReportPaidData>? onDelete;

  String _formatDate(DateTime? date) {
    if (date == null) return '-';

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  double _roundMoney(double value) {
    if (!value.isFinite) return 0.0;

    final rounded = (value * 100).roundToDouble() / 100;

    if (rounded == 0.0) return 0.0;

    return rounded;
  }

  double _positive(double? value) {
    final v = value ?? 0.0;

    if (!v.isFinite || v <= 0) return 0.0;

    return _roundMoney(v);
  }

  double _totalRetencoes(ReportPaidData payment) {
    return _roundMoney(
      _positive(payment.inssPaymentValue) +
          _positive(payment.irpfPaymentValue) +
          _positive(payment.issPaymentValue),
    );
  }

  double _totalPagamento(ReportPaidData payment) {
    return _roundMoney(
      _positive(payment.paymentValue) + _totalRetencoes(payment),
    );
  }

  String _idOf(ReportPaidData item) {
    return item.id?.trim() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    if (payments.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: SipGedTheme.surfaceLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: SipGedTheme.blackAlpha(0.06),
          ),
        ),
        child: Text(
          'Nenhum pagamento cadastrado para esta medição.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: SipGedTheme.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    final selectedId = selected == null ? '' : _idOf(selected!);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: SipGedTheme.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: SipGedTheme.blackAlpha(0.08),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int index = 0; index < payments.length; index++) ...[
            Builder(
              builder: (context) {
                final payment = payments[index];
                final paymentId = _idOf(payment);

                return PaymentTile(
                  payment: payment,
                  selected: selectedId.isNotEmpty && selectedId == paymentId,
                  dateText: _formatDate(payment.paymentDate),
                  totalRetencoes: _totalRetencoes(payment),
                  totalPagamento: _totalPagamento(payment),
                  onTap: () => onSelect(payment),
                  onDelete: onDelete == null
                      ? null
                      : () => onDelete?.call(payment),
                );
              },
            ),
            if (index < payments.length - 1)
              Divider(
                height: 1,
                color: SipGedTheme.blackAlpha(0.06),
              ),
          ],
        ],
      ),
    );
  }
}