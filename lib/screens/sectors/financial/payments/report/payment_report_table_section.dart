import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:siged/_utils/formats/converters_utils.dart';
import 'package:siged/_widgets/table/simple/simple_table_changed.dart';
import 'package:siged/_blocs/sectors/financial/payments/report/payment_report_controller.dart';

import 'package:siged/_blocs/sectors/financial/payments/report/payments_reports_data.dart';
import 'package:siged/_utils/formats/format_field.dart';
import 'package:siged/_widgets/table/totalTableRows/footer_rows_generic.dart';

class PaymentReportTableSection extends StatelessWidget {
  const PaymentReportTableSection({
    super.key,
    required this.reportData, // ainda pode vir de fora se precisar comparar com medições
  });

  final List<PaymentsReportData> reportData;

  @override
  Widget build(BuildContext context) {
    final c = context.watch<PaymentsReportController>();

    final paymentReportData = c.reports;
    final selectedPaymentReport = c.selected;

    // totais
    final totalPaymentReports = paymentReportData.fold<double>(
      0.0,
          (prev, item) => prev + (item.valuePaymentReport ?? 0.0),
    );
    final totalReports = reportData.fold<double>(
      0.0,
          (prev, item) => prev + (item.valuePaymentReport ?? 0.0),
    );

    final saldo = c.saldo;

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
                  selectedItem: selectedPaymentReport,
                  columnTitles: const [
                    'ORDEM',
                    'Nº PROCESSO DA MEDIÇÃO',
                    'DATA DO PAGAMENTO DO BOLETIM DE MEDIÇÃO',
                    'VALOR DO PAGAMENTO DO BOLETIM DE MEDIÇÃO',
                  ],
                  columnGetters: [
                        (a) => '${a.orderPaymentReport ?? '-'}',
                        (a) => a.processPaymentReport ?? '-',
                        (a) => dateTimeToDDMMYYYY(
                      a.datePaymentReport ?? DateTime.now(),
                    ),
                        (a) => priceToString(a.valuePaymentReport),
                  ],
                  onTapItem: (data) => c.selectRow(data),
                  onDelete: (data) async {
                    final id = data.idPaymentReport;
                    if (id == null) return;
                    await c.deleteById(id);
                  },
                  // larguras: 4 colunas + coluna de ações
                  columnWidths: const [100, 220, 260, 260, 56],
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
    );
  }
}
