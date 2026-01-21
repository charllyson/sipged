// lib/screens/modules/traffic/overview-dashboard/accidents_dashboard_network_page.dart
import 'dart:math' as math;

import 'package:diacritic/diacritic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siged/_blocs/modules/planning/geo/ibge_location/ibge_localidade_repository.dart';

// Infra UI
import 'package:siged/_widgets/menu/upBar/up_bar.dart';
import 'package:siged/screens/modules/traffic/dashboard/accidents_analytics_panel.dart';
import 'package:siged/screens/modules/traffic/dashboard/accidents_map_panel.dart';

// Split responsivo
import 'package:siged/_widgets/layout/split_layout/split_layout.dart';

// Mapa (reuso)
import 'package:siged/_widgets/map/polygon/polygon_changed.dart';

// Cubit
import 'package:siged/_blocs/modules/transit/accidents/accidents_cubit.dart';
import 'package:siged/_blocs/modules/transit/accidents/accidents_state.dart';

enum RightPanelMode { none, map }

class AccidentsDashboardNetworkPage extends StatefulWidget {
  const AccidentsDashboardNetworkPage({super.key});

  @override
  State<AccidentsDashboardNetworkPage> createState() =>
      _AccidentsDashboardNetworkPageState();
}

class _AccidentsDashboardNetworkPageState
    extends State<AccidentsDashboardNetworkPage> {
  RightPanelMode _mode = RightPanelMode.map;
  bool _inited = false;

  // Geo/Mapa
  List<PolygonChanged> _regionalPolygons = [];

  // ✅ NOVO: repositório de malhas IBGE (com cache em memória)
  late final IBGELocationRepository _geoRepo = IBGELocationRepository();

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

    // Warmup dos dados via Cubit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _inited) return;

      // 👉 warmup SEM filtros: carrega todos os anos/meses/cidades
      context.read<AccidentsCubit>().warmup();
      _inited = true;
    });

    _warmupPolygons();
  }

  // ====== AGORA BUSCA POLÍGONOS NA API DO IBGE (UF = 27 / ALAGOAS) ======
  Future<void> _warmupPolygons() async {
    try {
      // 27 = código IBGE de Alagoas
      final polys = await _geoRepo.getMunicipioPolygonsByUf(27);

      if (!mounted) return;
      setState(() => _regionalPolygons = polys);
    } catch (e) {
      if (!mounted) return;
      setState(() => _regionalPolygons = const []);
    }
  }

  void _clearFilters() {
    context.read<AccidentsCubit>().changeFilter(
      year: null,
      month: null,
      city: null,
    );
  }

  void _toggleMapPanel() {
    setState(() {
      _mode = (_mode == RightPanelMode.map)
          ? RightPanelMode.none
          : RightPanelMode.map;
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
    if (polygons.isEmpty) return {};

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

    // Garante cor para todas as cidades do GeoJSON/API, mesmo sem acidentes
    for (final poly in polygons) {
      final key = _normalizeCity(poly.title);
      colors.putIfAbsent(key, () => zeroColor);
    }

    return colors;
  }

  @override
  Widget build(BuildContext context) {
    final showRightPanel = _mode != RightPanelMode.none;

    return Scaffold(
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
      body: BlocBuilder<AccidentsCubit, AccidentsState>(
        builder: (context, state) {
          final regionColors = _buildRegionColors(
            totalsByCity: state.totalsByCity,
            palette: _heatmapPalette,
            zeroColor: _zeroValueColor,
            useLog: _useLogScale,
            polygons: _regionalPolygons,
          );

          const left = AccidentsAnalyticsPanel();

          final right = (_mode == RightPanelMode.map)
              ? AccidentsMapPanel(
            state: state,
            regionalPolygons: _regionalPolygons,
            regionColors: regionColors,
          )
              : const SizedBox.shrink();

          return SplitLayout(
            left: left,
            right: right,
            showRightPanel: showRightPanel,
            rightPanelWidth: 600.0,
            bottomPanelHeight: 420.0,
            showDividers: true,
            dividerThickness: 12.0,
            dividerBackgroundColor: Colors.white,
            dividerBorderColor: Colors.black12,
            gripColor: const Color(0xFF9E9E9E),
            stackedRightOnTop: true,
          );
        },
      ),
    );
  }
}
