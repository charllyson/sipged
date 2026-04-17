import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/actives/railway/active_railway_data.dart';
import 'package:sipged/_widgets/overlays/loading_progress.dart';
import 'package:sipged/_widgets/table/paged/paged_colum.dart';
import 'package:sipged/_widgets/table/paged/paged_table_changed.dart';

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
        }

        if (snapshot.hasError) {
          return Center(child: Text('Erro: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(12.0),
            child: Text('Nenhuma ferrovia encontrada.'),
          );
        }

        final data = snapshot.data!;

        return SizedBox(
          height: 620,
          child: PagedTableChanged<ActiveRailwayData>(
            listData: data,
            getKey: (item) => item.id ?? '',
            onTapItem: onTapItem,
            onDelete: (item) {
              final id = item.id;
              if (id != null && id.isNotEmpty) {
                onDelete(id);
              }
            },
            statusLabel: 'Ferrovias encontradas',
            minTableWidth: 1500,
            initialRowsPerPage: 25,
            rowsPerPageOptions: const [10, 25, 50, 100],
            columns: [
              const PagedColum<ActiveRailwayData>(
                title: 'CÓDIGO',
                getter: _getCodigo,
                textAlign: TextAlign.center,
                maxWidth: 110,
              ),
              const PagedColum<ActiveRailwayData>(
                title: 'NOME',
                getter: _getNome,
                textAlign: TextAlign.left,
                maxWidth: 220,
              ),
              const PagedColum<ActiveRailwayData>(
                title: 'STATUS',
                getter: _getStatus,
                textAlign: TextAlign.center,
                maxWidth: 140,
              ),
              const PagedColum<ActiveRailwayData>(
                title: 'BITOLA',
                getter: _getBitola,
                textAlign: TextAlign.center,
                maxWidth: 110,
              ),
              const PagedColum<ActiveRailwayData>(
                title: 'UF',
                getter: _getUf,
                textAlign: TextAlign.center,
                maxWidth: 60,
              ),
              const PagedColum<ActiveRailwayData>(
                title: 'MUNICÍPIO',
                getter: _getMunicipio,
                textAlign: TextAlign.left,
                maxWidth: 160,
              ),
              const PagedColum<ActiveRailwayData>(
                title: 'EXTENSÃO (km)',
                getter: _getExtensao,
                textAlign: TextAlign.center,
                maxWidth: 120,
              ),
              const PagedColum<ActiveRailwayData>(
                title: 'EXT. E.',
                getter: _getExtensaoE,
                textAlign: TextAlign.center,
                maxWidth: 100,
              ),
              const PagedColum<ActiveRailwayData>(
                title: 'EXT. C.',
                getter: _getExtensaoC,
                textAlign: TextAlign.center,
                maxWidth: 100,
              ),
              const PagedColum<ActiveRailwayData>(
                title: 'SEGMENTOS',
                getter: _getSegments,
                textAlign: TextAlign.center,
                maxWidth: 110,
              ),
              const PagedColum<ActiveRailwayData>(
                title: 'PONTOS',
                getter: _getPoints,
                textAlign: TextAlign.center,
                maxWidth: 100,
              ),
            ],
          ),
        );
      },
    );
  }

  static String _getCodigo(ActiveRailwayData r) => r.codigo ?? '-';

  static String _getNome(ActiveRailwayData r) => r.nome ?? '-';

  static String _getStatus(ActiveRailwayData r) => r.status ?? '-';

  static String _getBitola(ActiveRailwayData r) => r.bitola ?? '-';

  static String _getUf(ActiveRailwayData r) => r.uf ?? '-';

  static String _getMunicipio(ActiveRailwayData r) => r.municipio ?? '-';

  static String _getExtensao(ActiveRailwayData r) =>
      _fmtNum(r.extensao, maxDecimals: 3);

  static String _getExtensaoE(ActiveRailwayData r) =>
      _fmtNum(r.extensaoE, maxDecimals: 3);

  static String _getExtensaoC(ActiveRailwayData r) =>
      _fmtNum(r.extensaoC, maxDecimals: 3);

  static String _getSegments(ActiveRailwayData r) =>
      r.segments.length.toString();

  static String _getPoints(ActiveRailwayData r) =>
      r.pointsFlattened.length.toString();
}

String _fmtNum(num? v, {int maxDecimals = 3}) {
  if (v == null) return '-';
  var s = v.toStringAsFixed(maxDecimals);
  while (s.contains('.') && (s.endsWith('0') || s.endsWith('.'))) {
    s = s.substring(0, s.length - 1);
  }
  return s;
}