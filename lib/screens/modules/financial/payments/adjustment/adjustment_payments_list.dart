import 'package:flutter/material.dart';

import 'package:sipged/_blocs/modules/financial/payments/adjustment/adjustment_paid_data.dart';
import 'package:sipged/_blocs/modules/financial/payments/adjustment/adjustment_paid_repository.dart';
import 'package:sipged/_utils/theme/sipged_theme.dart';

import 'adjustment_payment_tile.dart';

class AdjustmentPaymentsList extends StatelessWidget {
  const AdjustmentPaymentsList({
    super.key,
    required this.payments,
    required this.repository,
    this.selected,
    this.onTap,
    this.onDelete,
  });

  final List<AdjustmentPaidData> payments;
  final AdjustmentPaidRepository repository;
  final AdjustmentPaidData? selected;
  final void Function(AdjustmentPaidData payment)? onTap;
  final void Function(AdjustmentPaidData payment)? onDelete;

  String _idOf(AdjustmentPaidData? item) {
    return item?.id?.trim() ?? '';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
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
          'Nenhum pagamento cadastrado para este reajuste.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: SipGedTheme.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    final selectedId = _idOf(selected);

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
            AdjustmentPaymentTile(
              payment: payments[index],
              selected: selectedId.isNotEmpty && selectedId == _idOf(payments[index]),
              dateText: _formatDate(payments[index].paymentDate),
              totalRetencoes: repository.retentionsValue(payments[index]),
              totalPagamento: repository.totalPaymentValue(payments[index]),
              onTap: () => onTap?.call(payments[index]),
              onDelete: onDelete == null
                  ? null
                  : () => onDelete?.call(payments[index]),
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