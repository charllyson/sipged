import 'package:flutter/material.dart';
import 'package:siged/_utils/date_utils.dart';
import 'package:siged/_widgets/table/simple/simple_table_changed.dart';

import 'package:siged/_widgets/loading/loading_progress.dart';
import 'package:siged/_blocs/documents/contracts/validity/validity_data.dart';

class ValidityTableSection extends StatelessWidget {
  final void Function(ValidityData) onTapItem;
  final void Function(String validityId) onDelete;
  final Future<List<ValidityData>> futureValidity;

  const ValidityTableSection({
    super.key,
    required this.onTapItem,
    required this.onDelete,
    required this.futureValidity,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ValidityData>>(
        future: futureValidity,
        builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingProgress();
        } else if (snapshot.hasError) {
          return Center(child: Text('Erro: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text('Nenhuma ordem encontrada.');
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            return SimpleTableChanged<ValidityData>(
              listData: snapshot.data!,
              constraints: constraints,
              columnTitles: const [
                'ORDEM',
                'TIPO DA ORDEM',
                'DATA DA ORDEM',
              ],
              columnWidths: const [
                80,
                200,
                140,
                80,
              ],
              columnGetters: [
                    (item) => item.orderNumber?.toString() ?? '',
                    (item) => item.ordertype ?? '',
                    (item) => convertDateTimeToDDMMYYYY(item.orderdate),
              ],
              columnTextAligns: const [
                TextAlign.center,
                TextAlign.left,
                TextAlign.center,
                TextAlign.center,
              ],
              onTapItem: onTapItem,
              onDelete: (item) => onDelete(item.id!),
            );
          },
        );
      }
    );
  }
}
