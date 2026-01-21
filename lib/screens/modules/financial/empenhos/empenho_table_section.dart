import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:siged/_blocs/modules/financial/empenhos/empenho_data.dart';
import 'package:siged/_widgets/table/simple/simple_table_changed.dart';

class EmpenhoTableSection extends StatelessWidget {
  final List<EmpenhoData> items;
  final EmpenhoData? selected;
  final NumberFormat currency;

  final void Function(EmpenhoData e) onSelect;
  final Future<void> Function(EmpenhoData e)? onDelete;

  const EmpenhoTableSection({
    super.key,
    required this.items,
    required this.selected,
    required this.currency,
    required this.onSelect,
    this.onDelete,
  });

  String _s(String? v) => (v ?? '').trim();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SimpleTableChanged<EmpenhoData>(
          constraints: constraints,
          listData: items,
          selectedItem: selected,
          onTapItem: onSelect,
          onDelete: (e) => onDelete!(e),

          columnTitles: const [
            'NÚMERO',
            'CREDITADO EM',
            'CONTRATANTE',
            'FONTE',
            'DATA',
            'VALOR',
          ],

          columnGetters: [
                (e) => e.numero,
                (e) => _s(e.demandLabel),
                (e) => _s(e.companyLabel) ,
                (e) => _s(e.fundingSourceLabel),
                (e) => DateFormat('dd/MM/yyyy').format(e.date),
                (e) => currency.format(e.empenhadoTotal),
          ],

          columnWidths: const [140, 360, 220, 220, 120, 140, 220],

          columnTextAligns: const [
            TextAlign.center,   // numero
            TextAlign.left,   // demanda
            TextAlign.center,   // contratante
            TextAlign.center,   // fonte
            TextAlign.center, // data
            TextAlign.right,  // total
            TextAlign.center,
          ],
        );
      },
    );
  }
}
