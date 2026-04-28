import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:sipged/_blocs/modules/actives/roads/active_roads_cubit.dart';
import 'package:sipged/_blocs/modules/actives/roads/active_roads_data.dart';
import 'package:sipged/_blocs/modules/actives/roads/active_roads_state.dart';
import 'package:sipged/screens/modules/actives/roads/network/road_label_circle.dart';
import 'package:sipged/_widgets/map/clusters/cluster_layer.dart';
import 'package:sipged/_widgets/map/flutter_map/map_interactive.dart';
import 'package:sipged/_widgets/draw/shimmer/map_shimmer.dart';

import 'package:sipged/_widgets/overlays/balloon/balloon_change.dart';
import 'package:sipged/_widgets/overlays/balloon/balloon_tile.dart';
import 'package:sipged/_widgets/overlays/balloon/balloon_tip.dart';

import 'package:sipged/screens/modules/actives/roads/network/active_roads_details.dart';

class ActiveRoadsMap extends StatefulWidget {
  const ActiveRoadsMap({super.key});

  @override
  State<ActiveRoadsMap> createState() => _ActiveRoadsMapState();
}

class _ActiveRoadsMapState extends State<ActiveRoadsMap> {
  final ValueNotifier<double> _zoomVN = ValueNotifier<double>(12.0);
  final ValueNotifier<double> _centerLatVN = ValueNotifier<double>(-9.65);

  LatLng? _anchorLatLng;
  MapController? _lastMapController;
  Offset Function(Offset local)? _toGlobal;

