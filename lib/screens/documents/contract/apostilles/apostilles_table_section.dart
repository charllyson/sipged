import 'package:flutter/material.dart';
import 'package:sisged/_utils/date_utils.dart';
import 'package:sisged/_widgets/table/simple_table_changed.dart';

import 'package:sisged/_utils/formats/format_field.dart';
import 'package:sisged/_widgets/loading/loading_progress.dart';
import 'package:sisged/_blocs/documents/contracts/apostilles/apostilles_data.dart';

class ApostilleTableSection extends StatelessWidget {
  final void Function(ApostillesData) onTapItem;
  final void Function(String apostilleId) onDelete;
  final Future<List<ApostillesData>> futureApostilles;

  const ApostilleTableSection({
    super.key,
    required this.onTapItem,
    required this.onDelete,
    required this.futureApostilles,
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
                      columnTitles: [
                        'ORDEM',
                        'Nº PROCESSO',
                        'DATA',
                        'VALOR',
                      ],
                      columnGetters: [
                            (a) => '${a.apostilleOrder ?? '-'}',
                            (a) => a.apostilleNumberProcess ?? '-',
                            (a) => convertDateTimeToDDMMYYYY(a.apostilleData ?? DateTime.now()),
                            (a) => priceToString(a.apostilleValue),
                      ],
                      onTapItem: (item) => onTapItem(item),
                      onDelete: (item) => onDelete(item.id!),
                      columnWidths: const [
                        100,
                        200,
                        150,
                        200,
                      ],
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
