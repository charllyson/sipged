// lib/screens/modules/actives/roads/network/active_roads_map.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:sipged/_blocs/modules/actives/roads/active_roads_cubit.dart';
import 'package:sipged/_blocs/modules/actives/roads/active_roads_data.dart';
import 'package:sipged/_blocs/modules/actives/roads/active_roads_state.dart';
import 'package:sipged/_blocs/modules/actives/roads/roads/road_label_circle.dart';

import 'package:sipged/_widgets/map/flutter_map/map_interactive.dart';
import 'package:sipged/_widgets/map/shimmer/map_loading_shimmer.dart';
import 'package:sipged/_widgets/map/tooltip/map_tap_overlay.dart';

import 'package:sipged/_widgets/map/clusters/cluster_animated_marker_widget.dart';

import 'package:sipged/screens/modules/actives/roads/network/active_roads_details.dart';

class ActiveRoadsMap extends StatefulWidget {
  const ActiveRoadsMap({super.key});

  @override
  State<ActiveRoadsMap> createState() => _ActiveRoadsMapState();
}

class _ActiveRoadsMapState extends State<ActiveRoadsMap> {
  // ✅ Evita setState em pan/zoom: usa VN
  final ValueNotifier<double> _zoomVN = ValueNotifier<double>(12.0);
  final ValueNotifier<double> _centerLatVN = ValueNotifier<double>(-9.65);

  LatLng? _anchorLatLng;
  MapController? _lastMapController;
  Offset Function(Offset local)? _toGlobal;

  @override
  void initState() {
    super.initState();

    // ✅ Warmup com bucket coerente com o zoom inicial
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<ActiveRoadsCubit>();
      final bucket = ActiveRoadsCubit.bucketForZoom(_zoomVN.value);
      cubit.warmup(bucket: bucket);
    });
  }

  @override
  void dispose() {
    _zoomVN.dispose();
    _centerLatVN.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ActiveRoadsCubit>().state;
    final cubit = context.read<ActiveRoadsCubit>();

    final isInitialLoading =
        state.loadStatus == ActiveRoadsLoadStatus.loading && !state.initialized;

    if (isInitialLoading) return const MapLoadingShimmer();

    return ValueListenableBuilder<double>(
      valueListenable: _zoomVN,
      builder: (context, zoom, _) {
        // ✅ labels baseados no dataset já filtrado (região/pie)
        final labelMarkers = state.buildRoadLabelMarkers(zoom: zoom);
        final labelTagged = state.buildRoadLabelTaggedMarkers(zoom: zoom);

        final bool useCluster = cubit.shouldUseCluster(zoom);

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

              // ✅ Usa geoms simplificados em cache (bucket) e aplica estilo por zoom/centro
              // IMPORTANTE: como o MapInteractivePage agora faz debounce de câmera,
              // esse rebuild não fica “por pixel”; e como não usamos setState aqui,
              // o custo cai MUITO.
              tappablePolylines: state.buildStyledPolylines(
                zoom: zoom,
                centerLatitude: centerLat,
              ),

              extraMarkers: useCluster ? const [] : labelMarkers,
              taggedMarkers: useCluster ? labelTagged : const [],

              clusterWidgetBuilder: useCluster
                  ? (tagged, selectedMarkerPosition, onMarkerSelected) {
                return ClusterAnimatedMarkerLayer<ActiveRoadsData>(
                  taggedMarkers: tagged,
                  selectedMarkerPosition: selectedMarkerPosition,
                  onMarkerSelected: onMarkerSelected,
                  markerBuilder: (ctx, taggedMarker, isSelected) {
                    final lab =
                        taggedMarker.properties['label']?.toString() ?? '';
                    final d =
                        (taggedMarker.properties['diameter'] as double?) ??
                            24.0;
                    final f =
                        (taggedMarker.properties['font'] as double?) ??
                            10.0;
                    return IgnorePointer(
                      ignoring: true,
                      child: RoadLabelCircle(
                        text: lab,
                        diameter: d,
                        fontSize: f,
                      ),
                    );
                  },
                  titleBuilder: (r) =>
                  '${r.acronym ?? ''} (${r.roadCode ?? ''})',
                  subTitleBuilder: (r) =>
                  '${r.initialSegment} / ${r.finalSegment}',
                  inlineTooltip: false,
                  inlineMaxWidth: 240,
                  inlineEstimatedHeight: 120,
                  markerAlignment: Alignment.center,
                );
              }
                  : null,

              // ✅ NÃO usa setState; só atualiza VN
              onCameraChanged: (double z, LatLng center) {
                // Atualiza VN (rápido)
                if (_zoomVN.value != z) _zoomVN.value = z;
                final lat = center.latitude;
                if (_centerLatVN.value != lat) _centerLatVN.value = lat;

                // ✅ bucket/cache (debounce) igual ao Federal
                cubit.onZoomChanged(zoom: z);

                // Tooltip ancorado
                if (_anchorLatLng != null &&
                    _lastMapController != null &&
                    _toGlobal != null) {
                  final local = _lastMapController!.camera
                      .latLngToScreenOffset(_anchorLatLng!);
                  final global = _toGlobal!(local);
                  MapTapOverlayTooltip.updatePosition(global);
                }
              },

              onClearPolylineSelection: () async {
                cubit.clearPolylineSelection();
                _anchorLatLng = null;
                _lastMapController = null;
                _toGlobal = null;
                MapTapOverlayTooltip.hide();
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

                final overlay = Overlay.of(context);

                MapTapOverlayTooltip.show(
                  overlayState: overlay,
                  position: position,
                  title: cubit.tooltipTitle(road),
                  subtitle: cubit.tooltipSubtitle(road),
                  maxWidth: 320,
                  forceDownArrow: true,
                  onDetails: () async {
                    MapTapOverlayTooltip.hide();
                    await showDialog(
                      context: context,
                      barrierDismissible: true,
                      builder: (_) => Dialog(
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
                      ),
                    );
                  },
                  onClose: () {
                    _anchorLatLng = null;
                    _lastMapController = null;
                    _toGlobal = null;
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
