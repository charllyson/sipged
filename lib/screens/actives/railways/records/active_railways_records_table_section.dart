import 'package:flutter/material.dart';
import 'package:siged/_widgets/loading/loading_progress.dart';
import 'package:siged/_widgets/table/virtualized/virtualized_table_changed.dart';
import 'package:siged/_blocs/actives/railway/active_railway_data.dart';

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

            final safeConstraints = BoxConstraints.tightFor(width: availableWidth).normalize();

            return SizedBox(
              width: availableWidth,
              child: SimpleTableVirtualized<ActiveRailwayData>(
                constraints: safeConstraints,
                listData: data,

                columnTitles: const [
                  'CÓDIGO','NOME','STATUS','BITOLA','UF','MUNICÍPIO',
                  'EXTENSÃO (km)','EXT. E.','EXT. C.','SEGMENTOS','PONTOS',
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
                columnWidths: const [
                  110, 220, 140, 110, 60, 160, 120, 100, 100, 110, 100, 100,
                ],
                columnTextAligns: const [
                  TextAlign.center, TextAlign.left,  TextAlign.center, TextAlign.center,
                  TextAlign.center, TextAlign.left,  TextAlign.center, TextAlign.center,
                  TextAlign.center, TextAlign.center, TextAlign.center,
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
