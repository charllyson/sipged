import 'package:flutter/material.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
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
  });

  @override
  Widget build(BuildContext context) {
    final markers = taggedMarkers.map((tagged) => ClusterMarkerBuilder(
      tagged: tagged,
      selectedMarkerPosition: selectedMarkerPosition,
      onMarkerSelected: onMarkerSelected,
      markerBuilder: markerBuilder,
      titleBuilder: titleBuilder,
      subTitleBuilder: subTitleBuilder,
      onTooltipRequested: onTooltipRequested,
      onShowTooltipAcima: onShowTooltipAcima,
    ).build(context)).toList();
    return MarkerClusterLayerWidget(
      options: MarkerClusterLayerOptions(
        markers: markers,
        maxClusterRadius: 30, // menor = clusters só em zoom muito distante
        size: const Size(40, 40),
        zoomToBoundsOnClick: true,
        spiderfyCircleRadius: 100,
        forceIntegerZoomLevel: true,
        animationsOptions: const AnimationsOptions(centerMarker: Duration(milliseconds: 200)),
        builder: (context, cluster) => Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black54,
          ),
          child: Center(
            child: Text(
              '${cluster.length}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
