import 'package:diacritic/diacritic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:siged/_services/geometry/geometry_utils.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart';

import 'package:siged/_widgets/map/map_interactive.dart';
import 'package:siged/_widgets/map/polygon/polygon_changed.dart';
import 'package:siged/_widgets/map/tooltip/tooltip_animated_card.dart';
import 'package:siged/_widgets/map/tooltip/tooltip_balloon_tip.dart';

import 'package:siged/_services/sigmine/sigmine_service.dart';

class SigmineMap extends StatefulWidget {
  const SigmineMap({
    super.key,
    required this.featuresAtivos,
    required this.mineriosAtivos,
    required this.getColorForMinerio,
    required this.onRegionTap,       // recebe processo
    required this.onControllerReady,
    required this.ufs,
    required this.selectedUF,
    required this.loading,
    required this.onChangeUF,
    required this.onRequestDetails,          // 🆕
    required this.onRequestDetailsByProcess, // 🆕
  });

  final List<SigmineFeature> featuresAtivos;
  final Set<String> mineriosAtivos;
  final Color Function(String nomeNormalizado) getColorForMinerio;
  final void Function(String? region) onRegionTap;
  final void Function(MapController controller) onControllerReady;
  final List<String> ufs;
  final String? selectedUF;
  final bool loading;
  final void Function(String uf) onChangeUF;

  final void Function(SigmineFeature feature) onRequestDetails; // 🆕
  final void Function(String processo) onRequestDetailsByProcess; // 🆕 alternativa

  @override
  State<SigmineMap> createState() => _SigmineMapState();
}

class _SigmineMapState extends State<SigmineMap> {
  MapController? _controller;

  // lookup por processo (normalizado)
  late Map<String, SigmineFeature> _byProcess;

  // tooltip
  String? _selectedProcesso;
  LatLng? _tooltipAnchor;
  Offset? _tooltipScreenPos;
  String _tooltipTitle = '';
  String? _tooltipSubtitle;

  // layout tooltip
  static const double _cardMaxWidth = 260;
  static const double _cardEstimatedHeight = 130;
  static const double _balloonHeight = 6;
  static const double _yOffset = 4;

  // ------- normalizadores -------
  String _normMinerio(String s) =>
      removeDiacritics(s).replaceAll(RegExp(r'\s+'), ' ').trim().toUpperCase();

  String _normProc(String s) => s.replaceAll(RegExp(r'\s+'), ' ').trim();

  @override
  void initState() {
    super.initState();
    _rebuildIndex();
  }

  @override
  void didUpdateWidget(covariant SigmineMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.featuresAtivos != widget.featuresAtivos) {
      _rebuildIndex();
      _recomputeTooltipScreenPos(_controller);
    }
  }

  void _rebuildIndex() {
    _byProcess = {
      for (final f in widget.featuresAtivos) _normProc(f.processo): f,
    };
  }

  SigmineFeature? _resolveProcess(String raw) {
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

  // -------- tooltip --------
  void _openTooltipForProcess(String processoRaw) {
    final f = _resolveProcess(processoRaw);
    if (f == null) return;

    setState(() {
      _selectedProcesso = _normProc(f.processo);
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

  @override
  Widget build(BuildContext context) {
    // --------- monta polígonos ----------
    final polygons = widget.featuresAtivos.map((f) {
      final minerioNorm = _normMinerio((f.substancia ?? 'INDEFINIDO'));
      final base = widget.getColorForMinerio(minerioNorm);
      final bool isSelected = _selectedProcesso == _normProc(f.processo);

      return PolygonChanged(
        title: f.processo, // seleção por processo
        polygon: Polygon(
          points: f.polygon.points,
          color: base.withOpacity(isSelected ? 0.70 : 0.45),
          borderColor: isSelected ? Colors.black : base.withOpacity(0.95),
          borderStrokeWidth: isSelected ? 2.0 : 0.8,
        ),
        properties: [
          {'processo': _normProc(f.processo)},
          {'minerio': minerioNorm},
          {'fase': (f.fase ?? '').trim()},
          {'titular': (f.titular ?? '').trim()},
        ],
      );
    }).toList();

    // cores de legenda por substância (compartilhadas c/ gráfico)
    final Map<String, Color> _regionColors = {
      for (final f in widget.featuresAtivos)
        _normMinerio(f.substancia ?? 'INDEFINIDO'):
        widget.getColorForMinerio(_normMinerio(f.substancia ?? 'INDEFINIDO')),
    };

    return Stack(
      children: [
        MapInteractivePage<void>(
          activeMap: true,
          showLegend: false,
          showSearch: true,
          polygonsChanged: polygons,
          polygonChangeColors: _regionColors,
          allowMultiSelect: false,
          onRegionTap: (maybeProcess) {
            if (maybeProcess != null) {
              _openTooltipForProcess(maybeProcess);
              widget.onRegionTap(maybeProcess);
            } else {
              _closeTooltip();
              widget.onRegionTap(null);
            }
          },
          onControllerReady: (c) {
            _controller = c;
            widget.onControllerReady(c);
            _controller!.mapEventStream
                .listen((_) => _recomputeTooltipScreenPos(_controller));
          },
        ),

        // seletor de UF
        Positioned(
          top: 16,
          right: 16,
          child: DropDownButtonChange(
            items: widget.ufs,
            onChanged: (uf) {
              if (uf == null) return;
              widget.onChangeUF(uf);
              _closeTooltip();
            },
            labelText: 'Selecione a UF',
            controller: TextEditingController(text: widget.selectedUF),
          ),
        ),

        // tooltip ancorado no labelPoint do PROCESSO
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
                      // 👉 pede para o PAI abrir o painel no lugar do sidepanel
                      final f = _resolveProcess(_tooltipTitle);
                      if (f != null) {
                        widget.onRequestDetails(f);
                      } else {
                        widget.onRequestDetailsByProcess(_tooltipTitle);
                      }
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
}
