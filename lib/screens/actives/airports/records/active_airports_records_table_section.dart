import 'package:flutter/material.dart';
import 'package:siged/_blocs/actives/oaes/active_oaes_data.dart';
import 'package:siged/_widgets/overlays/loading_progress.dart';
import 'package:siged/_utils/formats/date_utils.dart';
import 'package:siged/_utils/formats/format_field.dart';
import 'package:siged/_widgets/table/virtualized/virtualized_table_changed.dart';

class ActiveAirportsRecordsTableSection extends StatelessWidget {
  final void Function(ActiveOaesData) onTapItem;
  final void Function(String oaeId) onDelete;
  final Future<List<ActiveOaesData>> futureOaes;

  const ActiveAirportsRecordsTableSection({
    super.key,
    required this.onTapItem,
    required this.onDelete,
    required this.futureOaes,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ActiveOaesData>>(
      future: futureOaes,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingProgress();
        } else if (snapshot.hasError) {
          return Center(child: Text('Erro: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text('Nenhuma OAE encontrada.');
        }

        final data = snapshot.data!;

        return LayoutBuilder(
          builder: (context, constraints) {
            return SimpleTableVirtualized<ActiveOaesData>(
              constraints: constraints,
              listData: data,

              // Cabeçalho
              columnTitles: const [
                'ORDEM',
                'SCORE',
                'UF',
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

              // Como renderizar cada célula
              columnGetters: [
                    (a) => '${a.order ?? '-'}',
                    (a) => a.score == null
                    ? '-'
                    : a.score!.toStringAsFixed(
                    a.score!.truncateToDouble() == a.score ? 0 : 1),
                    (a) => a.state ?? '-',
                    (a) => a.region ?? '-',
                    (a) => a.identificationName ?? '-',
                    (a) => _fmtNum(a.extension),
                    (a) => _fmtNum(a.width),
                    (a) => _fmtNum(a.area),
                    (a) => a.structureType ?? '-',
                    (a) => a.relatedContracts ?? '-',
                    (a) => priceToString(a.valueIntervention),
                    (a) => priceToString(a.linearCostMedia),
                    (a) => priceToString(a.costEstimate),
                    (a) => dateTimeToDDMMYYYY(a.lastDateIntervention),
                    (a) => a.companyBuild ?? '-',
                    (a) => _fmtNum(a.latitude, maxDecimals: 6),
                    (a) => _fmtNum(a.longitude, maxDecimals: 6),
                    (a) => _fmtNum(a.altitude, maxDecimals: 2),
              ],

              onTapItem: onTapItem,
              onDelete: (item) {
                final id = item.id;
                if (id != null && id.isNotEmpty) onDelete(id);
              },

              // Larguras: 18 colunas de dados + 1 coluna do botão "Apagar"
              columnWidths: const [
                100, // ordem
                100, // score
                90,  // uf
                120, // região
                280, // identificação
                120, // extensão
                120, // largura
                120, // área
                180, // tipo de estrutura
                220, // contratos relacionados
                160, // valor intervenção
                140, // custo médio
                160, // custo estimado
                200, // última data intervenção
                220, // empresa
                140, // latitude
                140, // longitude
                120, // altitude
                56,  // <-- largura da coluna de delete (obrigatória quando onDelete != null)
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
              ],
              // NOVO: modo virtualizado
              bodyHeight: 480, // ajuste conforme seu layout
            );
          },
        );
      },
    );
  }
}

// ---------- helpers locais ----------
String _fmtNum(num? v, {int maxDecimals = 3}) {
  if (v == null) return '-';
  var s = v.toStringAsFixed(maxDecimals);
  while (s.contains('.') && (s.endsWith('0') || s.endsWith('.'))) {
    s = s.substring(0, s.length - 1);
  }
  return s;
}
