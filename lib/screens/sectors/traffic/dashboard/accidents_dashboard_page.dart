// lib/screens/sectors/traffic/dashboard/accidents_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:siged/_blocs/sectors/transit/accidents/accidents_controller.dart';

import 'package:siged/_widgets/background/background_cleaner.dart';
import 'package:siged/screens/sectors/traffic/dashboard/accidents_selector_section.dart';
import 'package:siged/screens/sectors/traffic/dashboard/accidents_summary_section.dart';
import 'package:siged/_widgets/texts/divider_text.dart';
import 'package:siged/_widgets/footBar/foot_bar.dart';
import 'package:siged/_widgets/upBar/up_bar.dart';
import 'accidents_charts_section.dart';
import 'accident_map_section.dart';

class AccidentsDashboardPage extends StatelessWidget {
  const AccidentsDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _AccidentsDashboardScaffold();
  }
}

class _AccidentsDashboardScaffold extends StatefulWidget {
  const _AccidentsDashboardScaffold({super.key});

  @override
  State<_AccidentsDashboardScaffold> createState() => _AccidentsDashboardScaffoldState();
}

class _AccidentsDashboardScaffoldState extends State<_AccidentsDashboardScaffold> {
  bool _didInit = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _didInit) return;
      _didInit = true;
      context.read<AccidentsController>().postFrameInit(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AccidentsController>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const BackgroundClean(),
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const UpBar(),
                      const SizedBox(height: 8),
                      const DividerText(title: 'Estatística geral de acidentes'),
                      const SizedBox(height: 8),
                      AccidentsSummarySection(
                        totalsByType: c.totalsByAccidentType,
                      ),
                      const SizedBox(height: 8),
                      const DividerText(title: 'Maiores índices por tipos e cidades'),
                      const SizedBox(height: 8),
                      AccidentsChartsSection(
                        labelsType: c.labelsType,
                        valuesType: c.valuesType,
                        labelsRegiao: c.labelsRegiao,
                        valuesRegiao: c.valuesRegiao,
                        selectedIndexType: c.selectedIndexType,
                        selectedIndexRegiao: c.selectedIndexRegion,
                        totalAccidents: c.totalByType,
                        valorTotal: c.valorTotal,
                        // highlight por padrão; use applyFilter: true para filtrar de fato
                        onTypeSelected: (t) => c.onTypeSelected(t, applyFilter: false),
                        onRegionTap:   (r) => c.onRegionSelected(r, applyFilter: false),
                      ),
                      const SizedBox(height: 8),
                      const DividerText(title: 'Filtro por ano'),
                      const SizedBox(height: 8),
                      AccidentsSelectorSection(
                        allData: c.allData,
                        onFilterChanged: (_, y, m) => c.onSelectorChanged(year: y, month: m),
                      ),
                      const SizedBox(height: 8),
                      const DividerText(
                        title: 'Mapa da incidência de acidentes por município',
                      ),
                      const SizedBox(height: 8),

                      // Mapa “burro”: lógica/cores/dados vêm do controller
                      AccidentsMapSection(
                        regionalPolygons: c.regionalPolygons,
                        selectedRegionNames: c.selectedRegionName != null
                            ? [c.selectedRegionName!.toUpperCase()]
                            : [],
                        onRegionTap: c.onRegionSelected,
                        regionColors: c.regionColorsForMap,
                        fetchCityData: c.fetchCityAccidents,
                      ),
                    ],
                  ),
                ),
              ),
              const FootBar(),
            ],
          ),

          // Overlay de loading leve (não bloqueia layout)
          if (c.loading)
            Positioned.fill(
              child: IgnorePointer(
                ignoring: true,
                child: Container(
                  color: Colors.transparent,
                  alignment: Alignment.topRight,
                  padding: const EdgeInsets.all(12),
                  child: const SizedBox(
                    width: 26, height: 26,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