  OverlayEntry? _roadBalloonEntry;
  Offset? _roadBalloonGlobalPosition;
  ActiveRoadsData? _roadBalloonData;
  ActiveRoadsCubit? _roadBalloonCubit;
  RenderBox? _roadBalloonOverlayBox;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final cubit = context.read<ActiveRoadsCubit>();
      final bucket = ActiveRoadsCubit.bucketForZoom(_zoomVN.value);
      cubit.warmup(bucket: bucket);
    });
  }

  @override
  void dispose() {
    _hideRoadBalloon(clearAnchor: true);
    _zoomVN.dispose();
    _centerLatVN.dispose();
    super.dispose();
  }

  void _clearTooltipAnchor() {
    _anchorLatLng = null;
    _lastMapController = null;
    _toGlobal = null;
  }

  void _hideRoadBalloon({bool clearAnchor = false}) {
    _roadBalloonEntry?.remove();
    _roadBalloonEntry = null;
    _roadBalloonGlobalPosition = null;
    _roadBalloonData = null;
    _roadBalloonCubit = null;
    _roadBalloonOverlayBox = null;

    if (clearAnchor) {
      _clearTooltipAnchor();
    }
  }

  void _updateRoadBalloonPosition() {
    if (_anchorLatLng == null ||
        _lastMapController == null ||
        _toGlobal == null ||
        _roadBalloonEntry == null) {
      return;
    }

    final local = _lastMapController!.camera.latLngToScreenOffset(
      _anchorLatLng!,
    );

    _roadBalloonGlobalPosition = _toGlobal!(local);
    _roadBalloonEntry?.markNeedsBuild();
  }

  Future<void> _showRoadDetails(ActiveRoadsData road) async {
    _hideRoadBalloon(clearAnchor: true);

    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            height: MediaQuery.of(context).size.height * 0.7,
            width: MediaQuery.of(context).size.width * 0.8,
            child: ActiveRoadsDetails(road: road),
          ),
        );
      },
    );
  }

  void _showRoadBalloon({
    required OverlayState overlayState,
    required Offset position,
    required ActiveRoadsData road,
    required ActiveRoadsCubit cubit,
  }) {
    final overlayObject = overlayState.context.findRenderObject();
    if (overlayObject is! RenderBox) return;

    _hideRoadBalloon();

    _roadBalloonGlobalPosition = position;
    _roadBalloonData = road;
    _roadBalloonCubit = cubit;
    _roadBalloonOverlayBox = overlayObject;

    _roadBalloonEntry = OverlayEntry(
      builder: (_) {
        final currentPosition = _roadBalloonGlobalPosition;
        final currentRoad = _roadBalloonData;
        final currentCubit = _roadBalloonCubit;
        final currentOverlayBox = _roadBalloonOverlayBox;

        if (currentPosition == null ||
            currentRoad == null ||
            currentCubit == null ||
            currentOverlayBox == null) {
          return const SizedBox.shrink();
        }

        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => _hideRoadBalloon(clearAnchor: true),
                child: const SizedBox.expand(),
              ),
            ),
            BalloonChange(
              overlayBox: currentOverlayBox,
              globalAnchor: currentPosition,
              width: 320,
              maxHeight: 138,
              topGap: 0,
              screenMargin: 12,
              tipSide: BalloonTipSide.bottom,
              title: currentCubit.tooltipTitle(currentRoad),
              showAction: true,
              onAction: () => _showRoadDetails(currentRoad),
              emptyMessage: 'Nenhuma informação encontrada.',
              items: [
                BalloonTileData(
                  id: currentRoad.id ?? currentRoad.roadCode ?? 'road',
                  subtitle: currentCubit.tooltipSubtitle(currentRoad),
                  details: 'Toque para visualizar os detalhes da rodovia.',
                  icon: Icons.alt_route_rounded,
                  accentColor: Colors.blue.shade800,
                  onTap: () => _showRoadDetails(currentRoad),
                ),
              ],
            ),
          ],
        );
      },
    );

    overlayState.insert(_roadBalloonEntry!);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ActiveRoadsCubit>().state;
    final cubit = context.read<ActiveRoadsCubit>();

    final isInitialLoading =
        state.loadStatus == ActiveRoadsLoadStatus.loading && !state.initialized;

    if (isInitialLoading) {
      return const MapShimmer();
    }

    return ValueListenableBuilder<double>(
      valueListenable: _zoomVN,
      builder: (context, zoom, _) {
        final labelMarkers = state.buildRoadLabelMarkers(zoom: zoom);
        final labelTagged = state.buildRoadLabelTaggedMarkers(zoom: zoom);
        final useCluster = cubit.shouldUseCluster(zoom);

        return ValueListenableBuilder<double>(
          valueListenable: _centerLatVN,
          builder: (context, centerLat, _) {
            return MapInteractivePage<ActiveRoadsData>(
              showSearch: true,
              searchTargetZoom: 16,
              showSearchMarker: true,
              activeMap: true,
              showChangeMapType: true,
              showMyLocation: true,
              tappablePolylines: state.buildStyledPolylines(
                zoom: zoom,
                centerLatitude: centerLat,
              ),
              extraMarkers: useCluster ? const [] : labelMarkers,
              taggedMarkers: useCluster ? labelTagged : const [],
              clusterWidgetBuilder: useCluster
                  ? (tagged, selectedMarkerPosition, onMarkerSelected) {
                return ClusterLayer<ActiveRoadsData>(
                  taggedMarkers: tagged,
                  selectedMarkerPosition: selectedMarkerPosition,
                  onMarkerSelected: onMarkerSelected,
                  markerBuilder: (ctx, taggedMarker, isSelected) {
                    final label =
                        taggedMarker.properties['label']?.toString() ??
                            '';
                    final diameter =
                        (taggedMarker.properties['diameter'] as double?) ??
                            24.0;
                    final font =
                        (taggedMarker.properties['font'] as double?) ??
                            10.0;

                    return IgnorePointer(
                      ignoring: true,
                      child: Center(
                        child: RoadLabelCircle(
                          text: label,
                          diameter: diameter,
                          fontSize: font,
                        ),
                      ),
                    );
                  },
                  titleBuilder: (r) {
                    return '${r.acronym ?? ''} (${r.roadCode ?? ''})';
                  },
                  subTitleBuilder: (r) {
                    return '${r.initialSegment} / ${r.finalSegment}';
                  },
                  inlineTooltip: true,
                  inlineMaxWidth: 280,
                  inlineEstimatedHeight: 170,
                  markerAlignment: Alignment.center,
                );
              }
                  : null,
              onCameraChanged: (double z, LatLng center) {
                if (_zoomVN.value != z) {
                  _zoomVN.value = z;
                }

                final lat = center.latitude;
                if (_centerLatVN.value != lat) {
                  _centerLatVN.value = lat;
                }

                cubit.onZoomChanged(zoom: z);

                _updateRoadBalloonPosition();
              },
              onClearPolylineSelection: () async {
                cubit.clearPolylineSelection();
                _hideRoadBalloon(clearAnchor: true);
              },
              onSelectPolyline: (polyline) async {
                cubit.selectPolyline(polyline.tag?.toString());
              },
              onShowPolylineTooltip: ({
                required BuildContext context,
                required Offset position,
                required Object? tag,
                required MapController mapController,
                LatLng? tapLatLng,
                Offset Function(Offset p)? toGlobal,
              }) async {
                final road = cubit.findByPolylineTag(tag);
                if (road == null) return;

                _anchorLatLng = road.anchorForTap(tapLatLng) ?? tapLatLng;
                if (_anchorLatLng == null) return;

                _lastMapController = mapController;
                _toGlobal = toGlobal;

                final local = mapController.camera.latLngToScreenOffset(
                  _anchorLatLng!,
                );

                final global = toGlobal?.call(local) ?? position;

                final overlay = Overlay.of(context);

                _showRoadBalloon(
                  overlayState: overlay,
                  position: global,
                  road: road,
                  cubit: cubit,
                );
              },
            );
          },
        );
      },
    );
  }
}