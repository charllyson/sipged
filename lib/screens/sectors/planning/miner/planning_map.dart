import 'dart:async';
import 'dart:math' as math;

import 'package:diacritic/diacritic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:siged/_services/geography/ana_rain/ana_station_data.dart';

// SIGMINE
import 'package:siged/_services/geography/sig_miner/sigmine_data.dart';
import 'package:siged/_services/geometry/geometry_utils.dart';

import 'package:siged/_widgets/input/drop_down_botton_change.dart';
import 'package:siged/_widgets/map/flutter_map/map_interactive.dart';
import 'package:siged/_widgets/map/polygon/polygon_changed.dart';
import 'package:siged/_widgets/map/tooltip/tooltip_animated_card.dart';
import 'package:siged/_widgets/map/tooltip/tooltip_balloon_tip.dart';
import 'package:siged/_widgets/map/polylines/tappable_changed_polyline.dart';

class PlanningMap extends StatefulWidget {
  const PlanningMap({
    super.key,
    // SIGMINE
    required this.featuresAtivos,
    required this.mineriosAtivos,
    required this.getColorForMinerio,
    required this.onRegionTap,
    required this.onControllerReady,
    // callback opcional para mudanças de câmera (centro / zoom)
    this.onCameraChanged,
    // UF selector
    required this.ufs,
    required this.selectedUF,
    required this.loading,
    required this.onChangeUF,
    // Detalhes SIGMINE
    required this.onRequestDetails,
    required this.onRequestDetailsByProcess,
    required this.showSigmine,
    // IBGE – geometria
    required this.ibgeCityPolygons,
    required this.showIbgeCities,
    // IBGE – agregados (choropleth)
    this.showIbgeStats = false,
    this.ibgeStatsValues = const <String, double>{},
    // clique em município
    this.onMunicipioTap,
    // mapa base
    this.selectedBaseIndex,
    // RODOVIAS – OSM (já como TappableChangedPolyline)
    this.roadPolylines = const <TappableChangedPolyline>[],
    this.showRoads = false,
    // PLUVIOMETRIA – estações com chuva mensal (ANA)
    this.showPluviometria = false,
  });

  // SIGMINE
  final List<SigMineData> featuresAtivos;
  final Set<String> mineriosAtivos;
  final Color Function(String nome) getColorForMinerio;
  final void Function(String? region) onRegionTap;
  final void Function(MapController controller) onControllerReady;

  /// Opcional: chamado sempre que a câmera muda (pan/zoom).
  final void Function(LatLng center, double zoom)? onCameraChanged;

  // UF selector
  final List<String> ufs;
  final String? selectedUF;
  final bool loading;
  final void Function(String uf) onChangeUF;

  // Detalhes SIGMINE
  final void Function(SigMineData feature) onRequestDetails;
  final void Function(String processo) onRequestDetailsByProcess;

  final bool showSigmine;

  // IBGE – geometria (já em PolygonChanged)
  final List<PolygonChanged> ibgeCityPolygons;
  final bool showIbgeCities;

  // IBGE – agregados (valores por município, usando idIbge)
  final bool showIbgeStats;
  final Map<String, double> ibgeStatsValues;

  /// Chamado quando o usuário clica em um polígono de MUNICÍPIO (IBGE).
  /// Recebe o `idIbge` daquele município.
  final void Function(String idIbge)? onMunicipioTap;

  /// Índice do mapa base selecionado em MapBaseLayer.mapBase (ou null).
  final int? selectedBaseIndex;

  /// Rodovias já prontas como polylines clicáveis (OSM).
  final List<TappableChangedPolyline> roadPolylines;

  /// Flag geral de visibilidade das rodovias.
  final bool showRoads;

  /// Flag geral de visibilidade da camada de Pluviometria (heatmap).
  final bool showPluviometria;

  @override
  State<PlanningMap> createState() => _PlanningMapState();
}

class _PlanningMapState extends State<PlanningMap> {
  MapController? _controller;
  StreamSubscription<MapEvent>? _mapSubscription;

  // lookup por processo (normalizado) para SIGMINE
  late Map<String, SigMineData> _byProcess;

