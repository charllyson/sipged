import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_marker_cluster_plus/flutter_map_marker_cluster_plus.dart';

import 'cluster_marker_widget.dart';
import 'tagged_marker.dart';

class AnimatedClusterMarkerLayer<T> extends StatelessWidget {
  final List<TaggedChangedMarker<T>> taggedMarkers;
  final LatLng? selectedMarkerPosition;
  final ValueChanged<TaggedChangedMarker<T>> onMarkerSelected;
  final Widget Function(BuildContext context, TaggedChangedMarker<T> marker) markerBuilder;
  final String Function(T data)? titleBuilder;
  final String Function(T data)? subTitleBuilder;

  final void Function(LatLng, String)? onTooltipRequested;
  final void Function({
  required BuildContext context,
  required LatLng position,
  required List<MapEntry<String, String>> entries,
  })? onShowTooltipAcima;

  /// Repassa o callback do "Ver detalhes"
  final void Function(BuildContext context, TaggedChangedMarker<T> marker)? onViewDetails;

  const AnimatedClusterMarkerLayer({
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
  });

  @override
  Widget build(BuildContext context) {
    final markers = taggedMarkers
        .map((tagged) => ClusterMarkerBuilder<T>(
      tagged: tagged,
      selectedMarkerPosition: selectedMarkerPosition,
      onMarkerSelected: onMarkerSelected,
      markerBuilder: markerBuilder,
      titleBuilder: titleBuilder,
      subTitleBuilder: subTitleBuilder,
      onTooltipRequested: onTooltipRequested,
      onShowTooltipAcima: onShowTooltipAcima,
      onViewDetails: onViewDetails,
    ).build(context))
        .toList();

    return MarkerClusterLayerWidget(
      options: MarkerClusterLayerOptions(
        markers: markers,
        maxClusterRadius: 30,
        size: const Size(40, 40),
        zoomToBoundsOnClick: true,
        spiderfyCircleRadius: 100,
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
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
