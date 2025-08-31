import 'package:flutter/material.dart';
import 'package:siged/_blocs/actives/roads/active_roads_data.dart';
import 'package:siged/_widgets/loading/loading_progress.dart';
import 'package:siged/_widgets/table/virtualized/virtualized_table_changed.dart';

class ActiveRoadsRecordsTableSection extends StatelessWidget {
  final Future<List<ActiveRoadsData>> futureRoads;
  final void Function(ActiveRoadsData) onTapItem;
  final void Function(String id) onDelete;

  const ActiveRoadsRecordsTableSection({
    super.key,
    required this.futureRoads,
    required this.onTapItem,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ActiveRoadsData>>(
      future: futureRoads,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingProgress();
        } else if (snapshot.hasError) {
          return Center(child: Text('Erro: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text('Nenhuma rodovia encontrada.');
        }

        final data = snapshot.data!;
        return LayoutBuilder(
          builder: (context, constraints) {
            // largura disponível segura (quando sem bound, uso a da tela)
            final availableWidth = constraints.hasBoundedWidth
                ? constraints.maxWidth
                : MediaQuery.of(context).size.width;

            // constraint tight e normalizado (min == max == availableWidth)
            final safeConstraints = BoxConstraints.tightFor(width: availableWidth).normalize();

            return SizedBox(
              width: availableWidth, // garante bound estável pro filho
              child: SimpleTableVirtualized<ActiveRoadsData>(
                constraints: safeConstraints,   // <-- aqui o pulo do gato
                listData: data,

                columnTitles: const [
                  'RODOVIA','UF','REGIÃO','CÓDIGO','EXTENSÃO (km)','STATUS','OBRAS',
                  'ÓRGÃO GESTOR','SENTIDO','TMD','VEL. MÁX.','PONTOS',
                ],
                columnGetters: [
                      (r) => r.acronym ?? '-',
                      (r) => r.uf ?? '-',
                      (r) => r.regional ?? (r.metadata?['regional']?.toString() ?? '-'),
                      (r) => r.roadCode ?? '-',
                      (r) => _fmtNum(r.extension, maxDecimals: 3),
                      (r) => (r.stateSurface ?? r.surface ?? r.state) ?? '-',
                      (r) => r.works ?? '-',
                      (r) => r.managingAgency ?? '-',
                      (r) => r.direction ?? '-',
                      (r) => (r.tmd ?? '-').toString(),
                      (r) => (r.maximumSpeed ?? '-').toString(),
                      (r) => (r.points?.length ?? 0).toString(),
                ],
                onTapItem: onTapItem,
                onDelete: (item) {
                  final id = item.id;
                  if (id != null && id.isNotEmpty) onDelete(id);
                },
                columnWidths: const [
                  120, 60, 160, 120, 130, 140, 300, 180, 120, 90, 100, 90, 100,
                ],
                columnTextAligns: const [
                  TextAlign.center, TextAlign.center, TextAlign.center, TextAlign.center,
                  TextAlign.center, TextAlign.center, TextAlign.center, TextAlign.center,
                  TextAlign.center, TextAlign.center, TextAlign.center, TextAlign.center,
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
