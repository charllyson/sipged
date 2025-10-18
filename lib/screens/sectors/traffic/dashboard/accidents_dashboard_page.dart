// lib/screens/sectors/traffic/overview-dashboard/accidents_dashboard_page.dart
import 'dart:math' as math;
import 'package:diacritic/diacritic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Infra UI
import 'package:siged/_widgets/upBar/up_bar.dart';
import 'package:siged/screens/sectors/traffic/dashboard/accidents_analytics_panel.dart';
import 'package:siged/screens/sectors/traffic/dashboard/accidents_map_panel.dart';

// Mapa (reuso)
import 'package:siged/_widgets/map/polygon/polygon_changed.dart';
import 'package:siged/_services/geo_json_service.dart';

// Bloc
import 'package:siged/_blocs/sectors/transit/accidents/accidents_bloc.dart';
import 'package:siged/_blocs/sectors/transit/accidents/accidents_event.dart';
import 'package:siged/_blocs/sectors/transit/accidents/accidents_state.dart';

// ===================== Scaffold com painel lateral =====================

enum RightPanelMode { none, map }

class AccidentsDashboardPage extends StatefulWidget {
  const AccidentsDashboardPage({super.key});

  @override
  State<AccidentsDashboardPage> createState() => _AccidentsDashboardPageState();
}

class _AccidentsDashboardPageState extends State<AccidentsDashboardPage> {
  late final AccidentsBloc _bloc;

  RightPanelMode _mode = RightPanelMode.map;

  // Split do painel direito (wide) — fração da largura total (0..1). Começa em 50%.
  double _splitH = 0.49;

  // Split vertical (small) — fração da ALTURA total para o painel do mapa (0..1). Começa em 50%.
  double _splitV = 0.35;

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
            // Cores do mapa (derivadas do state atual)
            final regionColors = _buildRegionColors(
              totalsByCity: state.totalsByCity,
              palette: _heatmapPalette,
              zeroColor: _zeroValueColor,
              useLog: _useLogScale,
              polygons: _regionalPolygons,
            );

            // Painel da direita (mapa)
            Widget? rightPane;
            if (_mode == RightPanelMode.map) {
              rightPane = AccidentsMapPanel(
                state: state,
                regionalPolygons: _regionalPolygons,
                regionColors: regionColors,
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final bool isWide = constraints.maxWidth >= 980;

                if (!isWide) {
                  // ================== SMALL: divisor VERTICAL arrastável ==================
                  if (rightPane == null) {
                    // Sem painel: apenas analytics
                    return const AccidentsAnalyticsPanel();
                  }

                  // Altura disponível nesta área
                  final double totalH = constraints.maxHeight;
                  const double minBottom = 260.0;                        // altura mínima do mapa
                  final double maxBottom = (totalH * 0.9).clamp(300.0, totalH); // máxima segura

                  // altura atual do mapa baseada no split
                  double bottomH = (_splitV * totalH).clamp(minBottom, maxBottom);
                  final double clampedV = bottomH / totalH;
                  if (clampedV != _splitV) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _splitV = clampedV);
                    });
                  }

                  // handle vertical
                  final Widget vHandle = MouseRegion(
                    cursor: SystemMouseCursors.resizeRow,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onDoubleTap: () => setState(() => _splitV = 0.5), // reset 50%
                      onVerticalDragUpdate: (details) {
                        final double hNow = (_splitV * totalH);
                        final double newH = (hNow + details.delta.dy)   // dy > 0 (baixo) => aumenta
                            .clamp(minBottom, maxBottom);
                        setState(() {
                          _splitV = newH / totalH;
                        });
                      },
                      child: Container(
                        height: 10,
                        color: Colors.white,
                        child: Center(
                          child: Container(width: double.infinity, height: 1, color: Colors.blue),
                        ),
                      ),
                    ),
                  );

                  return Column(
                    children: [
                      // Fundo (mapa) com altura ajustável
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 80),
                        curve: Curves.easeOut,
                        height: bottomH,
                        width: double.infinity,
                        child: rightPane,
                      ),
                      vHandle,
                      // Topo (analytics) ocupa o restante
                      const Expanded(child: AccidentsAnalyticsPanel()),
                      // Handle vertical
                    ],
                  );
                }

                // ================== WIDE: divisor HORIZONTAL arrastável ==================
                const double minRight = 420.0;
                final double maxRight = constraints.maxWidth * 0.80;

                // largura atual do painel direito baseada no split
                final double currentRightWidth =
                (_splitH * constraints.maxWidth).clamp(minRight, maxRight);

                // se clampou, sincroniza split
                final double clampedH = currentRightWidth / constraints.maxWidth;
                if (clampedH != _splitH) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _splitH = clampedH);
                  });
                }

                // handle horizontal
                final Widget hHandle = MouseRegion(
                  cursor: SystemMouseCursors.resizeColumn,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onDoubleTap: () => setState(() => _splitH = 0.5), // reset 50%
                    onHorizontalDragUpdate: (details) {
                      // Em LTR: arrastar para ESQUERDA => AUMENTA painel direito
                      final dir = Directionality.of(context);
                      final sign = (dir == TextDirection.ltr) ? -1.0 : 1.0;
                      final double widthNow = (_splitH * constraints.maxWidth);
                      final double newWidth = (widthNow + sign * details.delta.dx).clamp(minRight, maxRight);
                      setState(() {
                        _splitH = newWidth / constraints.maxWidth;
                      });
                    },
                    child: Container(
                      width: 10,
                      color: Colors.white,
                      child: Center(
                        child: Container(width: 1, height: double.infinity, color: Colors.blue),
                      ),
                    ),
                  ),
                );

                return Row(
                  children: [
                    // painel esquerdo ocupa o restante
                    const Expanded(child: AccidentsAnalyticsPanel()),
                    // divisor/handle
                    hHandle,
                    // painel direito (mapa) com largura ajustável
                    if (rightPane != null)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 80),
                        curve: Curves.easeOut,
                        width: currentRightWidth,
                        child: rightPane,
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}


