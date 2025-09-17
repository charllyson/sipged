// ==============================
// lib/screens/contracts/apostilles/apostilles_table_section.dart
// ==============================
import 'package:flutter/material.dart';
import 'package:siged/_utils/date_utils.dart';
import 'package:siged/_widgets/table/simple/simple_table_changed.dart';

import 'package:siged/_widgets/loading/loading_progress.dart';
import 'package:siged/_blocs/documents/contracts/apostilles/apostilles_data.dart';
import 'package:siged/_utils/formats/format_field.dart';

class ApostilleTableSection extends StatelessWidget {
  final Future<List<ApostillesData>> futureApostilles;
  final void Function(ApostillesData) onTapItem;
  final void Function(String id) onDelete;

  // 🆕 para destacar linha selecionada
  final ApostillesData? selectedItem;

  const ApostilleTableSection({
    super.key,
    required this.futureApostilles,
    required this.onTapItem,
    required this.onDelete,
    this.selectedItem,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ApostillesData>>(
      future: futureApostilles,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingProgress();
        } else if (snapshot.hasError) {
          return Center(child: Text('Erro: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text('Nenhum apostilamento encontrado.');
        }

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
                      listData: snapshot.data!,
                      columnTitles: const [
                        'ORDEM',
                        'Nº PROCESSO',
                        'DATA',
                        'VALOR',
                      ],
                      columnGetters: [
                            (a) => '${a.apostilleOrder ?? '-'}',
                            (a) => a.apostilleNumberProcess ?? '-',
                            (a) => dateTimeToDDMMYYYY(a.apostilleData ?? DateTime.now()),
                            (a) => priceToString(a.apostilleValue),
                      ],
                      onTapItem: onTapItem,
                      onDelete: (item) => onDelete(item.id!),
                      // 🆕 destaque de seleção
                      selectedItem: selectedItem,
                      columnWidths: const [100, 200, 150, 200],
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
      },
    );
  }
}
