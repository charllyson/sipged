import 'package:flutter/material.dart';
import 'package:sipged/_widgets/overlays/loading_progress.dart';
import 'package:sipged/_widgets/table/virtualized/virtualized_table_changed.dart';
import 'package:sipged/_blocs/modules/actives/railway/active_railway_data.dart';

class ActiveRailwaysRecordsTableSection extends StatelessWidget {
  final Future<List<ActiveRailwayData>> futureRailways;
  final void Function(ActiveRailwayData) onTapItem;
  final void Function(String id) onDelete;

  const ActiveRailwaysRecordsTableSection({
    super.key,
    required this.futureRailways,
    required this.onTapItem,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ActiveRailwayData>>(
      future: futureRailways,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingProgress();
        } else if (snapshot.hasError) {
          return Center(child: Text('Erro: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text('Nenhuma ferrovia encontrada.');
        }

        final data = snapshot.data!;
        return LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.hasBoundedWidth
                ? constraints.maxWidth
                : MediaQuery.of(context).size.width;

            final safeConstraints =
            BoxConstraints.tightFor(width: availableWidth).normalize();

            return SizedBox(
              width: availableWidth,
              child: SimpleTableVirtualized<ActiveRailwayData>(
                constraints: safeConstraints,
                listData: data,

                columnTitles: const [
                  'CÓDIGO',
                  'NOME',
                  'STATUS',
                  'BITOLA',
                  'UF',
                  'MUNICÍPIO',
                  'EXTENSÃO (km)',
                  'EXT. E.',
                  'EXT. C.',
                  'SEGMENTOS',
                  'PONTOS',
                ],
                columnGetters: [
                      (r) => r.codigo ?? '-',
                      (r) => r.nome ?? '-',
                      (r) => r.status ?? '-',
                      (r) => r.bitola ?? '-',
                      (r) => r.uf ?? '-',
                      (r) => r.municipio ?? '-',
                      (r) => _fmtNum(r.extensao,  maxDecimals: 3),
                      (r) => _fmtNum(r.extensaoE, maxDecimals: 3),
                      (r) => _fmtNum(r.extensaoC, maxDecimals: 3),
                      (r) => r.segments.length.toString(),
                      (r) => r.pointsFlattened.length.toString(),
                ],
                onTapItem: onTapItem,
                onDelete: (item) {
                  final id = item.id;
                  if (id != null && id.isNotEmpty) onDelete(id);
                },
                // 11 larguras para 11 colunas
                columnWidths: const [
                  110, // CÓDIGO
                  220, // NOME
                  140, // STATUS
                  110, // BITOLA
                  60,  // UF
                  160, // MUNICÍPIO
                  120, // EXTENSÃO (km)
                  100, // EXT. E.
                  100, // EXT. C.
                  110, // SEGMENTOS
                  100, // PONTOS
                ],
                columnTextAligns: const [
                  TextAlign.center, // CÓDIGO
                  TextAlign.left,   // NOME
                  TextAlign.center, // STATUS
                  TextAlign.center, // BITOLA
                  TextAlign.center, // UF
                  TextAlign.left,   // MUNICÍPIO
                  TextAlign.center, // EXTENSÃO (km)
                  TextAlign.center, // EXT. E.
                  TextAlign.center, // EXT. C.
                  TextAlign.center, // SEGMENTOS
                  TextAlign.center, // PONTOS
                ],
                bodyHeight: 480,
              ),
            );
          },
        );
      },
    );
  }
}

// ---------- helpers ----------
String _fmtNum(num? v, {int maxDecimals = 3}) {
  if (v == null) return '-';
  var s = v.toStringAsFixed(maxDecimals);
  while (s.contains('.') && (s.endsWith('0') || s.endsWith('.'))) {
    s = s.substring(0, s.length - 1);
  }
  return s;
}
