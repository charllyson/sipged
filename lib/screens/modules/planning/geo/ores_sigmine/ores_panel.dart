import 'package:flutter/material.dart';
import 'package:sipged/_widgets/background/background_cleaner.dart';
import 'package:sipged/_widgets/charts/gauges/gauge_circular_percent.dart';
import 'package:sipged/_widgets/charts/pies/pie_chart_changed.dart';
import 'package:sipged/_widgets/texts/divider_text.dart';
import 'package:sipged/_widgets/texts/section_text_name.dart';

class OresPanel extends StatelessWidget {
  const OresPanel({
    super.key,
    required this.minerios,
    required this.contagens,
    required this.selectedIndex,
    required this.getColorForMinerio,
    required this.onSelectMinerio,
    required this.hasData,
  });

  /// ⚠️ CHAVES NORMALIZADAS (ex.: FERRO, OURO, etc.)
  final List<String> minerios;
  final List<int> contagens;
  final int? selectedIndex; // índice do pie/seleção
  final Color Function(String) getColorForMinerio; // recebe chave (normalizada ou não)
  final void Function(String) onSelectMinerio; // devolve chave normalizada
  final bool hasData;

  @override
  Widget build(BuildContext context) {
    if (!hasData) {
      return const Stack(
        children: [
          BackgroundClean(),
          Center(child: Text('Selecione um estado para visualizar os dados.')),
        ],
      );
    }

    // ======= Gauge =======
    final int total = contagens.fold(0, (a, b) => a + b);
    final bool oneSelected = selectedIndex != null &&
        selectedIndex! >= 0 &&
        selectedIndex! < minerios.length;
    final String gaugeLabel =
    oneSelected ? minerios[selectedIndex!] : 'Total de jazidas';
    final int gaugeCount = oneSelected ? contagens[selectedIndex!] : total;
    final double gaugePercent =
    total > 0 ? (gaugeCount / total).clamp(0.0, 1.0) : 0.0;

    const double kGaugeBoxWidth = 260;
    const double kPieBoxWidth = 280;

    return Stack(
      children: [
        const BackgroundClean(),
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionTitle(text: 'Jazida de minério'),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    SizedBox(
                      width: kGaugeBoxWidth,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final double side = constraints.maxWidth;
                          final double dynamicRadius = side * 0.35;
                          final double dynamicFontSize =
                              dynamicRadius * 0.5;

                          return Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: GaugeCircularPercent(
                              centerTitle: gaugePercent,
                              footerTitle: gaugeLabel,
                              headerMode: GaugeTextMode.number,
                              centerMode: GaugeTextMode.number,
                              values: [gaugeCount.toDouble()],
                              footerMode: GaugeTextMode.explicit,
                              radius: dynamicRadius,
                              larguraGrafico: side,
                              centerFontSize: dynamicFontSize,
                              footerFontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),

                    // ---- PIE ----
                    SizedBox(
                      width: kPieBoxWidth,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final double side = constraints.maxWidth;
                          final double chartHeight =
                          (side * 0.85).clamp(160.0, 195.0);
                          final double maxOuter =
                              (chartHeight / 2) - 12.0;

                          final double baseSlice =
                          (side * 0.2).clamp(34.0, maxOuter);
                          final double hiSlice =
                          (baseSlice + 6.0).clamp(baseSlice, maxOuter);
                          final double centerHole =
                          (baseSlice * 0.58).clamp(18.0, baseSlice - 10.0);

                          const double alturaCard = 295;

                          return Padding(
                            padding:
                            const EdgeInsets.only(right: 12.0, top: 12),
                            child: PieChartChanged(
                              valueFormatType: ValueFormatType.integer,
                              colorCard: Colors.white,
                              labels: minerios,
                              values: contagens
                                  .map((e) => e.toDouble())
                                  .toList(),
                              // 🎯 MESMA PALETA do mapa
                              coresPersonalizadas:
                              minerios.map(getColorForMinerio).toList(),
                              selectedIndex: selectedIndex,
                              larguraGrafico: side,
                              alturaCard: alturaCard,
                              chartHeight: chartHeight,
                              sliceRadius: baseSlice,
                              sliceRadiusHighlighted: hiSlice,
                              centerSpaceRadius: centerHole,
                              sectionsSpace: 2,
                              onTouch: (idx) {
                                if (idx == null || idx >= minerios.length) {
                                  return;
                                }
                                onSelectMinerio(minerios[idx]);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              const DividerText(text: 'Detalhamento por substância'),
              const SizedBox(height: 4),

              // ===================== LISTA =====================
              ListView.builder(
                itemCount: minerios.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (_, i) {
                  final nome = minerios[i];
                  final cor = getColorForMinerio(nome);
                  final bool isSelected =
                      selectedIndex != null && i == selectedIndex;
                  final bool ativo = isSelected || selectedIndex == null;

                  return ListTile(
                    dense: true,
                    visualDensity: const VisualDensity(
                      horizontal: -2,
                      vertical: -2,
                    ),
                    leading: Icon(
                      isSelected
                          ? Icons.check_circle
                          : Icons.circle_outlined,
                      color: isSelected ? cor : Colors.grey,
                    ),
                    title: Text(
                      nome,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: ativo ? cor : Colors.grey.shade700,
                        fontWeight:
                        ativo ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    trailing: Text('${contagens[i]}'),
                    onTap: () => onSelectMinerio(nome),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }
}
