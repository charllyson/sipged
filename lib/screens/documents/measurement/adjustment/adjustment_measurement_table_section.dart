import 'package:flutter/material.dart';
import 'package:siged/_blocs/documents/measurement/adjustment/adjustment_measurement_data.dart';
import 'package:siged/_utils/date_utils.dart';
import 'package:siged/_widgets/table/simple/simple_table_changed.dart';
import 'package:siged/_utils/formats/format_field.dart';
import 'package:siged/_blocs/documents/contracts/contracts/contract_data.dart';
import 'package:siged/_widgets/totalTableRows/footer_rows_generic.dart';

class AdjustmentMeasurementTableSection extends StatelessWidget {
  final void Function(AdjustmentMeasurementData) onTapItem;
  final void Function(String additiveId) onDelete;
  final List<AdjustmentMeasurementData> adjustmentMeasurementsData;
  final AdjustmentMeasurementData? selectedAdjustmentMeasurement;
  final ContractData? contractData;

  final double valueApostilles;
  final double valueRevisions;
  final double valorTotal;
  final double balance;

  const AdjustmentMeasurementTableSection({
    super.key,
    required this.onTapItem,
    required this.onDelete,
    required this.adjustmentMeasurementsData,
    required this.selectedAdjustmentMeasurement,
    required this.valueApostilles,
    required this.valueRevisions,
    required this.valorTotal,
    required this.balance,
    this.contractData,
  });

  @override
  Widget build(BuildContext context) {
    final totalAdjustments = adjustmentMeasurementsData.fold<double>(0.0, (prev, item) => prev + (item.value ?? 0.0),);
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              const SizedBox(width: 12),
              ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: SimpleTableChanged<AdjustmentMeasurementData>(
                  constraints: constraints,
                  listData: adjustmentMeasurementsData,
                  columnTitles: [
                    'ORDEM',
                    'Nº PROCESSO',
                    'DATA DO REAJUSTE',
                    'VALOR DO REAJUSTE',
                  ],
                  selectedItem: selectedAdjustmentMeasurement,
                  columnGetters: [
                        (a) => '${a.order ?? '-'}',
                        (a) => a.numberprocess ?? '-',
                        (a) => dateTimeToDDMMYYYY(a.date ?? DateTime.now()),
                        (a) => priceToString(a.value),
                  ],
                  onTapItem: onTapItem,
                  onDelete: (item) => onDelete(item.id!),
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
                        label: 'TOTAL DOS REAJUSTES',
                        value: totalAdjustments,
                        backgroundColor: Colors.grey.shade200,
                      ),
                      FooterResumo.empty(),
                      FooterResumo(
                        label: 'VALOR DOS APOSTILAMENTOS',
                        value: valueApostilles,
                        backgroundColor: Colors.white,
                        fontWeight: FontWeight.normal,
                      ),
                      FooterResumo(
                        label: 'VALOR DAS REVISÕES DE APOSTILAMENTO',
                        value: valueRevisions,
                        backgroundColor: Colors.white,
                        fontWeight: FontWeight.normal,
                      ),
                      FooterResumo(
                        label: 'SALDO DO APOSTILAMENTO',
                        value: balance,
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
