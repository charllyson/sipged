import 'package:flutter/material.dart';

import 'package:sipged/_blocs/modules/financial/payments/revision/revision_paid_data.dart';
import 'package:sipged/_blocs/modules/financial/payments/revision/revision_paid_repository.dart';
import 'package:sipged/_utils/theme/sipged_theme.dart';

import 'revision_payment_tile.dart';

class RevisionPaymentsList extends StatelessWidget {
  const RevisionPaymentsList({
    super.key,
    required this.payments,
    required this.repository,
    this.selected,
    this.onTap,
    this.onDelete,
  });

  final List<RevisionPaidData> payments;
  final RevisionPaidRepository repository;
  final RevisionPaidData? selected;
  final void Function(RevisionPaidData payment)? onTap;
  final void Function(RevisionPaidData payment)? onDelete;

  String _idOf(RevisionPaidData item) {
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
          'Nenhum pagamento cadastrado para esta revisão.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: SipGedTheme.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

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

                final selectedId = selected == null ? '' : _idOf(selected!);
                final paymentId = _idOf(payment);

                return RevisionPaymentTile(
                  payment: payment,
                  selected: selectedId.isNotEmpty && selectedId == paymentId,
                  totalRetencoes: repository.retentionsValue(payment),
                  totalPagamento: repository.totalPaymentValue(payment),
                  onTap: () => onTap?.call(payment),
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