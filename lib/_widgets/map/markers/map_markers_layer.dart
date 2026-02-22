// lib/_widgets/map/flutter_map/layers/map_markers_layer.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sipged/_widgets/map/markers/tagged_marker.dart';

class MapMarkersLayer<T> extends StatelessWidget {
  final List<TaggedChangedMarker<T>>? taggedMarkers;
  final Widget Function(
      List<TaggedChangedMarker<T>> taggedMarkers,
      LatLng? selectedMarkerPosition,
      ValueChanged<TaggedChangedMarker<T>> onMarkerSelected,
      )? clusterWidgetBuilder;

  final LatLng? selectedMarkerPosition;
  final ValueChanged<TaggedChangedMarker<T>> onMarkerSelected;

  final List<Marker>? extraMarkers;

  const MapMarkersLayer({
    super.key,
    required this.taggedMarkers,
    required this.clusterWidgetBuilder,
    required this.selectedMarkerPosition,
    required this.onMarkerSelected,
    required this.extraMarkers,
  });

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    final tagged = taggedMarkers;
    final clusterBuilder = clusterWidgetBuilder;
    if (tagged != null && tagged.isNotEmpty && clusterBuilder != null) {
      children.add(
        clusterBuilder(
          tagged,
          selectedMarkerPosition,
          onMarkerSelected,
        ),
      );
    }

    final extras = extraMarkers;
    if (extras != null && extras.isNotEmpty) {
      children.add(
        IgnorePointer(
          ignoring: true,
          child: MarkerLayer(markers: extras),
        ),
      );
    }

    if (children.isEmpty) return const SizedBox.shrink();
    if (children.length == 1) return children.first;
    return Stack(children: children);
  }
}
