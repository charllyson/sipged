// lib/screens/sectors/traffic/dashboard/accidents_dashboard_page.dart
import 'dart:math' as math;
import 'package:diacritic/diacritic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_widgets/background/background_cleaner.dart';
import 'package:siged/screens/sectors/traffic/dashboard/accidents_selector_section.dart';
import 'package:siged/screens/sectors/traffic/dashboard/accidents_summary_section.dart';
import 'package:siged/_widgets/texts/divider_text.dart';
import 'package:siged/_widgets/footBar/foot_bar.dart';
import 'package:siged/_widgets/upBar/up_bar.dart';
import 'accidents_charts_section.dart';
import 'accident_map_section.dart';

// Bloc
import 'package:siged/_blocs/sectors/transit/accidents/accidents_bloc.dart';
import 'package:siged/_blocs/sectors/transit/accidents/accidents_event.dart';
import 'package:siged/_blocs/sectors/transit/accidents/accidents_state.dart';
import 'package:siged/_blocs/sectors/transit/accidents/accidents_data.dart';

// Geo/Mapa helpers (antes ficavam no controller)
import 'package:siged/_services/geo_json_service.dart';
import 'package:siged/_widgets/map/polygon/polygon_changed.dart';

class AccidentsDashboardPage extends StatelessWidget {
  const AccidentsDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _AccidentsDashboardScaffold();
  }
}

class _AccidentsDashboardScaffold extends StatefulWidget {
  const _AccidentsDashboardScaffold();

  @override
  State<_AccidentsDashboardScaffold> createState() => _AccidentsDashboardScaffoldState();
}

class _AccidentsDashboardScaffoldState extends State<_AccidentsDashboardScaffold> {
  bool _didInit = false;

  // ========= estado local (substitui o antigo controller) =========
  List<PolygonChanged> _regionalPolygons = [];
  String? _selectedRegionName;
  String? _selectedTypeName;
  int? _selectedIndexRegion;
  int? _selectedIndexType;

