import 'package:flutter/material.dart';
import 'package:sisged/_widgets/table/simple_table_changed.dart';

import '../../../../../_widgets/loading/loading_progress.dart';
import '../../../../_datas/actives/oaes/oaesData.dart';

class ModalOaesRegistrationTableSection extends StatelessWidget {
  final void Function(OaesData) onTapItem;
  final void Function(String additiveId) onDelete;
  final Future<List<OaesData>> futureOaes;

  const ModalOaesRegistrationTableSection({
    super.key,
    required this.onTapItem,
    required this.onDelete,
    required this.futureOaes,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<OaesData>>(
        future: futureOaes,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingProgress();
          } else if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Text('Nenhum aditivo encontrado.');
          }
          return LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    SizedBox(width: 12),
                    ConstrainedBox(
                        constraints: BoxConstraints(minWidth: constraints.maxWidth),
                        child: SimpleTableChanged<OaesData>(
                          constraints: constraints,
                          listData: snapshot.data!,
                          columnTitles: [
                            'ORDEM',
                            'SCORE',
                            'STATUS',
                            'REGIÃO',
                            'IDENTIFICAÇÃO',
                            'EXTENSÃO',
                            'LARGURA',
                            'ÁREA',
                            'TIPO DE ESTRUTURA',
                            'CONTRATOS RELACIONADOS',
                            'VALOR INTERVENÇÃO',
                            'CUSTO MÉDIO',
                            'CUSTO ESTIMADO',
                            'ÚLTIMA DATA DE INTERVENÇÃO',
                            'EMPRESA QUE CONSTRUIU',
                            'LATITUDE',
                            'LONGITUDE',
                            'ALTITUDE',
                          ],
                          columnGetters: [
                                (a) => '${a.order ?? '-'}',
                                (a) => '${a.score ?? '-'}',
                                (a) => '${a.state ?? '-'}',
                                (a) => '${a.region ?? '-'}',
                                (a) => '${a.identificationName ?? '-'}',
                                (a) => '${a.extension ?? '-'}',
                                (a) => '${a.width ?? '-'}',
                                (a) => '${a.area ?? '-'}',
                                (a) => '${a.structureType ?? '-'}',
                                (a) => '${a.relatedContracts ?? '-'}',
                                (a) => '${a.valueIntervention ?? '-'}',
                                (a) => '${a.linearCostMedia ?? '-'}',
                                (a) => '${a.costEstimate ?? '-'}',
                                (a) => '${a.lastDateIntervention ?? '-'}',
                                (a) => '${a.companyBuild ?? '-'}',
                                (a) => '${a.latitude ?? '-'}',
                                (a) => '${a.longitude ?? '-'}',
                                (a) => '${a.altitude ?? '-'}',
                          ],
                          onTapItem: (item) => onTapItem(item),
                          onDelete: (item) => onDelete(item.id!),
                          columnWidths: const [
                            100,
                            200,
                            150,
                            200,
                            100,
                            100,
                            100,
                            100,
                            100,
                            100,
                            100,
                            100,
                            100,
                            100,
                            100,
                            100,
                            100,
                            100,
                          ],
                          columnTextAligns: const [
                            TextAlign.center,
                            TextAlign.center,
                            TextAlign.center,
                            TextAlign.center,
                            TextAlign.center,
                            TextAlign.center,
                            TextAlign.center,
                            TextAlign.center,
                            TextAlign.center,
                            TextAlign.center,
                            TextAlign.center,
                            TextAlign.center,
                            TextAlign.center,
                            TextAlign.center,
                            TextAlign.center,
                            TextAlign.center,
                            TextAlign.center,
                            TextAlign.center,
                          ]
                        )
                    ),
                  ],
                ),
              );
            },
          );
        }
    );
  }
}
