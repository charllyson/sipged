import 'package:flutter/material.dart';
import 'package:sisged/_utils/date_utils.dart';
import 'package:sisged/_widgets/table/simple_table_changed.dart';

import '../../../../../_datas/documents/contracts/contracts/contract_data.dart';
import '../../../../../_datas/sectors/financial/payments/revisions/payments_revisions_data.dart';
import '../../../../../_widgets/formats/format_field.dart';
import '../../../../documents/footer_rows_generic.dart';

class PaymentRevisionTableSection extends StatelessWidget {
  final void Function(PaymentsRevisionsData) onTapItem;
  final void Function(String additiveId) onDelete;
  final List<PaymentsRevisionsData> paymentsRevisionsData;
  final PaymentsRevisionsData? selectedPaymentsRevisionsData;
  final ContractData? contractData;

  final double valorInicial;
  final double valorAditivos;
  final double valorTotal;
  final double saldo;

  const PaymentRevisionTableSection({
    super.key,
    required this.onTapItem,
    required this.onDelete,
    required this.paymentsRevisionsData,
    required this.selectedPaymentsRevisionsData,
    required this.valorInicial,
    required this.valorAditivos,
    required this.valorTotal,
    required this.saldo,
    this.contractData,
  });

  @override
  Widget build(BuildContext context) {
    final totalReports = paymentsRevisionsData.fold<double>(0.0, (prev, item) => prev + (item.valuePaymentRevision ?? 0.0),);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              const SizedBox(width: 12),
              ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: SimpleTableChanged<PaymentsRevisionsData>(
                  constraints: constraints,
                  listData: paymentsRevisionsData,
                  columnTitles: [
                    'ORDEM',
                    'Nº PROCESSO',
                    'DATA DO PAGAMENTO DA MEDIÇÃO',
                    'VALOR DO PAGAMENTO DA MEDIÇÃO',
                  ],
                  selectedItem: selectedPaymentsRevisionsData,
                  columnGetters: [
                        (a) => '${a.orderPaymentRevision ?? '-'}',
                        (a) => a.processPaymentRevision ?? '-',
                        (a) => convertDateTimeToDDMMYYYY(a.datePaymentRevision ?? DateTime.now()),
                        (a) => priceToString(a.valuePaymentRevision),
                  ],
                  onTapItem: onTapItem,
                  onDelete: (item) => onDelete(item.idRevisionPayment!),
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
                        value: totalReports,
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
