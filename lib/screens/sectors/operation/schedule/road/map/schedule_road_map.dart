// lib/screens/sectors/planning/projects/planning_right_way_map.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:siged/_blocs/sectors/operation/road/schedule_road_bloc.dart';
import 'package:siged/_blocs/sectors/operation/road/schedule_road_state.dart';
import 'package:siged/_blocs/sectors/operation/road/schedule_road_event.dart';
import 'package:siged/_blocs/sectors/operation/road/schedule_road_style.dart';

import 'package:siged/_widgets/stakes/line_segmentation.dart';
import 'package:siged/_services/geoJson/send_firebase.dart';
import 'package:siged/_widgets/services/floating_buttons.dart';
import 'package:siged/_widgets/stakes/zoom_listener.dart';
import 'package:siged/_services/geocoding/geocoding_service.dart';

import 'package:siged/_widgets/map/polylines/tappable_changed_polyline.dart';
import 'package:siged/_widgets/map/map_interactive.dart';
import 'package:siged/_widgets/map/shimmer/map_loading_shimmer.dart';
import 'package:siged/_widgets/map/markers/tagged_marker.dart';

import 'package:siged/_widgets/stakes/stakes_up_right.dart';
import 'package:siged/_widgets/search/search_overlay.dart';
import 'package:siged/_widgets/search/search_widget.dart';
import '../../../../../../_blocs/sectors/operation/road/schedule_road_data.dart';
import '../schedule_road_panel.dart';
import 'package:siged/_blocs/documents/contracts/contracts/contract_data.dart';

// ====== constantes de estilo ======
const double kLaneStrokeWidth = 7.0;            // largura padrão dos segmentos
const double kLaneStrokeWidthSelected = 10.0;   // largura quando selecionado
const double kHitStrokeMin = 22.0;              // área mínima de toque (helpers)

class ScheduleRoadMap extends StatefulWidget {
  final ContractData contractData;
  final ValueNotifier<bool>? externalPanelController;

  const ScheduleRoadMap({
    super.key,
    required this.contractData,
    this.externalPanelController,
  });

  @override
  State<ScheduleRoadMap> createState() => _ScheduleRoadMapState();
}

class _ScheduleRoadMapState extends State<ScheduleRoadMap> {
  bool _showRightPanel = false;
  String? _selectedTag;
  VoidCallback? _panelListener;

  // ====== caches ======
  SegmentedAxis? _cachedSegmented;
  String? _segKey; // axisKey + step + zoomBucket

  @override
  void initState() {
    super.initState();
    if (widget.externalPanelController != null) {
      _showRightPanel = widget.externalPanelController!.value;
      _panelListener = () {
        final v = widget.externalPanelController!.value;
        if (v != _showRightPanel && mounted) setState(() => _showRightPanel = v);
      };
      widget.externalPanelController!.addListener(_panelListener!);
    }
  }

  @override
  void dispose() {
    if (_panelListener != null && widget.externalPanelController != null) {
      widget.externalPanelController!.removeListener(_panelListener!);
    }
    super.dispose();
  }

  // ====== helpers de chave/cache ======
  String _makeAxisKey(List<LatLng> axis) {
    if (axis.isEmpty) return 'empty';
    final a = axis.first, b = axis.last;
    return '${axis.length}:${a.latitude.toStringAsFixed(6)},${a.longitude.toStringAsFixed(6)}>'
        '${b.latitude.toStringAsFixed(6)},${b.longitude.toStringAsFixed(6)}';
  }

  double _bucketZoom(double z) => (z * 4).round() / 4.0; // bucket de 0.25

  SegmentedAxis _getSegmented({
    required List<LatLng> axis,
    required double stepMeters,
    required double zoom,
  }) {
    final key = '${_makeAxisKey(axis)}@$stepMeters@${_bucketZoom(zoom)}';
    if (_cachedSegmented == null || _segKey != key) {
      _cachedSegmented = splitAxisByFixedStep(axis: axis, stepMeters: stepMeters);
      _segKey = key;
    }
    return _cachedSegmented!;
  }

  String? _tagAsString(Object? tag) => tag?.toString();

