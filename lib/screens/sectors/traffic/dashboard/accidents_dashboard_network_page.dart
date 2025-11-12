// lib/screens/sectors/traffic/overview-dashboard/accidents_dashboard_network_page.dart
import 'dart:math' as math;
import 'package:diacritic/diacritic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Infra UI
import 'package:siged/_widgets/upBar/up_bar.dart';
import 'package:siged/screens/sectors/traffic/dashboard/accidents_analytics_panel.dart';
import 'package:siged/screens/sectors/traffic/dashboard/accidents_map_panel.dart';

// Split responsivo (NOVO)
import 'package:siged/_widgets/layout/responsive_split_view.dart';

// Mapa (reuso)
import 'package:siged/_widgets/map/polygon/polygon_changed.dart';
import 'package:siged/_services/geoJson/geo_json_service.dart';

// Bloc
import 'package:siged/_blocs/sectors/transit/accidents/accidents_bloc.dart';
import 'package:siged/_blocs/sectors/transit/accidents/accidents_event.dart';
import 'package:siged/_blocs/sectors/transit/accidents/accidents_state.dart';

enum RightPanelMode { none, map }

class AccidentsDashboardNetworkPage extends StatefulWidget {
  const AccidentsDashboardNetworkPage({super.key});

  @override
  State<AccidentsDashboardNetworkPage> createState() => _AccidentsDashboardNetworkPageState();
}

class _AccidentsDashboardNetworkPageState extends State<AccidentsDashboardNetworkPage> {
  late final AccidentsBloc _bloc;

  RightPanelMode _mode = RightPanelMode.map;

  // Geo/Mapa
  List<PolygonChanged> _regionalPolygons = [];
  final List<Color> _heatmapPalette = const [
    Color(0xFFFFF59D), // amarelo claro
    Color(0xFFFFB300), // laranja
    Color(0xFFD32F2F), // vermelho
  ];
  final Color _zeroValueColor = Colors.grey;
  bool _useLogScale = false;

  @override
  void initState() {
    super.initState();
    _bloc = AccidentsBloc()..add(AccidentsWarmupRequested(initialYear: DateTime.now().year));
    _warmupPolygons();
  }

  Future<void> _warmupPolygons() async {
    final polys = await GeoJsonService.loadServicePolygonsOfCitiesAL(
      assetPath: 'assets/geojson/limits/limites_cidades_al.geojson',
    );
    if (!mounted) return;
    setState(() => _regionalPolygons = polys);
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  void _clearFilters() {
    _bloc.add(const AccidentsFilterChanged(year: null, month: null));
  }

  void _toggleMapPanel() {
    setState(() {
      _mode = (_mode == RightPanelMode.map) ? RightPanelMode.none : RightPanelMode.map;
    });
  }

  // ===== helpers para o heatmap =====
  String _normalizeCity(String? nome) {
    if (nome == null) return '';
    final noAccent = removeDiacritics(nome);
    final noMultipleSpace = noAccent.replaceAll(RegExp(r'\s+'), ' ');
    return noMultipleSpace.trim().toUpperCase();
  }

  Map<String, Color> _buildRegionColors({
    required Map<String, double> totalsByCity,
    required List<Color> palette,
    required Color zeroColor,
    required bool useLog,
    required List<PolygonChanged> polygons,
  }) {
    final counts = <String, int>{};
    for (final e in totalsByCity.entries) {
      counts[_normalizeCity(e.key)] = (e.value).round();
    }

    int maxRaw = 0;
    for (final v in counts.values) {
      if (v > maxRaw) maxRaw = v;
    }
    double normMax = useLog ? math.log(maxRaw + 1) : maxRaw.toDouble();
    if (normMax <= 0) normMax = 1;

    Color lerp(double f) {
      final n = palette.length;
      if (n == 1) return palette.first;
      final scaled = f * (n - 1);
      final i = scaled.floor().clamp(0, n - 2);
      final t = scaled - i;
      return Color.lerp(palette[i], palette[i + 1], t)!;
    }

    final colors = <String, Color>{};
    for (final e in counts.entries) {
      final vNorm = useLog ? math.log(e.value + 1) : e.value.toDouble();
      final factor = (vNorm / normMax).clamp(0.0, 1.0);
      colors[e.key] = lerp(factor);
    }

    for (final poly in polygons) {
      final key = _normalizeCity(poly.title);
      colors.putIfAbsent(key, () => zeroColor);
    }
    return colors;
  }

  @override
  Widget build(BuildContext context) {
    final showRightPanel = _mode != RightPanelMode.none;

    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(74),
          child: UpBar(
            showPhotoMenu: true,
            actions: [
              IconButton(
                tooltip: 'Limpar filtros',
                icon: const Icon(Icons.filter_alt_off, color: Colors.white),
                onPressed: _clearFilters,
              ),
              IconButton(
                tooltip: showRightPanel ? 'Ocultar mapa' : 'Mostrar mapa',
                icon: Icon(
                  showRightPanel ? Icons.map : Icons.map_outlined,
                  color: Colors.white,
                ),
                onPressed: _toggleMapPanel,
              ),
            ],
          ),
        ),
        body: BlocBuilder<AccidentsBloc, AccidentsState>(
          builder: (context, state) {
            final regionColors = _buildRegionColors(
              totalsByCity: state.totalsByCity,
              palette: _heatmapPalette,
              zeroColor: _zeroValueColor,
              useLog: _useLogScale,
              polygons: _regionalPolygons,
            );

            // Painel esquerdo: analytics sempre presente
            const left = AccidentsAnalyticsPanel();

            // Painel direito: mapa condicional
            final right = (_mode == RightPanelMode.map)
                ? AccidentsMapPanel(
              state: state,
              regionalPolygons: _regionalPolygons,
              regionColors: regionColors,
            )
                : const SizedBox.shrink();

            // Split responsivo (lado a lado >= breakpoint; empilhado < breakpoint)
            return ResponsiveSplitView(
              left: left,
              right: right,
              showRightPanel: showRightPanel,
              breakpoint: 980.0,
              rightPanelWidth: 600.0,   // alvo no wide
              bottomPanelHeight: 420.0, // alvo no stacked
              showDividers: true,
              dividerThickness: 12.0,
              dividerBackgroundColor: Colors.white,
              dividerBorderColor: Colors.black12,
              gripColor: const Color(0xFF9E9E9E),
            );
          },
        ),
      ),
    );
  }
}