  // tooltip SIGMINE
  String? _selectedProcesso;
  LatLng? _tooltipAnchor;
  Offset? _tooltipScreenPos;
  String _tooltipTitle = '';
  String? _tooltipSubtitle;

  // município IBGE selecionado (para lógica externa, não mais para estilo)
  String? _selectedMunicipioTitle;

  // layout tooltip
  static const double _cardMaxWidth = 260;
  static const double _cardEstimatedHeight = 130;
  static const double _balloonHeight = 6;
  static const double _yOffset = 4;

  // controller para o dropdown de UF
  late final TextEditingController _ufController;

  String _normProc(String s) =>
      s.replaceAll(RegExp(r'\s+'), ' ').trim();

  @override
  void initState() {
    super.initState();
    _ufController = TextEditingController(text: widget.selectedUF ?? '');
    _rebuildIndex();
  }

  @override
  void didUpdateWidget(covariant PlanningMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.featuresAtivos != widget.featuresAtivos) {
      _rebuildIndex();
      _recomputeTooltipScreenPos(_controller);
    }

    if (oldWidget.selectedUF != widget.selectedUF) {
      final newText = widget.selectedUF ?? '';
      if (_ufController.text != newText) {
        _ufController.text = newText;
      }
    }
  }

  @override
  void dispose() {
    _mapSubscription?.cancel();
    _ufController.dispose();
    super.dispose();
  }

  void _rebuildIndex() {
    _byProcess = {
      for (final f in widget.featuresAtivos) _normProc(f.processo): f,
    };
  }

  SigMineData? _resolveProcess(String raw) {
    final key = _normProc(raw);
    if (_byProcess.containsKey(key)) return _byProcess[key];

    final low = key.toLowerCase();
    for (final e in _byProcess.entries) {
      if (e.key.toLowerCase() == low) return e.value;
    }
    for (final e in _byProcess.entries) {
      if (e.key.toLowerCase().startsWith(low)) return e.value;
    }
    return null;
  }

  // -------- tooltip SIGMINE --------
  void _openTooltipForProcess(String processoRaw) {
    final f = _resolveProcess(processoRaw);
    if (f == null) return;

    setState(() {
      _selectedProcesso = _normProc(f.processo);
      _selectedMunicipioTitle = null;
      _tooltipAnchor = f.labelPoint;
      _tooltipTitle = f.processo;

      final fase = (f.fase ?? '').trim();
      final titular = (f.titular ?? '').trim();
      final subs = (f.substancia ?? '').trim();

      final parts = [
        if (subs.isNotEmpty) subs,
        if (fase.isNotEmpty) fase,
        if (titular.isNotEmpty) titular,
      ];
      _tooltipSubtitle = parts.isEmpty ? null : parts.join(' • ');
    });

    _recomputeTooltipScreenPos(_controller);
  }

  void _closeTooltip() {
    setState(() {
      _selectedProcesso = null;
      _tooltipAnchor = null;
      _tooltipScreenPos = null;
      _tooltipTitle = '';
      _tooltipSubtitle = null;
    });
  }

  void _recomputeTooltipScreenPos(MapController? mapController) {
    if (_tooltipAnchor == null || mapController == null) return;
    final cam = mapController.camera;
    final pos = MapMath.latLngToScreen(cam, _tooltipAnchor!);
    setState(() => _tooltipScreenPos = pos);
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    // --------- SIGMINE: monta polígonos ----------
    final sigminePolygons = _buildSigminePolygons();

    // cores de legenda por substância (SIGMINE)
    final Map<String, Color> sigmineColors = _buildSigmineLegendColors();

    // --------- IBGE: mapa de cores (neutro ou por indicador) ----------
    final Map<String, Color> ibgeColors = _buildIbgeChoroplethColors();


    // Combina cores de SIGMINE + IBGE para a legenda
    final Map<String, Color> polygonColors = {
      ...ibgeColors,
      ...sigmineColors,
      // heatmap não entra na legenda nominal (opcional)
    };

    // --------- IBGE: aplica estilo normal/selecionado ----------
    final ibgePolygonsStyled = _buildIbgeStyledPolygons(ibgeColors);

    // Lista final de polígonos
    final allPolygons = <PolygonChanged>[
      if (widget.showIbgeCities) ...ibgePolygonsStyled,
      if (widget.showSigmine) ...sigminePolygons,
    ];

    // --------- RODOVIAS (OSM): usa lista já pronta / filtrada ----------
    final tappableRoads = widget.showRoads
        ? widget.roadPolylines
        : const <TappableChangedPolyline>[];

    return Stack(
      children: [
        MapInteractivePage<void>(
          activeMap: true,
          showLegend: false,
          showSearch: true,
          showMyLocation: true,
          showChangeMapType: false, // base vem de selectedBaseIndex externo
          polygonsChanged: allPolygons,
          polygonChangeColors: polygonColors, // opcional para legenda
          tappablePolylines: tappableRoads,
          allowMultiSelect: false,
          onRegionTap: _handleRegionTap,
          onControllerReady: (c) {
            _controller = c;
            widget.onControllerReady(c);

            _mapSubscription?.cancel();
            _mapSubscription = _controller!.mapEventStream.listen((_) {
              _recomputeTooltipScreenPos(_controller);

              final cam = _controller!.camera;
              widget.onCameraChanged?.call(cam.center, cam.zoom);
            });
          },
          selectedBaseIndex: widget.selectedBaseIndex,
        ),

        // seletor de UF
        Positioned(
          top: 16,
          right: 16,
          child: DropDownButtonChange(
            controller: _ufController,
            items: widget.ufs,
            onChanged: (uf) {
              if (uf == null) return;
              widget.onChangeUF(uf);
              _closeTooltip();
              setState(() {
                _selectedMunicipioTitle = null;
              });
            },
            labelText: 'Selecione a UF',
          ),
        ),

        // tooltip ancorado no labelPoint do PROCESSO (apenas SIGMINE)
        if (_tooltipAnchor != null && _tooltipScreenPos != null)
          Positioned(
            left: _tooltipScreenPos!.dx - (_cardMaxWidth / 2),
            top: _tooltipScreenPos!.dy -
                (_cardEstimatedHeight + _balloonHeight + _yOffset),
            child: IgnorePointer(
              ignoring: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TooltipAnimatedCard(
                    title: _tooltipTitle,
                    subtitle: _tooltipSubtitle,
                    maxWidth: _cardMaxWidth,
                    onDetails: () {
                      widget.onRequestDetailsByProcess(_tooltipTitle);
                    },
                    onClose: _closeTooltip,
                  ),
                  const TooltipBalloonTip(
                    color: Colors.black87,
                    height: _balloonHeight,
                    width: 12,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // HELPERS DE CONSTRUÇÃO
  // ---------------------------------------------------------------------------

  List<PolygonChanged> _buildSigminePolygons() {
    return widget.featuresAtivos.map((f) {
      final minerioNorm = removeDiacritics((f.substancia ?? 'INDEFINIDO'))
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim()
          .toUpperCase();

      final base = widget.getColorForMinerio(minerioNorm);

      return PolygonChanged(
        title: f.processo,
        polygon: Polygon(
          points: f.polygon.points,
        ),
        // estilo normal
        normalFillColor: base.withOpacity(0.45),
        normalBorderColor: base.withOpacity(0.95),
        normalBorderWidth: 0.8,
        // estilo selecionado (quando o usuário clica no processo)
        selectedFillColor: base.withOpacity(0.75),
        selectedBorderColor: Colors.black,
        selectedBorderWidth: 2.0,
        properties: [
          {'processo': _normProc(f.processo)},
          {'minerio': minerioNorm},
          {'fase': (f.fase ?? '').trim()},
          {'titular': (f.titular ?? '').trim()},
        ],
      );
    }).toList();
  }

  Map<String, Color> _buildSigmineLegendColors() {
    final Map<String, Color> sigmineColors = {};

    for (final f in widget.featuresAtivos) {
      final key = removeDiacritics((f.substancia ?? 'INDEFINIDO'))
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim()
          .toUpperCase();

      sigmineColors[key] = widget.getColorForMinerio(key);
    }
    return sigmineColors;
  }

  Map<String, Color> _buildIbgeChoroplethColors() {
    final Map<String, Color> ibgeColors = {};

    if (!widget.showIbgeCities) return ibgeColors;

    final hasStats =
        widget.showIbgeStats && widget.ibgeStatsValues.isNotEmpty;
    double? minVal;
    double? maxVal;

    if (hasStats) {
      for (final v in widget.ibgeStatsValues.values) {
        minVal = (minVal == null) ? v : math.min(minVal!, v);
        maxVal = (maxVal == null) ? v : math.max(maxVal!, v);
      }
    }

    for (final p in widget.ibgeCityPolygons) {
      final title = p.title.isEmpty ? 'MUNICIPIO_SEM_NOME' : p.title;
      Color base = Colors.white;

      if (hasStats && (p.properties ?? const []).isNotEmpty) {
        String? idIbge;

        final propsList = p.properties ?? const [];
        for (final props in propsList) {
          if (props is Map<String, dynamic> && props['idIbge'] != null) {
            idIbge = props['idIbge'].toString();
            break;
          }
        }

        if (idIbge != null &&
            widget.ibgeStatsValues.containsKey(idIbge) &&
            minVal != null &&
            maxVal != null &&
            maxVal > minVal) {
          final v = widget.ibgeStatsValues[idIbge]!;
          final t =
          ((v - minVal) / (maxVal - minVal)).clamp(0.0, 1.0);

          base = Color.lerp(
            Colors.yellow.shade200,
            Colors.red.shade800,
            t,
          )!
              .withOpacity(0.80);
        }
      }

      ibgeColors[title] = base;
    }

    return ibgeColors;
  }

  List<PolygonChanged> _buildIbgeStyledPolygons(
      Map<String, Color> ibgeColors,
      ) {
    if (!widget.showIbgeCities) return const [];

    return widget.ibgeCityPolygons.map((p) {
      final basePoly = p.polygon;
      final String title =
      p.title.isEmpty ? 'MUNICIPIO_SEM_NOME' : p.title;
      final baseColor = ibgeColors[title] ?? Colors.white;

      return PolygonChanged(
        title: p.title,
        polygon: Polygon(
          points: basePoly.points,
        ),
        // normal: cor do choropleth + borda cinza
        normalFillColor: baseColor,
        normalBorderColor: Colors.grey.shade300,
        normalBorderWidth: 2.0,
        // selecionado: vermelho (interior e borda)
        selectedFillColor: Colors.red.withOpacity(0.25),
        selectedBorderColor: Colors.red,
        selectedBorderWidth: 3.0,
        properties: p.properties,
        mapColors: p.mapColors,
      );
    }).toList();
  }

  // --------------- HEATMAP PLUVIOMETRIA (IDW SIMPLES) ---------------


  // ---------------------------------------------------------------------------
  // HANDLER DE CLIQUE NO MAPA (polígonos)
  // ---------------------------------------------------------------------------
  void _handleRegionTap(String? regionTitle) {
    if (regionTitle == null) {
      // Deseleção geral
      _closeTooltip();
      setState(() {
        _selectedMunicipioTitle = null;
      });
      widget.onRegionTap(null);
      return;
    }

    // 1) Tenta interpretar como PROCESSO SIGMINE
    final f = _resolveProcess(regionTitle);
    if (f != null) {
      _openTooltipForProcess(regionTitle);
      setState(() {
        _selectedMunicipioTitle = null;
      });
      widget.onRegionTap(regionTitle);
      return;
    }

    // 2) Não é processo conhecido => trata como MUNICÍPIO IBGE
    _closeTooltip();

    if (widget.onMunicipioTap != null && widget.showIbgeCities) {
      final target = regionTitle.trim().toUpperCase();

      PolygonChanged? found;
      for (final p in widget.ibgeCityPolygons) {
        final title = p.title.trim().toUpperCase();
        if (title == target) {
          found = p;
          break;
        }
      }

      if (found != null) {
        setState(() {
          _selectedMunicipioTitle = found!.title;
        });

        String? idIbge;
        final propsList = found.properties ?? const <dynamic>[];

        for (final props in propsList) {
          if (props is Map<String, dynamic> &&
              props['idIbge'] != null) {
            idIbge = props['idIbge'].toString();
            break;
          }
        }

        if (idIbge != null) {
          widget.onMunicipioTap!(idIbge);
        }
      }
    }
  }
}
