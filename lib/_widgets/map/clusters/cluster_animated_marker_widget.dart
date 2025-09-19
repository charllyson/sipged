// lib/_widgets/map/clusters/cluster_animated_marker_widget.dart
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_marker_cluster_plus/flutter_map_marker_cluster_plus.dart';

import '../markers/tagged_marker.dart';
import 'cluster_marker_widget.dart';

class ClusterAnimatedMarkerLayer<T> extends StatelessWidget {
  const ClusterAnimatedMarkerLayer({
    super.key,
    required this.taggedMarkers,
    required this.selectedMarkerPosition,
    required this.onMarkerSelected,
    required this.markerBuilder,
    this.titleBuilder,
    this.subTitleBuilder,
    this.onTooltipRequested,
    this.onShowTooltipAcima,
    this.onViewDetails,
    this.onClearSelection,
  });

  final List<TaggedChangedMarker<T>> taggedMarkers;
  final LatLng? selectedMarkerPosition;
  final ValueChanged<TaggedChangedMarker<T>> onMarkerSelected;

  final Widget Function(BuildContext context, TaggedChangedMarker<T> marker)
  markerBuilder;

  final String Function(T data)? titleBuilder;
  final String Function(T data)? subTitleBuilder;

  final void Function(LatLng, String)? onTooltipRequested;

  /// O **PAI** desenha o tooltip fora do Marker (overlay sobre o mapa).
  final void Function({
  required BuildContext context,
  required LatLng position,
  required List<MapEntry<String, String>> entries,
  VoidCallback? onDetails,
  VoidCallback? onClose,
  })? onShowTooltipAcima;

  final void Function(BuildContext, TaggedChangedMarker<T>)? onViewDetails;
  final VoidCallback? onClearSelection;

  @override
  Widget build(BuildContext context) {
    final markers = taggedMarkers
        .map(
          (tagged) => ClusterMarkerBuilder<T>(
        tagged: tagged,
        selectedMarkerPosition: selectedMarkerPosition,
        onMarkerSelected: onMarkerSelected,
        markerBuilder: markerBuilder,
        titleBuilder: titleBuilder,
        subTitleBuilder: subTitleBuilder,
        onTooltipRequested: onTooltipRequested,
        onShowTooltipAcima: onShowTooltipAcima, // repassa
        onViewDetails: onViewDetails,
        onClearSelection: onClearSelection,
      ).build(context),
    )
        .toList();

    // 🔎 Não coloque barreira de clique-fora aqui. Deixe no overlay do PAI.
    return MarkerClusterLayerWidget(
      options: MarkerClusterLayerOptions(
        markers: markers,
        maxClusterRadius: 30,
        disableClusteringAtZoom: 17,
        spiderfyCluster: true,
        zoomToBoundsOnClick: false,
        spiderfyCircleRadius: 90,
        showPolygon: true,
        polygonOptions: const PolygonOptions(
          borderColor: Colors.black26,
          color: Color(0x11000000),
          borderStrokeWidth: 1.0,
        ),
        builder: (context, cluster) => Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black54,
            border: Border.all(color: Colors.white, width: 2),
          ),
          alignment: Alignment.center,
          child: Text(
            '${cluster.length}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