  // ===== Helper: apagar traçado salvo =====
  Future<void> _onDeleteCollectionLikeBefore(ScheduleRoadState st) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Apagar traçado'),
        content: const Text(
          'Tem certeza que deseja remover o traçado (geometry) salvo para este contrato? '
              'Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Apagar')),
        ],
      ),
    );

    if (ok == true && mounted) {
      final bloc = context.read<ScheduleRoadBloc>();
      bloc.add(const ScheduleProjectDeleteRequested());
      bloc.add(const ScheduleRefreshRequested());
    }
  }

  // ======= stakes layer =======
  Widget _stakesLayer({required List<TaggedChangedMarker<Map<String, dynamic>>> markers}) {
    if (markers.isEmpty) return const SizedBox.shrink();
    return MarkerLayer(
      markers: [
        for (final m in markers)
          Marker(
            point: m.point,
            width: 80,
            height: 80,
            alignment: Alignment.center,
            child: StakesUpRight(
              label: m.properties['label']?.toString() ?? '',
              normalAngle: (m.properties['normalAngle'] as double?) ?? 0.0,
              tickPx: (m.properties['tickPx'] as double?) ?? 12.0,
            ),
          ),
      ],
    );
  }

  // ====== cópia segura (preserva flags e tag) ======
  TappableChangedPolyline _copyKeepingFlags(
      TappableChangedPolyline p, {
        Color? color,
        double? strokeWidth,
      }) {
    return TappableChangedPolyline(
      points: p.points,
      tag: p.tag,
      color: color ?? p.color,
      defaultColor: p.defaultColor,
      strokeWidth: strokeWidth ?? p.strokeWidth,
      isDotted: p.isDotted,
      hitTestable: p.hitTestable,
    );
  }

  // ======= estilo de seleção =======
  List<TappableChangedPolyline> _applySelectionStyle(
      List<TappableChangedPolyline> polylines,
      String? selectedTag,
      ) {
    if (selectedTag == null) {
      return polylines
          .map((p) => _copyKeepingFlags(
        p,
        strokeWidth: kLaneStrokeWidth,
        color: p.defaultColor ?? p.color,
      ))
          .toList();
    }

    return polylines.map((p) {
      final sel = p.tag?.toString() == selectedTag;
      return _copyKeepingFlags(
        p,
        color: sel ? const Color(0xFFEC407A) : (p.defaultColor ?? p.color),
        strokeWidth: sel ? kLaneStrokeWidthSelected : kLaneStrokeWidth,
      );
    }).toList();
  }

  // ======= helpers “invisíveis” para facilitar toque =======
  List<TappableChangedPolyline> _withTapHelpers(List<TappableChangedPolyline> src) {
    final helpers = <TappableChangedPolyline>[];
    for (final p in src) {
      helpers.add(_copyKeepingFlags(
        p,
        color: Colors.black,     // 👈 quase invisível (mas “tocável”)
        strokeWidth: math.max(p.strokeWidth, 9),
      ));
    }
    // helpers primeiro (capturam o toque), originais depois (visual)
    return [...helpers, ...src];
  }

  // ======= cor por SEGMENTO (mesma do grid) =======
  Color _colorForSegment({
    required int segIdx, // segmento i (entre estaca i e i+1)
    required int faixaIndex,
    required ScheduleRoadState st,
  }) {
    final estaca = segIdx + 1; // splitAxisByFixedStep: seg i == E(i+1)->E(i+2)

    final data = st.execIndex[estaca]?[faixaIndex] ??
        ScheduleRoadData(
          numero: estaca,
          faixaIndex: faixaIndex,
          tipo: st.currentServiceKey,
          status: 'a iniciar',
          createdAt: null,
          comentario: null,
          key: st.currentServiceKey,
          label: st.currentServiceKey.toUpperCase(),
          icon: Icons.layers_outlined,
          color: Colors.grey, // ignorado pelo squareColor
        );

    // Delega a paleta para o mesmo método do GRID:
    return st.squareColor(data);
  }

  // ======= lanes -> polylines (com cor por segmento) =======
  List<TappableChangedPolyline> _buildLanePolylines({
    required SegmentedAxis segmented,
    required List lanes,
    required ScheduleRoadState st,
  }) {
    const laneSpacing = 3.5; // m
    int le = 0, ce = 0, ld = 0;
    final out = <TappableChangedPolyline>[];

    for (int fi = 0; fi < lanes.length; fi++) {
      final label = lanes[fi].label.toString();
      final up = label.toUpperCase();

      late String side;
      if (up.contains('LE')) side = 'LE';
      else if (up.contains('LD')) side = 'LD';
      else side = 'CE';

      double offset; bool buildRight = false, buildLeft = false;
      if (side == 'LE') { le += 1; offset = laneSpacing * le; buildLeft = true; }
      else if (side == 'LD') { ld += 1; offset = laneSpacing * ld; buildRight = true; }
      else { ce += 1; offset = (ce == 1) ? 0.0 : laneSpacing * (ce - 1); buildRight = true; }

      // Cor dinâmica por segmento (segIdx) para esta faixa (fi)
      Color colorForIdx(int segIdx) => _colorForSegment(
        segIdx: segIdx,
        faixaIndex: fi,
        st: st,
      );

      out.addAll(buildParallelSegmentPolylines(
        segmented: segmented,
        offsetMeters: offset,
        buildRight: buildRight,
        buildLeft: buildLeft,
        colorForIndex: colorForIdx,        // 🔸 cor do GRID aplicada segmento a segmento
        strokeWidth: kLaneStrokeWidth,     // espessura base (não selecionada)
        hitTestable: true,                 // cada trecho clicável
        sidePrefixRight: 'lane$fi',
        sidePrefixLeft:  'lane$fi',
      ));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ScheduleRoadBloc, ScheduleRoadState, ({
    bool initialized,
    bool savingOrImporting,
    double mapZoom,
    List<LatLng> axis,
    List lanes,
    String currentServiceKey,
    Map<int, Map<int, ScheduleRoadData>> execIndex,
    })>(
      selector: (st) => (
      initialized: st.initialized,
      savingOrImporting: st.savingOrImporting,
      mapZoom: st.mapZoom,
      axis: st.axis,
      lanes: st.lanes,
      currentServiceKey: st.currentServiceKey,
      execIndex: st.execIndex,
      ),
      builder: (context, sel) {
        if (!sel.initialized || sel.savingOrImporting) return const MapLoadingShimmer();

        final segmented = _getSegmented(axis: sel.axis, stepMeters: 20.0, zoom: sel.mapZoom);

        // Pega o estado completo para usar squareColor e outros helpers
        final stFull = context.read<ScheduleRoadBloc>().state;

        // SEGMENTOS das faixas com cor por segmento (serviço atual)
        final laneSegments = _buildLanePolylines(
          segmented: segmented,
          lanes: sel.lanes,
          st: stFull,
        );

        // (opcional) eixo central segmentado e clicável
        // final centerSegs = buildSegmentPolylines(
        //   segmented: segmented,
        //   colorForIndex: (i) => const Color(0xFF1565C0),
        //   strokeWidth: kLaneStrokeWidth,
        // );

        final baseSegments = laneSegments; // ou [...centerSegs, ...laneSegments]

        // aplica seleção sem perder flags
        final styled = _applySelectionStyle(baseSegments, _selectedTag);

        // amplia tolerância de toque com helpers
        final tappables = _withTapHelpers(styled);

        // stakes apenas em zoom alto (performance)
        final showStakes = sel.mapZoom >= 14.0;
        final stakeMarkers = (!showStakes || sel.axis.isEmpty)
            ? const <TaggedChangedMarker<Map<String, dynamic>>>[]
            : (() {
          final gapPx = dynamicStakeGapPx(
            axis: sel.axis,
            zoom: sel.mapZoom,
            stepMeters: 20.0,
            bubbleWidthPx: 34.0,
            marginPx: 8.0,
          );
          return buildStakeMarkersUprightWithTickRight(
            axis: sel.axis,
            stepMeters: 20.0,
            zoom: sel.mapZoom,
            minLabelPixelGap: gapPx <= 0 ? 0 : gapPx,
          );
        })();

        final map = RepaintBoundary(
          child: Stack(
            children: [
              MapInteractivePage<Map<String, dynamic>>(
                showSearch: true,
                searchTargetZoom: 16,
                showSearchMarker: true,
                tappablePolylines: tappables,
                overlayBuilder: (mc, _) => ZoomListener(mapController: mc),
                onClearPolylineSelection: () async {
                  setState(() => _selectedTag = null);
                  context.read<ScheduleRoadBloc>()
                      .add(const SchedulePolylineSelected(null));
                },
                onSelectPolyline: (pl) async {
                  setState(() => _selectedTag = pl.tag?.toString());   // 👈 pega o tag da linha tocada
                  context.read<ScheduleRoadBloc>()
                      .add(SchedulePolylineSelected(_selectedTag));
                },
                onShowPolylineTooltip: ({required context, required position, required tag}) async {},
                taggedMarkers: stakeMarkers,
                clusterWidgetBuilder: (tagged, selectedPos, onSel) => _stakesLayer(markers: tagged),
              ),
              GeoJsonActionsButtons(
                collectionPath: 'planning_projects',
                initiallyExpanded: true,
                position: const GeoJsonActionsPosition.bottomLeft(),
                onImportGeoJson: (ctx) async {
                  final bloc = context.read<ScheduleRoadBloc>();
                  try { await GeoJsonSendFirebase(ctx); }
                  finally { bloc.add(const ScheduleRefreshRequested()); }
                },
                onDeleteCollection: () async {
                  final st = context.read<ScheduleRoadBloc>().state;
                  await _onDeleteCollectionLikeBefore(st);
                },
                onCheckDistances: () async {},
              ),
            ],
          ),
        );

        return LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 980;
            if (wide) {
              return Row(
                children: [
                  Expanded(child: map),
                  if (_showRightPanel) ...[
                    const VerticalDivider(width: 1),
                    const SizedBox(width: 600, child: PlanningProjectPanel()),
                  ],
                ],
              );
            }
            return Column(
              children: [
                Expanded(child: map),
                if (_showRightPanel) ...[
                  const Divider(height: 1),
                  const SizedBox(height: 420, child: PlanningProjectPanel()),
                ],
              ],
            );
          },
        );
      },
    );
  }
}
