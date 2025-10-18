import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:siged/_blocs/actives/roads/active_road_bloc.dart';
import 'package:siged/_blocs/actives/roads/active_roads_data.dart';
import 'package:siged/_widgets/map/map_interactive.dart';
import 'package:siged/_widgets/map/shimmer/map_loading_shimmer.dart';
import 'package:siged/_blocs/actives/roads/active_roads_state.dart';
import 'package:siged/_blocs/actives/roads/active_roads_event.dart';
import 'package:siged/screens/actives/roads/network/active_roads_details.dart';
import 'package:siged/_widgets/map/tooltip/map_tap_overlay.dart';

// ▼ cluster layer
import 'package:siged/_widgets/map/clusters/cluster_animated_marker_widget.dart';

class ActiveRoadsMap extends StatefulWidget {
  const ActiveRoadsMap({super.key, required this.state});
  final ActiveRoadsState state;

  @override
  State<ActiveRoadsMap> createState() => _ActiveRoadsMapState();
}

class _ActiveRoadsMapState extends State<ActiveRoadsMap> {
  double _currentZoom = 12.0;
  double _centerLat   = -9.65;

  LatLng? _anchorLatLng;
  MapController? _lastMapController;
  Offset Function(Offset local)? _toGlobal;

  @override
  Widget build(BuildContext context) {
    final isInitialLoading =
        widget.state.loadStatus == ActiveRoadsLoadStatus.loading && !widget.state.initialized;

    if (isInitialLoading) return const MapLoadingShimmer();

    // --- rótulos como marcadores "livres" (não interceptam toque)
    final labelMarkers = widget.state.buildRoadLabelMarkers(zoom: _currentZoom);
    // --- rótulos como tagged markers (para cluster)
    final labelTagged   = widget.state.buildRoadLabelTaggedMarkers(zoom: _currentZoom);

    // threshold para ligar cluster (ajuste à vontade)
    const double kClusterUntilZoom = 12.0;
    final bool useCluster = _currentZoom < kClusterUntilZoom;

    return MapInteractivePage<ActiveRoadsData>(
      showSearch: true,
      searchTargetZoom: 16,
      showSearchMarker: true,

      tappablePolylines: widget.state.buildStyledPolylines(
        zoom: _currentZoom,
        centerLatitude: _centerLat,
      ),

      // ▼ Quando zoom alto, use marcadores "livres" (atravessáveis).
      extraMarkers: useCluster ? const [] : labelMarkers,

      // ▼ Quando zoom baixo, use CLUSTER.
      taggedMarkers: useCluster ? labelTagged : const [],

      clusterWidgetBuilder: useCluster
          ? (tagged, selectedMarkerPosition, onMarkerSelected) {
        return ClusterAnimatedMarkerLayer<ActiveRoadsData>(
          taggedMarkers: tagged,
          selectedMarkerPosition: selectedMarkerPosition,
          onMarkerSelected: onMarkerSelected,

          // pin visual: o mesmo círculo de rótulo
          markerBuilder: (ctx, taggedMarker, isSelected) {
            final lab = taggedMarker.properties['label']?.toString() ?? '';
            final d   = (taggedMarker.properties['diameter'] as double?) ?? 24.0;
            final f   = (taggedMarker.properties['font'] as double?) ?? 10.0;
            return IgnorePointer(
              ignoring: true, // toque vai para o cluster
              child: RoadLabelCircle(text: lab, diameter: d, fontSize: f),
            );
          },

          titleBuilder: (r) => 'AL-${r.acronym ?? ''} (${r.roadCode ?? ''})',
          subTitleBuilder: (r) => '${r.initialSegment} / ${r.finalSegment}',

          // como os rótulos são só visuais, não precisamos do tooltip inline
          inlineTooltip: false,
          inlineMaxWidth: 240,
          inlineEstimatedHeight: 120,

          // opcional: esconder polígono do cluster

          markerAlignment: Alignment.center,
        );
      }
          : null,

      onCameraChanged: (double z, LatLng center) {
        setState(() {
          _currentZoom = z;
          _centerLat   = center.latitude;
        });

        if (_anchorLatLng != null && _lastMapController != null && _toGlobal != null) {
          final local = _lastMapController!.camera.latLngToScreenOffset(_anchorLatLng!);
          final global = _toGlobal!(local);
          MapTapOverlayTooltip.updatePosition(global);
        }
      },

      onClearPolylineSelection: () async {
        context.read<ActiveRoadsBloc>().add(const ActiveRoadsSelectPolyline(null));
        _anchorLatLng = null;
        _lastMapController = null;
        _toGlobal = null;
        MapTapOverlayTooltip.hide();
      },

      onSelectPolyline: (polyline) async {
        context.read<ActiveRoadsBloc>().add(
          ActiveRoadsSelectPolyline(polyline.tag?.toString()),
        );
      },

      onShowPolylineTooltip: ({
        required BuildContext context,
        required Offset position,
        required Object? tag,
        required MapController mapController,
        LatLng? tapLatLng,
        Offset Function(Offset p)? toGlobal,
      }) async {
        final id = tag?.toString();
        if (id == null) return;

        final road = widget.state.filteredAll.firstWhere(
              (r) => r.id == id,
          orElse: () => widget.state.all.firstWhere(
                (r) => r.id == id,
            orElse: () => null as dynamic,
          ),
        );

        _anchorLatLng = road.anchorForTap(tapLatLng) ?? tapLatLng;
        if (_anchorLatLng == null) return;

        _lastMapController = mapController;
        _toGlobal = toGlobal;

        final overlay = Overlay.of(context);
        if (overlay == null) return;

        MapTapOverlayTooltip.show(
          overlayState: overlay,
          position: position,
          title: 'Rodovia: AL-${road.acronym} (${road.roadCode})',
          subtitle: 'Trecho: ${road.initialSegment} / ${road.finalSegment}, ${road.extension}km de extensão',
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
  }
}
