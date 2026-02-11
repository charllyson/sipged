// ==============================
// lib/screens/contracts/validity/validity_table_section.dart
// ==============================
import 'package:flutter/material.dart';
import 'package:siged/_blocs/modules/contracts/validity/validity_data.dart';
import 'package:siged/_utils/formats/sipged_format_dates.dart';
import 'package:siged/_widgets/table/simple/simple_table_changed.dart';

class ValidityTableSection extends StatelessWidget {
  final void Function(ValidityData) onTapItem;
  final Future<void> Function(String validityId) onDelete;

  /// Lista de validades já carregada (vindo do Cubit/State)
  final List<ValidityData> validities;

  /// item selecionado para destacar a linha
  final ValidityData? selectedItem;

  const ValidityTableSection({
    super.key,
    required this.onTapItem,
    required this.onDelete,
    required this.validities,
    this.selectedItem,
  });

  @override
  Widget build(BuildContext context) {
    if (validities.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text('Nenhuma ordem encontrada.'),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SimpleTableChanged<ValidityData>(
          listData: validities,
          constraints: constraints,
          columnTitles: const [
            'ORDEM',
            'TIPO DA ORDEM',
            'DATA DA ORDEM',
          ],
          columnWidths: const [
            80,
            260,
            180,
            80, // col. apagar
          ],
          columnGetters: [
                (item) => item.orderNumber?.toString() ?? '',
                (item) => item.ordertype ?? '',
                (item) => SipGedFormatDates.dateToDdMMyyyy(item.orderdate),
          ],
          columnTextAligns: const [
            TextAlign.center,
            TextAlign.left,
            TextAlign.center,
            TextAlign.center,
          ],
          onTapItem: onTapItem,
          onDelete: (item) async {
            if (item.id != null) {
              await onDelete(item.id!);
            }
          },
          selectedItem: selectedItem,
        );
      },
    );
  }
}
