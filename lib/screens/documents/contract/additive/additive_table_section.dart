import 'package:flutter/material.dart';
import 'package:sisged/_utils/date_utils.dart';
import 'package:sisged/_widgets/table/simple_table_changed.dart';
import 'package:sisged/_widgets/formats/format_field.dart';
import 'package:sisged/_widgets/loading/loading_progress.dart';
import 'package:sisged/_datas/documents/contracts/additive/additive_data.dart';

class AdditiveTableSection extends StatelessWidget {
  final void Function(AdditiveData) onTapItem;
  final void Function(String additiveId) onDelete;
  final Future<List<AdditiveData>> futureAdditive;

  const AdditiveTableSection({
    super.key,
    required this.onTapItem,
    required this.onDelete,
    required this.futureAdditive,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AdditiveData>>(
      future: futureAdditive,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingProgress();
        } else if (snapshot.hasError) {
          return Center(child: Text('Erro: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text('Nenhum aditivo encontrado.');
        }
        final data = snapshot.data!;
        return LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: SimpleTableChanged<AdditiveData>(
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
                            (a) => convertDateTimeToDDMMYYYY(a.additiveDate ?? DateTime.now()),
                            (a) => priceToString(a.additiveValue),
                            (a) => '${a.additiveValidityContractDays ?? '-'}',
                            (a) => '${a.additiveValidityExecutionDays ?? '-'}',
                      ],
                      onTapItem: onTapItem,
                      onDelete: (item) => onDelete(item.id!),
                      columnWidths: const [100, 200, 150, 200, 100, 100],
                      columnTextAligns: const [
                        TextAlign.center,
                        TextAlign.center,
                        TextAlign.center,
                        TextAlign.center,
                        TextAlign.center,
                        TextAlign.center
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
