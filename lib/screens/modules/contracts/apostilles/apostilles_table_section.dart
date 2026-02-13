import 'package:flutter/material.dart';
import 'package:sipged/_utils/formats/sipged_format_dates.dart';
import 'package:sipged/_utils/formats/sipged_format_money.dart';

import 'package:sipged/_widgets/table/simple/simple_table_changed.dart';
import 'package:sipged/_widgets/overlays/loading_progress.dart';
import 'package:sipged/_blocs/modules/contracts/apostilles/apostilles_data.dart';

class ApostilleTableSection extends StatelessWidget {
  final void Function(ApostillesData) onTapItem;
  final void Function(ApostillesData item) onDelete;

  final List<ApostillesData> apostilles;
  final bool isLoading;

  final ApostillesData? selectedItem;

  const ApostilleTableSection({
    super.key,
    required this.onTapItem,
    required this.onDelete,
    required this.apostilles,
    required this.isLoading,
    this.selectedItem,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && apostilles.isEmpty) {
      return const LoadingProgress();
    } else if (!isLoading && apostilles.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Text('Nenhum apostilamento encontrado.'),
      );
    }

    final data = apostilles;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              const SizedBox(width: 12),
              ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: SimpleTableChanged<ApostillesData>(
                  constraints: constraints,
                  listData: data,
                  columnTitles: const [
                    'ORDEM',
                    'Nº PROCESSO',
                    'DATA',
                    'VALOR',
                  ],
                  columnGetters: [
                        (a) => '${a.apostilleOrder ?? '-'}',
                        (a) => a.apostilleNumberProcess ?? '-',
                        (a) => SipGedFormatDates.dateToDdMMyyyy(a.apostilleData ?? DateTime.now()),
                        (a) => SipGedFormatMoney.doubleToText(a.apostilleValue),
                  ],
                  onTapItem: onTapItem,
                  onDelete: (item) => onDelete(item),
                  selectedItem: selectedItem,
                  columnWidths: const [100, 200, 150, 200, 56],
                  columnTextAligns: const [
                    TextAlign.center,
                    TextAlign.center,
                    TextAlign.center,
                    TextAlign.center,
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
