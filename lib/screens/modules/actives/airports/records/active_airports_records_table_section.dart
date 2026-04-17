import 'package:flutter/material.dart';

import 'package:sipged/_blocs/modules/actives/oaes/active_oaes_data.dart';
import 'package:sipged/_utils/formats/sipged_format_dates.dart';
import 'package:sipged/_utils/formats/sipged_format_money.dart';
import 'package:sipged/_widgets/table/paged/paged_colum.dart';
import 'package:sipged/_widgets/table/paged/paged_table_changed.dart';

class ActiveOaesRecordsTableSection extends StatelessWidget {
  final void Function(ActiveOaesData) onTapItem;
  final void Function(String oaeId) onDelete;
  final List<ActiveOaesData> oaes;

  const ActiveOaesRecordsTableSection({
    super.key,
    required this.onTapItem,
    required this.onDelete,
    required this.oaes,
  });

  @override
  Widget build(BuildContext context) {
    if (oaes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(12.0),
        child: Text('Nenhuma OAE encontrada.'),
      );
    }

    return SizedBox(
      height: 620,
      child: PagedTableChanged<ActiveOaesData>(
        listData: oaes,
        getKey: (item) => item.id ?? '',
        onTapItem: onTapItem,
        onDelete: (item) {
          final id = item.id;
          if (id != null && id.isNotEmpty) {
            onDelete(id);
          }
        },
        statusLabel: 'OAEs encontradas',
        minTableWidth: 3100,
        initialRowsPerPage: 25,
        rowsPerPageOptions: const [10, 25, 50, 100],
        columns: [
          const PagedColum<ActiveOaesData>(
            title: 'ORDEM',
            getter: _getOrder,
            textAlign: TextAlign.center,
            maxWidth: 100,
          ),
          const PagedColum<ActiveOaesData>(
            title: 'SCORE',
            getter: _getScore,
            textAlign: TextAlign.center,
            maxWidth: 100,
          ),
          const PagedColum<ActiveOaesData>(
            title: 'UF',
            getter: _getState,
            textAlign: TextAlign.center,
            maxWidth: 90,
          ),
          const PagedColum<ActiveOaesData>(
            title: 'REGIÃO',
            getter: _getRegion,
            textAlign: TextAlign.center,
            maxWidth: 120,
          ),
          const PagedColum<ActiveOaesData>(
            title: 'IDENTIFICAÇÃO',
            getter: _getIdentification,
            textAlign: TextAlign.left,
            maxWidth: 280,
          ),
          const PagedColum<ActiveOaesData>(
            title: 'EXTENSÃO',
            getter: _getExtension,
            textAlign: TextAlign.center,
            maxWidth: 120,
          ),
          const PagedColum<ActiveOaesData>(
            title: 'LARGURA',
            getter: _getWidth,
            textAlign: TextAlign.center,
            maxWidth: 120,
          ),
          const PagedColum<ActiveOaesData>(
            title: 'ÁREA',
            getter: _getArea,
            textAlign: TextAlign.center,
            maxWidth: 120,
          ),
          const PagedColum<ActiveOaesData>(
            title: 'TIPO DE ESTRUTURA',
            getter: _getStructureType,
            textAlign: TextAlign.left,
            maxWidth: 180,
          ),
          const PagedColum<ActiveOaesData>(
            title: 'CONTRATOS RELACIONADOS',
            getter: _getRelatedContracts,
            textAlign: TextAlign.left,
            maxWidth: 220,
          ),
          const PagedColum<ActiveOaesData>(
            title: 'VALOR INTERVENÇÃO',
            getter: _getValueIntervention,
            textAlign: TextAlign.right,
            maxWidth: 160,
          ),
          const PagedColum<ActiveOaesData>(
            title: 'CUSTO MÉDIO',
            getter: _getLinearCostMedia,
            textAlign: TextAlign.right,
            maxWidth: 140,
          ),
          const PagedColum<ActiveOaesData>(
            title: 'CUSTO ESTIMADO',
            getter: _getCostEstimate,
            textAlign: TextAlign.right,
            maxWidth: 160,
          ),
          const PagedColum<ActiveOaesData>(
            title: 'ÚLTIMA DATA DE INTERVENÇÃO',
            getter: _getLastDateIntervention,
            textAlign: TextAlign.center,
            maxWidth: 200,
          ),
          const PagedColum<ActiveOaesData>(
            title: 'EMPRESA QUE CONSTRUIU',
            getter: _getCompanyBuild,
            textAlign: TextAlign.left,
            maxWidth: 220,
          ),
          const PagedColum<ActiveOaesData>(
            title: 'LATITUDE',
            getter: _getLatitude,
            textAlign: TextAlign.center,
            maxWidth: 140,
          ),
          const PagedColum<ActiveOaesData>(
            title: 'LONGITUDE',
            getter: _getLongitude,
            textAlign: TextAlign.center,
            maxWidth: 140,
          ),
          const PagedColum<ActiveOaesData>(
            title: 'ALTITUDE',
            getter: _getAltitude,
            textAlign: TextAlign.center,
            maxWidth: 120,
          ),
        ],
      ),
    );
  }

  static String _getOrder(ActiveOaesData a) => '${a.order ?? '-'}';

  static String _getScore(ActiveOaesData a) {
    if (a.score == null) return '-';
    return a.score!.toStringAsFixed(
      a.score!.truncateToDouble() == a.score ? 0 : 1,
    );
  }

  static String _getState(ActiveOaesData a) => a.state ?? '-';

  static String _getRegion(ActiveOaesData a) => a.region ?? '-';

  static String _getIdentification(ActiveOaesData a) =>
      a.identificationName ?? '-';

  static String _getExtension(ActiveOaesData a) => _fmtNum(a.extension);

  static String _getWidth(ActiveOaesData a) => _fmtNum(a.width);

  static String _getArea(ActiveOaesData a) => _fmtNum(a.area);

  static String _getStructureType(ActiveOaesData a) =>
      a.estructureType ?? '-';

  static String _getRelatedContracts(ActiveOaesData a) =>
      a.relatedContracts ?? '-';

  static String _getValueIntervention(ActiveOaesData a) =>
      SipGedFormatMoney.doubleToText(a.valueIntervention);

  static String _getLinearCostMedia(ActiveOaesData a) =>
      SipGedFormatMoney.doubleToText(a.linearCostMedia);

  static String _getCostEstimate(ActiveOaesData a) =>
      SipGedFormatMoney.doubleToText(a.costEstimate);

  static String _getLastDateIntervention(ActiveOaesData a) =>
      SipGedFormatDates.dateToDdMMyyyy(a.lastDateIntervention);

  static String _getCompanyBuild(ActiveOaesData a) => a.companyBuild ?? '-';

  static String _getLatitude(ActiveOaesData a) =>
      _fmtNum(a.latitude, maxDecimals: 6);

  static String _getLongitude(ActiveOaesData a) =>
      _fmtNum(a.longitude, maxDecimals: 6);

  static String _getAltitude(ActiveOaesData a) =>
      _fmtNum(a.altitude, maxDecimals: 2);
}

String _fmtNum(num? v, {int maxDecimals = 3}) {
  if (v == null) return '-';
  var s = v.toStringAsFixed(maxDecimals);
  while (s.contains('.') && (s.endsWith('0') || s.endsWith('.'))) {
    s = s.substring(0, s.length - 1);
  }
  return s;
}