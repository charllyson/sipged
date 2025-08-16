import 'package:flutter/material.dart';
import 'package:sisged/_utils/date_utils.dart';
import 'package:sisged/_widgets/table/simple_table_changed.dart';

import '../../../../../_datas/documents/contracts/contracts/contracts_data.dart';
import '../../../../../_datas/documents/measurement/measurement_data.dart';
import '../../../../../_datas/sectors/financial/payments/payments_reports_data.dart';
import '../../../../../_widgets/formats/format_field.dart';
import '../../../../documents/footer_rows_generic.dart';

class PaymentReportTableSection extends StatelessWidget {
  final void Function(PaymentsReportData) onTapItem;
  final void Function(String additiveId) onDelete;
  final List<PaymentsReportData> paymentReportData;
  final List<ReportData> reportData;
  final PaymentsReportData? selectedPaymentReport;
  final ContractData? contractData;

  final double valorInicial;
  final double valorAditivos;
  final double valorTotal;
  final double saldo;

  const PaymentReportTableSection({
    super.key,
    required this.onTapItem,
    required this.onDelete,
    required this.paymentReportData,
    required this.reportData,
    required this.selectedPaymentReport,
    required this.valorInicial,
    required this.valorAditivos,
    required this.valorTotal,
    required this.saldo,
    this.contractData,
  });

  @override
  Widget build(BuildContext context) {
    final totalPaymentReports = paymentReportData.fold<double>(
      0.0,
      (prev, item) => prev + (item.valuePaymentReport ?? 0.0),
    );
    final totalReports = reportData.fold<double>(
      0.0,
      (prev, item) => prev + (item.valueReportMeasurement ?? 0.0),
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
                child: SimpleTableChanged<PaymentsReportData>(
                  constraints: constraints,
                  listData: paymentReportData,
                  columnTitles: [
                    'ORDEM',
                    'Nº PROCESSO DA MEDIÇÃO',
                    'DATA DO PAGAMENTO DO BOLETIM DE MEDIÇÃO',
                    'VALOR DO PAGAMENTO DO BOLETIM DE MEDIÇÃO',
                  ],
                  selectedItem: selectedPaymentReport,
                  columnGetters: [
                    (a) => '${a.orderPaymentReport ?? '-'}',
                    (a) => a.processPaymentReport ?? '-',
                    (a) => convertDateTimeToDDMMYYYY(
                      a.datePaymentReport ?? DateTime.now(),
                    ),
                    (a) => priceToString(a.valuePaymentReport),
                  ],
                  onTapItem: onTapItem,
                  onDelete: (item) => onDelete(item.idPaymentReport!),
                  columnWidths: const [100, 200, 150, 200],
                  columnTextAligns: const [
                    TextAlign.center,
                    TextAlign.center,
                    TextAlign.center,
                    TextAlign.center,
                  ],
                  footerRows:
                      FooterRowsGeneric(
                        mostrarColunaExcluir: true,
                        linhas: [
                          FooterResumo(
                            label: 'TOTAL DOS PAGAMENTOS',
                            value: totalPaymentReports,
                            backgroundColor: Colors.grey.shade200,
                          ),
                          FooterResumo.empty(),
                          FooterResumo(
                            label: 'TOTAL DAS MEDIÇÕES',
                            value: totalReports,
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
    ); /*FutureBuilder<List<PaymentsData>>(
        future: futurePayments,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingProgress();
          } else if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Text('Nenhum pagamento encontrado.');
          }
          return LayoutBuilder(
            builder: (context, constraints) {
              return TableChanged<PaymentsData>(
                constraints: constraints,
                listData: snapshot.data!,
                columnTitles: [
                  'ORDEM',
                  'Nº PROCESSO',
                  'DATA DO PAGAMENTO DA MEDIÇÃO',
                  'VALOR DO PAGAMENTO DA MEDIÇÃO',
                ],
                columnGetters: [
                      (a) => '${a.orderPaymentMeasurement ?? '-'}',
                      (a) => '${a.numberProcessPaymentMeasurement ?? '-'}',
                      (a) => convertDateTimeToDDMMYYYY(a.datePaymentMeasurement ?? DateTime.now()),
                      (a) => priceToString(a.valuePaymentMeasurement),
                ],
                onTapItem: (item) => onTapItem(item),
                onDelete: (item) => onDelete(item.idPaymentMeasurement!),
                columnWidths: const [
                  80,
                  200,
                  120,
                  140,
                ],
                columnTextAligns: const [
                  TextAlign.center,
                  TextAlign.center,
                  TextAlign.center,
                  TextAlign.center,
                ],
              );
            },
          );
        }
    );*/
  }
}
