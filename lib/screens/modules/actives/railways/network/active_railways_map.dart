// lib/screens/modules/actives/railways/network/active_railways_map.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:sipged/_blocs/modules/actives/railway/active_railway_data.dart';
import 'package:sipged/_blocs/modules/actives/railway/active_railways_cubit.dart';
import 'package:sipged/_blocs/modules/actives/railway/active_railways_state.dart';

import 'package:sipged/_blocs/modules/planning/geo/feature/feature_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data.dart';

import 'package:sipged/_widgets/draw/shimmer/map_shimmer.dart';
import 'package:sipged/_widgets/map/map/map_change.dart';

import 'package:sipged/_widgets/overlays/balloon/balloon_change.dart';
import 'package:sipged/_widgets/overlays/balloon/balloon_tile.dart';
import 'package:sipged/_widgets/overlays/balloon/balloon_tip.dart';

import 'active_railways_details.dart';

class ActiveRailwaysMap extends StatefulWidget {
  const ActiveRailwaysMap({
    super.key,
    required this.state,
  });

  final ActiveRailwaysState state;

  @override
  State<ActiveRailwaysMap> createState() => _ActiveRailwaysMapState();
}

class _ActiveRailwaysMapState extends State<ActiveRailwaysMap> {
  LatLng? _anchorLatLng;
  MapController? _lastMapController;
  Offset Function(Offset local)? _toGlobal;

  OverlayEntry? _railwayBalloonEntry;
  Offset? _railwayBalloonGlobalPosition;
  ActiveRailwayData? _railwayBalloonData;
  RenderBox? _railwayBalloonOverlayBox;

  @override
  void dispose() {
    _hideRailwayBalloon(clearAnchor: true);
    super.dispose();
  }

  void _clearTooltipAnchor() {
    _anchorLatLng = null;
    _lastMapController = null;
    _toGlobal = null;
  }

  void _hideRailwayBalloon({bool clearAnchor = false}) {
    _railwayBalloonEntry?.remove();
    _railwayBalloonEntry = null;

    _railwayBalloonGlobalPosition = null;
    _railwayBalloonData = null;
    _railwayBalloonOverlayBox = null;

    if (clearAnchor) {
      _clearTooltipAnchor();
    }
  }

  void _updateRailwayBalloonPosition() {
    if (_anchorLatLng == null ||
        _lastMapController == null ||
        _toGlobal == null ||
        _railwayBalloonEntry == null) {
      return;
    }

    final local = _lastMapController!.camera.latLngToScreenOffset(
      _anchorLatLng!,
    );

    _railwayBalloonGlobalPosition = _toGlobal!(local);
    _railwayBalloonEntry?.markNeedsBuild();
  }