  // paleta para o heatmap (similar ao controller antigo)
  List<Color> _heatmapPalette = const [
    Color(0xFFFFF59D), // amarelo claro
    Color(0xFFFFB300), // laranja
    Color(0xFFD32F2F), // vermelho
  ];
  final Color _zeroValueColor = const Color(0xFF2E7D32); // verde para “0”
  bool _useLogScale = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _didInit) return;
      _didInit = true;

      // Warmup do Bloc (filtros padrão: ano atual)
      context.read<AccidentsBloc>().add(
        AccidentsWarmupRequested(initialYear: DateTime.now().year),
      );

      // Carrega limites municipais de AL (para o mapa)
      final polys = await GeoJsonService.loadServicePolygonsOfCitiesAL(
        assetPath: 'assets/geojson/limits/limites_cidades_al.geojson',
      );
      if (mounted) setState(() => _regionalPolygons = polys);
    });
  }

  // ========= normalização (cidades sem acento/uppercase) =========
  String _normalizeCity(String? nome) {
    if (nome == null) return '';
    final noAccent = removeDiacritics(nome);
    final noMultipleSpace = noAccent.replaceAll(RegExp(r'\s+'), ' ');
    return noMultipleSpace.trim().toUpperCase();
  }

  // ========= construção das cores do mapa a partir dos totais =========
  Map<String, Color> _regionColors(Map<String, double> totalsByCity) {
    // conta por cidade já está em UPPERCASE no state (proveniente do repo),
    // mas normalizamos por segurança
    final counts = <String, int>{};
    for (final e in totalsByCity.entries) {
      final key = _normalizeCity(e.key);
      counts[key] = (e.value).round();
    }

    // máxima incidência (normalizada/log se necessário)
    int maxRaw = 0;
    for (final v in counts.values) {
      if (v > maxRaw) maxRaw = v;
    }
    double normMax = _useLogScale ? math.log(maxRaw + 1) : maxRaw.toDouble();
    if (normMax <= 0) normMax = 1;

    Color interpolate(double factor) {
      final n = _heatmapPalette.length;
      if (n == 1) return _heatmapPalette.first;
      final scaled = factor * (n - 1);
      final i = scaled.floor().clamp(0, n - 2);
      final t = scaled - i;
      return Color.lerp(_heatmapPalette[i], _heatmapPalette[i + 1], t)!;
    }

    final colors = <String, Color>{};
    for (final e in counts.entries) {
      final vNorm = _useLogScale ? math.log(e.value + 1) : e.value.toDouble();
      final factor = (vNorm / normMax).clamp(0.0, 1.0);
      colors[e.key] = interpolate(factor);
    }

    // completa com cidades sem acidentes → verde
    for (final poly in _regionalPolygons) {
      final key = _normalizeCity(poly.title);
      colors.putIfAbsent(key, () => _zeroValueColor);
    }
    return colors;
  }

  // ========= destaques (sem aplicar filtro global) =========
  void _onTypeSelectedLocal(String? typeName, List<String> labelsType) {
    if (typeName == null || typeName.toUpperCase() == _selectedTypeName?.toUpperCase()) {
      _selectedTypeName = null;
      _selectedIndexType = null;
    } else {
      _selectedTypeName = typeName;
      _selectedIndexType = labelsType.indexWhere((t) => t.toUpperCase() == typeName.toUpperCase());
    }
    setState(() {});
  }

  void _onRegionSelectedLocal(String? regionName, List<String> labelsRegiao) {
    if (regionName == null || regionName.toUpperCase() == _selectedRegionName?.toUpperCase()) {
      _selectedRegionName = null;
      _selectedIndexRegion = null;
    } else {
      _selectedRegionName = regionName;
      _selectedIndexRegion = labelsRegiao.indexWhere((r) => r.toUpperCase() == regionName.toUpperCase());
    }
    setState(() {});
  }

  // ========= busca por cidade (a partir da view atual do Bloc) =========
  Future<List<AccidentsData>> _fetchCityAccidentsFromState(
      AccidentsState st,
      String cityName,
      ) async {
    final key = _normalizeCity(cityName);
    return st.view.where((a) => _normalizeCity(a.city) == key).toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AccidentsBloc, AccidentsState>(
      builder: (context, state) {
        // dados para os cards/resumo
        final totalsByType = state.totalsByType; // Map<String,double>
        final totalsByCity = state.totalsByCity; // Map<String,double>

        // arrays para os gráficos
        final labelsType = totalsByType.entries.where((e) => e.value > 0).map((e) => e.key).toList();
        final valuesType = totalsByType.entries.where((e) => e.value > 0).map((e) => e.value).toList();

        final labelsRegiao =
        totalsByCity.entries.where((e) => e.value > 0).map((e) => e.key).toList();
        final valuesRegiao =
        totalsByCity.entries.where((e) => e.value > 0).map((e) => e.value).toList();

        // índices de highlight (mantidos localmente)
        _selectedIndexType = (_selectedTypeName == null)
            ? null
            : labelsType.indexWhere((t) => t.toUpperCase() == _selectedTypeName!.toUpperCase());
        _selectedIndexRegion = (_selectedRegionName == null)
            ? null
            : labelsRegiao.indexWhere((r) => r.toUpperCase() == _selectedRegionName!.toUpperCase());

        // totais agregados
        final valorTotal = state.all.length.toDouble();   // histórico total (universo carregado)
        final totalByType = state.view.length.toDouble(); // total no filtro atual (ano/mês/cidade)

        // cores para o mapa (derivadas de totalsByCity)
        final regionColors = _regionColors(totalsByCity);

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

                          // Resumo por tipos (usa o mesmo shape do controller antigo)
                          AccidentsSummarySection(
                            totalsByType: state.resumeByType,
                          ),

                          const SizedBox(height: 8),
                          const DividerText(title: 'Maiores índices por tipos e cidades'),
                          const SizedBox(height: 8),

                          AccidentsChartsSection(
                            labelsType: labelsType,
                            valuesType: valuesType,
                            labelsRegiao: labelsRegiao,
                            valuesRegiao: valuesRegiao,
                            selectedIndexType: _selectedIndexType,
                            selectedIndexRegiao: _selectedIndexRegion,
                            totalAccidents: totalByType,
                            valorTotal: valorTotal,
                            onTypeSelected: (t) => _onTypeSelectedLocal(t, labelsType),
                            onRegionTap:   (r) => _onRegionSelectedLocal(r, labelsRegiao),
                          ),

                          const SizedBox(height: 8),
                          const DividerText(title: 'Filtro por ano'),
                          const SizedBox(height: 8),

                          AccidentsSelectorSection(
                            allData: state.universe,   // ✅ sempre o universo completo
                            onFilterChanged: (_, y, m) {
                              context.read<AccidentsBloc>().add(
                                AccidentsFilterChanged(year: y, month: m),
                              );
                            },
                          ),

                          const SizedBox(height: 8),
                          const DividerText(
                            title: 'Mapa da incidência de acidentes por município',
                          ),
                          const SizedBox(height: 8),

                          // Mapa: dados/cores derivados do state; polígonos carregados localmente
                          AccidentsMapSection(
                            regionalPolygons: _regionalPolygons,
                            selectedRegionNames: _selectedRegionName != null
                                ? [_selectedRegionName!.toUpperCase()]
                                : const [],
                            onRegionTap: (name) => _onRegionSelectedLocal(name, labelsRegiao),
                            regionColors: regionColors,
                            fetchCityData: (city) => _fetchCityAccidentsFromState(state, city),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const FootBar(),
                ],
              ),

              // Overlay leve de loading (usa state.loading)
              if (state.loading)
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
      },
    );
  }
}
