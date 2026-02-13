// lib/screens/contracts/additives/additive_table_section.dart
import 'package:flutter/material.dart';
import 'package:sipged/_utils/formats/sipged_format_dates.dart';
import 'package:sipged/_utils/formats/sipged_format_money.dart';
import 'package:sipged/_widgets/table/simple/simple_table_changed.dart';
import 'package:sipged/_widgets/overlays/loading_progress.dart';
import 'package:sipged/_blocs/modules/contracts/additives/additives_data.dart';

class AdditiveTableSection extends StatelessWidget {
  final void Function(AdditivesData) onTapItem;
  final void Function(AdditivesData item) onDelete;
  final List<AdditivesData> additives;
  final bool isLoading;
  final AdditivesData? selectedItem;

  const AdditiveTableSection({
    super.key,
    required this.onTapItem,
    required this.onDelete,
    required this.additives,
    required this.isLoading,
    this.selectedItem,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && additives.isEmpty) {
      return const LoadingProgress();
    } else if (!isLoading && additives.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Text('Nenhum aditivo encontrado.'),
      );
    }

    final data = additives;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              const SizedBox(width: 12),
              ConstrainedBox(
                constraints:
                BoxConstraints(minWidth: constraints.maxWidth),
                child: SimpleTableChanged<AdditivesData>(
                  constraints: constraints,
                  listData: data,
                  columnTitles: const [
                    'ORDEM',
                    'Nº PROCESSO',
                    'DATA DO ADITIVO',
                    'VALOR DO ADITIVO',
                    'VALIDADE DO CONTRATO',
                    'VALIDADE DA EXECUÇÃO',
                  ],
                  columnGetters: [
                        (a) => '${a.additiveOrder ?? '-'}',
                        (a) => a.additiveNumberProcess ?? '-',
                        (a) => SipGedFormatDates.dateToDdMMyyyy(
                      a.additiveDate ?? DateTime.now(),
                    ),
                        (a) => SipGedFormatMoney.doubleToText(a.additiveValue),
                        (a) => '${a.additiveValidityContractDays ?? '-'}',
                        (a) => '${a.additiveValidityExecutionDays ?? '-'}',
                  ],
                  onTapItem: onTapItem,
                  onDelete: (item) => onDelete(item),
                  columnWidths: const [100, 200, 150, 200, 100, 100, 56],
                  columnTextAligns: const [
                    TextAlign.center,
                    TextAlign.center,
                    TextAlign.center,
                    TextAlign.center,
                    TextAlign.center,
                    TextAlign.center,
                  ],
                  selectedItem: selectedItem,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
