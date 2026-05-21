// lib/screens/modules/financial/payments/report/report_paid_tile.dart

import 'package:flutter/material.dart';

import 'package:sipged/_blocs/modules/financial/payments/report/report_paid_data.dart';
import 'package:sipged/_utils/formatters/sipged_format_money.dart';
import 'package:sipged/_utils/theme/sipged_theme.dart';

class PaymentTile extends StatelessWidget {
  const PaymentTile({
    super.key,
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
    final backgroundColor = SipGedTheme.surfaceLight;

    final borderColor = selected
        ? SipGedTheme.secondaryColor.withValues(alpha: 0.55)
        : SipGedTheme.blackAlpha(0.045);

    final iconColor =
    selected ? SipGedTheme.secondaryColor : SipGedTheme.textMuted;

    final iconBackground = selected
        ? SipGedTheme.secondaryColor.withValues(alpha: 0.08)
        : SipGedTheme.blackAlpha(0.035);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(selected ? 8 : 0),
        border: Border.all(
          color: borderColor,
          width: selected ? 1.4 : 1,
        ),
        boxShadow: selected
            ? [
          BoxShadow(
            color: SipGedTheme.blackAlpha(0.08),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ]
            : const [],
      ),
      child: Material(
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: IntrinsicHeight(
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  width: selected ? 5 : 0,
                  decoration: BoxDecoration(
                    color: SipGedTheme.secondaryColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(14),
                      bottomLeft: Radius.circular(14),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: selected ? 14 : 12,
                      vertical: selected ? 12 : 10,
                    ),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOutCubic,
                          width: selected ? 38 : 34,
                          height: selected ? 38 : 34,
                          decoration: BoxDecoration(
                            color: iconBackground,
                            shape: BoxShape.circle,
                            border: selected
                                ? Border.all(
                              color: SipGedTheme.secondaryColor
                                  .withValues(alpha: 0.28),
                            )
                                : null,
                          ),
                          child: Icon(
                            Icons.payments_outlined,
                            size: selected ? 21 : 19,
                            color: iconColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Wrap(
                            spacing: 14,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                payment.fundingSourceLabel ??
                                    'Fonte não informada',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: selected
                                      ? SipGedTheme.secondaryColor
                                      : SipGedTheme.textDark,
                                ),
                              ),
                              Text(
                                dateText,
                                style: const TextStyle(
                                  color: SipGedTheme.textMuted,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                SipGedFormatMoney.doubleToText(totalPagamento),
                                style: TextStyle(
                                  color: selected
                                      ? SipGedTheme.secondaryColor
                                      : SipGedTheme.textDark,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              if (totalRetencoes > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: SipGedTheme.secondaryColor
                                        .withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: SipGedTheme.secondaryColor
                                          .withValues(alpha: 0.14),
                                    ),
                                  ),
                                  child: Text(
                                    'Retenções: ${SipGedFormatMoney.doubleToText(totalRetencoes)}',
                                    style: const TextStyle(
                                      color: SipGedTheme.secondaryColor,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (onDelete != null) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: 'Apagar pagamento',
                            onPressed: onDelete,
                            style: IconButton.styleFrom(
                              backgroundColor: selected
                                  ? SipGedTheme.danger.withValues(alpha: 0.08)
                                  : Colors.transparent,
                            ),
                            icon: const Icon(
                              Icons.delete_outline,
                              color: SipGedTheme.danger,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}