  Future<void> _showRailwayDetails(ActiveRailwayData fer) async {
    _hideRailwayBalloon(clearAnchor: true);

    if (!mounted) return;

    final media = MediaQuery.of(context);
    final screenHeight = media.size.height;
    final screenWidth = media.size.width;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            height: screenHeight * 0.7,
            width: screenWidth * 0.8,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: ActiveRailwaysDetails(
              fer: fer,
              enabled: false,
            ),
          ),
        );
      },
    );
  }

  void _showRailwayBalloon({
    required OverlayState overlayState,
    required Offset position,
    required ActiveRailwayData railway,
  }) {
    final overlayObject = overlayState.context.findRenderObject();

    if (overlayObject is! RenderBox) return;

    _hideRailwayBalloon();

    _railwayBalloonGlobalPosition = position;
    _railwayBalloonData = railway;
    _railwayBalloonOverlayBox = overlayObject;

    _railwayBalloonEntry = OverlayEntry(
      builder: (_) {
        final currentPosition = _railwayBalloonGlobalPosition;
        final currentRailway = _railwayBalloonData;
        final currentOverlayBox = _railwayBalloonOverlayBox;

        if (currentPosition == null ||
            currentRailway == null ||
            currentOverlayBox == null) {
          return const SizedBox.shrink();
        }

        final title = _title(currentRailway);
        final subtitle = _subtitle(currentRailway);

        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => _hideRailwayBalloon(clearAnchor: true),
                child: const SizedBox.expand(),
              ),
            ),
            BalloonChange(
              overlayBox: currentOverlayBox,
              globalAnchor: currentPosition,
              width: 320,
              maxHeight: 210,
              topGap: 8,
              screenMargin: 12,
              tipSide: BalloonTipSide.bottom,
              title: title,
              showAction: true,
              onAction: () => _showRailwayDetails(currentRailway),
              emptyMessage: 'Nenhuma informação encontrada.',
              items: [
                BalloonTileData(
                  id: currentRailway.id ?? title,
                  subtitle: subtitle.isEmpty ? null : subtitle,
                  details: 'Toque para visualizar os detalhes da ferrovia.',
                  icon: Icons.train_rounded,
                  accentColor: Colors.deepPurple.shade700,
                  onTap: () => _showRailwayDetails(currentRailway),
                ),
              ],
            ),
          ],
        );
      },
    );

    overlayState.insert(_railwayBalloonEntry!);
  }

  ActiveRailwayData? _findRailwayById(String? id) {
    if (id == null || id.trim().isEmpty) return null;

    final cleanId = id.trim();

    for (final f in widget.state.filteredAll) {
      if (f.id == cleanId) return f;
    }

    for (final f in widget.state.all) {
      if (f.id == cleanId) return f;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isInitialLoading =
        widget.state.loadStatus == ActiveRailwaysLoadStatus.loading &&
            !widget.state.initialized;

    if (isInitialLoading) {
      return const MapShimmer();
    }

    return MapChange(
      key: const ValueKey('active-railways-map'),

      features: const <FeatureData>[],
      layersById: const <String, LayerData>{},
      orderedActiveLayerIds: const <String>[],

      selectedFeatureKey: null,
      loading: false,

      visualDataSignature: Object.hash(
        'active-railways',
        widget.state.mapZoom,
        widget.state.filteredAll.length,
        widget.state.all.length,
      ),

      initialCenter: const LatLng(-9.6658, -35.7353),
      initialZoom: widget.state.mapZoom <= 0 ? 7.8 : widget.state.mapZoom,
      minZoom: 4,
      maxZoom: 18,

      showSearch: true,
      showControls: true,

      externalPolylines: widget.state.buildStyledPolylines(
        zoom: widget.state.mapZoom,
      ),

      onControllerReady: (controller) {
        final railwaysCubit = context.read<ActiveRailwaysCubit>();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;

          final z = controller.camera.zoom;
          railwaysCubit.setMapZoom(z);
        });
      },

      onCameraChanged: (center, zoom) {
        final railwaysCubit = context.read<ActiveRailwaysCubit>();
        railwaysCubit.setMapZoom(zoom);

        _updateRailwayBalloonPosition();
      },

      onFeatureTap: (_) {},

      onClearExternalPolylineSelection: () async {
        final railwaysCubit = context.read<ActiveRailwaysCubit>();
        railwaysCubit.selectPolyline(null);

        _hideRailwayBalloon(clearAnchor: true);
      },

      onExternalPolylineTap: (polyline) async {
        final railwaysCubit = context.read<ActiveRailwaysCubit>();
        railwaysCubit.selectPolyline(polyline.hitValue?.toString());
      },

      onShowExternalPolylineTooltip: ({
        required BuildContext context,
        required Offset position,
        required Object? tag,
        required MapController mapController,
        LatLng? tapLatLng,
        Offset Function(Offset p)? toGlobal,
      }) async {
        final fer = _findRailwayById(tag?.toString());
        if (fer == null) return;

        _anchorLatLng = fer.anchorForTap(tapLatLng);

        if (_anchorLatLng == null) return;

        _lastMapController = mapController;
        _toGlobal = toGlobal;

        final local = mapController.camera.latLngToScreenOffset(
          _anchorLatLng!,
        );

        final global = toGlobal?.call(local) ?? position;
        final overlay = Overlay.of(context);

        _showRailwayBalloon(
          overlayState: overlay,
          position: global,
          railway: fer,
        );
      },
    );
  }

  String _title(ActiveRailwayData fer) {
    final nome = (fer.nome ?? '').trim();

    if (nome.isNotEmpty) return nome;

    final cod = (fer.codigo ?? '').trim();

    if (cod.isNotEmpty) return 'Ferrovia $cod';

    return fer.id ?? 'Ferrovia';
  }

  String _subtitle(ActiveRailwayData fer) {
    final s = <String>[];

    if ((fer.uf ?? '').trim().isNotEmpty) {
      s.add('UF: ${fer.uf}');
    }

    if ((fer.status ?? '').trim().isNotEmpty) {
      s.add('Status: ${fer.status}');
    }

    if ((fer.bitola ?? '').trim().isNotEmpty) {
      s.add('Bitola: ${fer.bitola}');
    }

    if ((fer.municipio ?? '').trim().isNotEmpty) {
      s.add(fer.municipio!);
    }

    return s.join(' • ');
  }
}