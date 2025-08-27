import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

// TROQUE os wrappers locais pelos do pacote PLUS:
import 'package:flutter_map_marker_cluster_plus/flutter_map_marker_cluster_plus.dart';
// Se você usa popups no cluster, há também o:
// import 'package:flutter_map_marker_popup_plus/flutter_map_marker_popup_plus.dart';

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
    // GARANTA que cada ClusterMarkerBuilder.build retorne um Marker COM 'child'
    final markers = taggedMarkers
        .map((tagged) => ClusterMarkerBuilder(
      tagged: tagged,
      selectedMarkerPosition: selectedMarkerPosition,
      onMarkerSelected: onMarkerSelected,
      markerBuilder: markerBuilder,         // deve produzir um Widget para o 'child'
      titleBuilder: titleBuilder,
      subTitleBuilder: subTitleBuilder,
      onTooltipRequested: onTooltipRequested,
      onShowTooltipAcima: onShowTooltipAcima,
    ).build(context))
        .toList();

    return MarkerClusterLayerWidget(
      options: MarkerClusterLayerOptions(
        markers: markers,
        maxClusterRadius: 30,
        size: const Size(40, 40),
        zoomToBoundsOnClick: true,
        spiderfyCircleRadius: 100,
        // 'forceIntegerZoomLevel' não é necessário no v8; remova se sua versão reclamar:
        // forceIntegerZoomLevel: true,

        // Se sua versão do PLUS expõe animações, mantenha; se não, comente:
        // animationsOptions: const AnimationsOptions(
        //   centerMarker: Duration(milliseconds: 200),
        // ),

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
