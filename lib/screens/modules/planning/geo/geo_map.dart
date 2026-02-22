// lib/screens/modules/planning/geo/geo_map.dart
import 'dart:async';
import 'dart:math' as math;

import 'package:diacritic/diacritic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

// SIGMINE
import 'package:sipged/_blocs/modules/planning/geo/natural_resources/sig_miner/sigmine_data.dart';
import 'package:sipged/_utils/geometry/sipged_geo_math.dart';

import 'package:sipged/_widgets/input/drop_down_botton_change.dart';
import 'package:sipged/_widgets/map/flutter_map/map_interactive.dart';
import 'package:sipged/_widgets/map/polygon/polygon_changed.dart';
import 'package:sipged/_widgets/map/tooltip/tooltip_animated_card.dart';
import 'package:sipged/_widgets/map/tooltip/tooltip_balloon_tip.dart';
import 'package:sipged/_widgets/map/polylines/tappable_changed_polyline.dart';

// ✅ ENERGY
import 'package:sipged/_blocs/modules/planning/geo/productive_units/energy_plants/energy_plants_state.dart';

class GeoMap extends StatefulWidget {
  const GeoMap({
    super.key,
    // SIGMINE
    required this.featuresAtivos,
    required this.mineriosAtivos,
    required this.getColorForMinerio,
    required this.onRegionTap,
    required this.onControllerReady,
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

    // RODOVIAS – OSM
    this.roadPolylines = const <TappableChangedPolyline>[],
    this.showRoads = false,

    // ✅ ENERGY
    this.showUnitsEnergy = false,
    this.unitsEnergyMarkers = const <EnergyPlantMarkerData>[],
    this.onEnergyMarkerTap,

    // PLUVIOMETRIA
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

  // IBGE – geometria
  final List<PolygonChanged> ibgeCityPolygons;
  final bool showIbgeCities;

  // IBGE – agregados
  final bool showIbgeStats;
  final Map<String, double> ibgeStatsValues;

  /// clique em município
  final void Function(String idIbge)? onMunicipioTap;

  /// mapa base
  final int? selectedBaseIndex;

  /// Rodovias polylines
  final List<TappableChangedPolyline> roadPolylines;
  final bool showRoads;

  /// ✅ Energy markers
  final bool showUnitsEnergy;
  final List<EnergyPlantMarkerData> unitsEnergyMarkers;
  final void Function(EnergyPlantMarkerData item)? onEnergyMarkerTap;

  /// Pluviometria
  final bool showPluviometria;

  @override
  State<GeoMap> createState() => _GeoMapState();
}

class _GeoMapState extends State<GeoMap> {
  MapController? _controller;
  StreamSubscription<MapEvent>? _mapSubscription;

  late Map<String, SigMineData> _byProcess;

  // tooltip SIGMINE
  LatLng? _tooltipAnchor;
  Offset? _tooltipScreenPos;
  String _tooltipTitle = '';
  String? _tooltipSubtitle;

  // layout tooltip
  static const double _cardMaxWidth = 260;
  static const double _cardEstimatedHeight = 130;
  static const double _balloonHeight = 6;
  static const double _yOffset = 4;

  late final TextEditingController _ufController;

  String _normProc(String s) => s.replaceAll(RegExp(r'\s+'), ' ').trim();

  @override
  void initState() {
    super.initState();
    _ufController = TextEditingController(text: widget.selectedUF ?? '');
    _rebuildIndex();
  }

  @override
  void didUpdateWidget(covariant GeoMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.featuresAtivos != widget.featuresAtivos) {
      _rebuildIndex();
      _recomputeTooltipScreenPos(_controller);
    }

    if (oldWidget.selectedUF != widget.selectedUF) {
      final newText = widget.selectedUF ?? '';
      if (_ufController.text != newText) _ufController.text = newText;
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

  void _openTooltipForProcess(String processoRaw) {
    final f = _resolveProcess(processoRaw);
    if (f == null) return;

    setState(() {
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
      _tooltipAnchor = null;
      _tooltipScreenPos = null;
      _tooltipTitle = '';
      _tooltipSubtitle = null;
    });
  }

  void _recomputeTooltipScreenPos(MapController? mapController) {
    if (_tooltipAnchor == null || mapController == null) return;
    final cam = mapController.camera;
    final pos = SipGedGeoMath.latLngToScreen(cam, _tooltipAnchor!);
    setState(() => _tooltipScreenPos = pos);
  }

  // ✅ Converte as usinas para Markers e envia via extraMarkers.
  List<Marker> _buildEnergyExtraMarkers() {
    if (!widget.showUnitsEnergy || widget.unitsEnergyMarkers.isEmpty) {
      return const <Marker>[];
    }

    return widget.unitsEnergyMarkers.map((m) {
      return Marker(
        point: m.point,
        width: 34,
        height: 34,
        alignment: Alignment.center,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => widget.onEnergyMarkerTap?.call(m),
          child: Tooltip(
            message: m.name.trim().isNotEmpty ? m.name.trim() : 'Usina de energia',
            child: const SizedBox(
              width: 34,
              height: 34,
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // contorno branco (ícone maior atrás)
                    Icon(
                      Icons.bolt,
                      size: 32,
                      color: Colors.white,
                    ),
                    // ícone principal
                    Icon(
                      Icons.bolt,
                      size: 22,
                      color: Colors.orange,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final sigminePolygons = _buildSigminePolygons();
    final Map<String, Color> sigmineColors = _buildSigmineLegendColors();

    final Map<String, Color> ibgeColors = _buildIbgeChoroplethColors();

    final Map<String, Color> polygonColors = {
      ...ibgeColors,
      ...sigmineColors,
    };

    final ibgePolygonsStyled = _buildIbgeStyledPolygons(ibgeColors);

    final allPolygons = <PolygonChanged>[
      if (widget.showIbgeCities) ...ibgePolygonsStyled,
      if (widget.showSigmine) ...sigminePolygons,
    ];

    final tappableRoads = widget.showRoads
        ? widget.roadPolylines
        : const <TappableChangedPolyline>[];

    final extraMarkers = _buildEnergyExtraMarkers();

    return Stack(
      children: [
        MapInteractivePage<void>(
          activeMap: true,
          showLegend: false,
          showSearch: true,
          showMyLocation: true,
          showChangeMapType: false,

          polygonsChanged: allPolygons,
          polygonChangeColors: polygonColors,

          tappablePolylines: tappableRoads,

          // ✅ AQUI: usa o que o seu MapInteractive já suporta.
          extraMarkers: extraMarkers,

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
              setState(() {});
            },
            labelText: 'Selecione a UF',
          ),
        ),

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

  List<PolygonChanged> _buildSigminePolygons() {
    return widget.featuresAtivos.map((f) {
      final minerioNorm = removeDiacritics((f.substancia ?? 'INDEFINIDO'))
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim()
          .toUpperCase();

      final base = widget.getColorForMinerio(minerioNorm);

      return PolygonChanged(
        title: f.processo,
        polygon: Polygon(points: f.polygon.points),
        normalFillColor: base.withValues(alpha: 0.45),
        normalBorderColor: base.withValues(alpha: 0.95),
        normalBorderWidth: 0.8,
        selectedFillColor: base.withValues(alpha: 0.75),
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

    final hasStats = widget.showIbgeStats && widget.ibgeStatsValues.isNotEmpty;
    double? minVal;
    double? maxVal;

    if (hasStats) {
      for (final v in widget.ibgeStatsValues.values) {
        minVal = (minVal == null) ? v : math.min(minVal, v);
        maxVal = (maxVal == null) ? v : math.max(maxVal, v);
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
          final t = ((v - minVal) / (maxVal - minVal)).clamp(0.0, 1.0);

          base = Color.lerp(
            Colors.yellow.shade200,
            Colors.red.shade800,
            t,
          )!.withValues(alpha: 0.80);
        }
      }

      ibgeColors[title] = base;
    }

    return ibgeColors;
  }

  List<PolygonChanged> _buildIbgeStyledPolygons(Map<String, Color> ibgeColors) {
    if (!widget.showIbgeCities) return const [];

    return widget.ibgeCityPolygons.map((p) {
      final basePoly = p.polygon;
      final String title = p.title.isEmpty ? 'MUNICIPIO_SEM_NOME' : p.title;
      final baseColor = ibgeColors[title] ?? Colors.white;

      return PolygonChanged(
        title: p.title,
        polygon: Polygon(points: basePoly.points),
        normalFillColor: baseColor,
        normalBorderColor: Colors.grey.shade300,
        normalBorderWidth: 2.0,
        selectedFillColor: Colors.red.withValues(alpha: 0.25),
        selectedBorderColor: Colors.red,
        selectedBorderWidth: 3.0,
        properties: p.properties,
        mapColors: p.mapColors,
      );
    }).toList();
  }

  void _handleRegionTap(String? regionTitle) {
    if (regionTitle == null) {
      _closeTooltip();
      setState(() {});
      widget.onRegionTap(null);
      return;
    }

    // SIGMINE
    final f = _resolveProcess(regionTitle);
    if (f != null) {
      _openTooltipForProcess(regionTitle);
      setState(() {});
      widget.onRegionTap(regionTitle);
      return;
    }

    // IBGE
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
        setState(() {});
        String? idIbge;
        final propsList = found.properties ?? const <dynamic>[];

        for (final props in propsList) {
          if (props is Map<String, dynamic> && props['idIbge'] != null) {
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
