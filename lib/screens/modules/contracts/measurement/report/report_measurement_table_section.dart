import 'package:flutter/material.dart';
import 'package:siged/_utils/converters/converters_utils.dart';
import 'package:siged/_widgets/table/simple/simple_table_changed.dart';
import 'package:siged/_utils/formats/format_field.dart';
import 'package:siged/_blocs/modules/contracts/_process/process_data.dart';
import 'package:siged/_blocs/modules/contracts/measurement/report/report_measurement_data.dart';
import 'package:siged/_widgets/table/totalTableRows/footer_rows_generic.dart';

class ReportMeasurementTableSection extends StatelessWidget {
  final void Function(ReportMeasurementData) onTapItem;
  final void Function(String additiveId) onDelete;
  final List<ReportMeasurementData> measurementsData;
  final ReportMeasurementData? selectedMeasurement;
  final ProcessData? contractData;

  final double valorInicial;
  final double valorAditivos;
  final double valorTotal;
  final double saldo;

  const ReportMeasurementTableSection({
    super.key,
    required this.onTapItem,
    required this.onDelete,
    required this.measurementsData,
    required this.selectedMeasurement,
    required this.valorInicial,
    required this.valorAditivos,
    required this.valorTotal,
    required this.saldo,
    this.contractData,
  });

  @override
  Widget build(BuildContext context) {
    final totalReports = measurementsData.fold<double>(0.0, (prev, item) => prev + (item.value ?? 0.0),);
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              const SizedBox(width: 12),
              ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: SimpleTableChanged<ReportMeasurementData>(
                  constraints: constraints,
                  listData: measurementsData,
                  columnTitles: const [
                    'ORDEM',
                    'Nº PROCESSO',
                    'DATA DA MEDIÇÃO',
                    'VALOR DA MEDIÇÃO',
                  ],
                  selectedItem: selectedMeasurement,
                  columnGetters: [
                        (a) => '${a.order ?? '-'}',
                        (a) => a.numberprocess ?? '-',
                        (a) => dateTimeToDDMMYYYY(a.date ?? DateTime.now()),
                        (a) => priceToString(a.value),
                  ],
                  onTapItem: onTapItem,
                  onDelete: (item) => onDelete(item.id!),

                  // ✅ agora com 5 larguras (4 colunas + coluna APAGAR)
                  columnWidths: const [100, 200, 150, 200, 56],

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
                        label: 'TOTAL DOS BOLETINS',
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
