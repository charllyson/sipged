import 'package:flutter/material.dart';
import 'package:sisged/_widgets/charts/gauge_circular_percent.dart';
import '../../../../_widgets/charts/barGraph/bar_chart_changed.dart';
import '../../../../_widgets/charts/pieGraph/pie_chart_changed.dart';

class AccidentsChartsSection extends StatelessWidget {
  final List<String> labelsType;
  final List<double> valuesType;
  final List<String> labelsRegiao;
  final List<double> valuesRegiao;
  final double valorTotal;
  final double totalAccidents;
  final int? selectedIndexType;
  final int? selectedIndexRegiao;

  final void Function(String? tipoSelecionado)? onTypeSelected;
  final void Function(String regionName)? onRegionTap;

  const AccidentsChartsSection({
    super.key,
    required this.labelsType,
    required this.valuesType,
    required this.labelsRegiao,
    required this.valuesRegiao,
    this.selectedIndexType,
    this.selectedIndexRegiao,
    this.onTypeSelected,
    this.onRegionTap,
    required this.valorTotal,
    required this.totalAccidents,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: ValueKey('row_${labelsRegiao.join()}_${labelsType.join()}'),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [

          GaugeCircularPercent(
            percent: valorTotal == 0 ? 0 : totalAccidents / valorTotal,
            label: 'Total em sinistros ',
            subTitle: '${totalAccidents.toString()} de ${valorTotal.toString()}',
            radius: 90,
            larguraGrafico: 255,
            values: totalAccidents.isNaN ? null : [totalAccidents],
          ),
          const SizedBox(width: 12),
          PieChartChanged(
            key: ValueKey('tipo_${labelsType.join()}_${valuesType.join()}'),
            labels: labelsType,
            values: valuesType,
            selectedIndex: selectedIndexType,
            showPercentageOutside: false,
            larguraGrafico: 360,
            onTapLabel: onTypeSelected,
            valueFormatType: ValueFormatType.integer
          ),
          const SizedBox(width: 12),
          BarChartChanged(
            key: ValueKey('regiao_${labelsRegiao.join()}_${valuesRegiao.join()}'),
            widthTitleBar: 80,
            heightGraphic: 260,
            labels: labelsRegiao,
            values: valuesRegiao,
            selectedIndex: selectedIndexRegiao,
            onBarTap: onRegionTap ?? (_) {},
            valueFormatter: (v) => v.toInt().toString(),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}
