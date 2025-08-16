import 'package:flutter/material.dart';
import 'package:sisged/_utils/date_utils.dart';
import 'package:sisged/_widgets/table/simple_table_changed.dart';
import '../../../../../_widgets/formats/format_field.dart';
import '../../../../_datas/documents/contracts/contracts/contracts_data.dart';
import '../../../../_datas/documents/measurement/measurement_data.dart';
import '../../footer_rows_generic.dart';

class RevisionMeasurementTableSection extends StatelessWidget {
  final void Function(ReportData) onTapItem;
  final void Function(String additiveId) onDelete;
  final List<ReportData> measurementsData;
  final ReportData? selectedMeasurement;
  final ContractData? contractData;

  final double valorInicial;
  final double valorAditivos;
  final double valorTotal;
  final double saldo;

  const RevisionMeasurementTableSection({
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
    final totalReports = measurementsData.fold<double>(0.0, (prev, item) => prev + (item.valueRevisionMeasurement ?? 0.0),);
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              const SizedBox(width: 12),
              ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: SimpleTableChanged<ReportData>(
                  constraints: constraints,
                  listData: measurementsData,
                  columnTitles: [
                    'ORDEM',
                    'Nº PROCESSO',
                    'DATA DA MEDIÇÃO',
                    'VALOR DA MEDIÇÃO',
                  ],
                  selectedItem: selectedMeasurement,
                  columnGetters: [
                        (a) => '${a.orderRevisionMeasurement ?? '-'}',
                        (a) => a.numberRevisionProcessMeasurement ?? '-',
                        (a) => convertDateTimeToDDMMYYYY(a.dateRevisionMeasurement ?? DateTime.now()),
                        (a) => priceToString(a.valueRevisionMeasurement),
                  ],
                  onTapItem: onTapItem,
                  onDelete: (item) => onDelete(item.idRevisionMeasurement!),
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
