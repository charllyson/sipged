import 'package:flutter/material.dart';
import 'package:siged/_utils/date_utils.dart';
import 'package:siged/_widgets/table/simple/simple_table_changed.dart';

import 'package:siged/_blocs/documents/contracts/contracts/contract_data.dart';
import 'package:siged/_blocs/sectors/financial/payments/adjustment/payments_adjustments_data.dart';
import 'package:siged/_utils/formats/format_field.dart';
import 'package:siged/_widgets/totalTableRows/footer_rows_generic.dart';

class PaymentAdjustmentTableSection extends StatelessWidget {
  final void Function(PaymentsAdjustmentsData) onTapItem;
  final void Function(String additiveId) onDelete;
  final List<PaymentsAdjustmentsData> paymentAdjustmentData;
  final PaymentsAdjustmentsData? selectedPaymentAdjustment;
  final ContractData? contractData;

  final double valorInicial;
  final double valorAditivos;
  final double valorTotal;
  final double saldo;

  const PaymentAdjustmentTableSection({
    super.key,
    required this.onTapItem,
    required this.onDelete,
    required this.paymentAdjustmentData,
    required this.selectedPaymentAdjustment,
    required this.valorInicial,
    required this.valorAditivos,
    required this.valorTotal,
    required this.saldo,
    this.contractData,
  });

  @override
  Widget build(BuildContext context) {
    final totalAdjustments = paymentAdjustmentData.fold<double>(
      0.0,
          (prev, item) => prev + (item.valuePaymentAdjustment ?? 0.0),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              const SizedBox(width: 12),
              ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: SimpleTableChanged<PaymentsAdjustmentsData>(
                  constraints: constraints,
                  listData: paymentAdjustmentData,
                  columnTitles: const [
                    'ORDEM DO REAJUSTE',
                    'Nº PROCESSO',
                    'DATA DO PAGAMENTO DO REAJUSTE',
                    'VALOR DO PAGAMENTO DO REAJUSTE',
                  ],
                  selectedItem: selectedPaymentAdjustment,
                  columnGetters: [
                        (a) => '${a.orderPaymentAdjustment ?? '-'}',
                        (a) => a.processPaymentAdjustment ?? '-',
                        (a) => convertDateTimeToDDMMYYYY(
                      a.datePaymentAdjustment ?? DateTime.now(),
                    ),
                        (a) => priceToString(a.valuePaymentAdjustment),
                  ],
                  onTapItem: onTapItem,
                  onDelete: (item) => onDelete(item.idPaymentAdjustment!),
                  columnWidths: const [100, 200, 150, 200],
                  columnTextAligns: const [
                    TextAlign.center,
                    TextAlign.center,
                    TextAlign.center,
                    TextAlign.center,
                  ],
                  footerRows: FooterRowsGeneric(
                    mostrarColunaExcluir: true,
                    linhas: [
                      FooterResumo(
                        label: 'TOTAL DOS PAGAMENTOS',
                        value: totalAdjustments,
                        backgroundColor: Colors.grey.shade200,
                      ),
                      FooterResumo.empty(),
                      FooterResumo(
                        label: 'VALOR CONTRATADO',
                        value: valorInicial,
                        backgroundColor: Colors.white,
                        fontWeight: FontWeight.normal,
                      ),
                      FooterResumo(
                        label: 'VALOR DOS ADITIVOS',
                        value: valorAditivos,
                        backgroundColor: Colors.white,
                        fontWeight: FontWeight.normal,
                      ),
                      FooterResumo(
                        label: 'VALOR CONTRATADO + ADITIVOS',
                        value: valorTotal,
                        backgroundColor: Colors.white,
                        fontWeight: FontWeight.normal,
                      ),
                      FooterResumo(
                        label: 'SALDO DO CONTRATO',
                        value: saldo,
                        backgroundColor: Colors.blue.shade100,
                      ),
                    ],
                  ).rows,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
