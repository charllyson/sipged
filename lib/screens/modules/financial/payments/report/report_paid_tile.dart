import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/financial/payments/report/report_paid_data.dart';
import 'package:sipged/_utils/formatters/sipged_format_money.dart';
import 'package:sipged/_utils/theme/sipged_theme.dart';

class PaymentTile extends StatelessWidget {
  const PaymentTile({super.key,
    required this.payment,
    required this.selected,
    required this.dateText,
    required this.totalRetencoes,
    required this.totalPagamento,
    required this.onTap,
    required this.onDelete,
  });

  final ReportPaidData payment;
  final bool selected;
  final String dateText;
  final double totalRetencoes;
  final double totalPagamento;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? SipGedTheme.secondaryColor.withValues(alpha: 0.06)
          : SipGedTheme.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          child: Row(
            children: [
              Icon(
                Icons.payments_outlined,
                size: 20,
                color:
                selected ? SipGedTheme.secondaryColor : SipGedTheme.textMuted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Wrap(
                  spacing: 14,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      payment.fundingSourceLabel ?? 'Fonte não informada',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: SipGedTheme.textDark,
                      ),
                    ),
                    Text(
                      dateText,
                      style: const TextStyle(
                        color: SipGedTheme.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      SipGedFormatMoney.doubleToText(totalPagamento),
                      style: const TextStyle(
                        color: SipGedTheme.textDark,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (totalRetencoes > 0)
                      Text(
                        'Retenções: ${SipGedFormatMoney.doubleToText(totalRetencoes)}',
                        style: const TextStyle(
                          color: SipGedTheme.secondaryColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                  ],
                ),
              ),
              if (onDelete != null)
                IconButton(
                  tooltip: 'Apagar pagamento',
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: SipGedTheme.danger,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
