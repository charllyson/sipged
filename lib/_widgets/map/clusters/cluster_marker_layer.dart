import 'package:flutter/material.dart';
import 'package:flutter_map_marker_cluster_plus/flutter_map_marker_cluster_plus.dart';
import 'package:latlong2/latlong.dart';

import '../markers/marker_changed_data.dart';
import 'cluster_marker_builder.dart';

class ClusterMarkerLayer<T> extends StatelessWidget {
  const ClusterMarkerLayer({
    super.key,
    required this.taggedMarkers,
    required this.selectedMarkerPosition,
    required this.onMarkerSelected,
    required this.markerBuilder,
    required this.markerAlignment,
    this.titleBuilder,
    this.subTitleBuilder,
    this.onTooltipRequested,
    this.onShowTooltipAcima,
    this.onViewDetails,
    this.onClearSelection,
    this.inlineTooltip = true,
    this.inlineMaxWidth = 280,
    this.inlineEstimatedHeight = 150.0,
    this.inlineYOffset = 4.0,
    this.inlineClearance = 0,
  });

  final List<MarkerChangedData<T>> taggedMarkers;
  final LatLng? selectedMarkerPosition;
  final ValueChanged<MarkerChangedData<T>> onMarkerSelected;

  final Widget Function(BuildContext, MarkerChangedData<T>, bool isSelected)
  markerBuilder;

  final String Function(T data)? titleBuilder;
  final String Function(T data)? subTitleBuilder;
  final void Function(LatLng, String)? onTooltipRequested;

  final Alignment markerAlignment;

  final void Function({
  required BuildContext context,
  required LatLng position,
  required List<MapEntry<String, String>> entries,
  VoidCallback? onDetails,
  VoidCallback? onClose,
  })? onShowTooltipAcima;

  final void Function(BuildContext, MarkerChangedData<T>)? onViewDetails;
  final VoidCallback? onClearSelection;

  final bool inlineTooltip;
  final double inlineMaxWidth;
  final double inlineEstimatedHeight;
  final double inlineYOffset;
  final double inlineClearance;

  @override
  Widget build(BuildContext context) {
    final sorted = List<MarkerChangedData<T>>.from(taggedMarkers);

    if (selectedMarkerPosition != null) {
      sorted.sort((a, b) {
        final aSel = _same(a.point, selectedMarkerPosition!);
        final bSel = _same(b.point, selectedMarkerPosition!);
        if (aSel == bSel) return 0;
        return aSel ? 1 : -1;
      });
    }

    final markers = sorted
        .map(
          (tagged) => ClusterMarkerBuilder<T>(
        tagged: tagged,
        selectedMarkerPosition: selectedMarkerPosition,
        onMarkerSelected: onMarkerSelected,
        markerBuilder: markerBuilder,
        titleBuilder: titleBuilder,
        subTitleBuilder: subTitleBuilder,
        onTooltipRequested: onTooltipRequested,
        onShowTooltipAcima: onShowTooltipAcima,
        onViewDetails: onViewDetails,
        onClearSelection: onClearSelection,
        inlineTooltip: inlineTooltip,
        inlineMaxWidth: inlineMaxWidth,
        inlineYOffset: inlineYOffset,
        inlineClearance: inlineClearance,
        inlineEstimatedHeight: inlineEstimatedHeight,
        inlineBalloonHeight: 4.0,
        markerAlignment: markerAlignment,
      ).build(context),
    )
        .toList(growable: false);

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

  bool _same(LatLng a, LatLng b, {double eps = 1e-9}) {
    return (a.latitude - b.latitude).abs() < eps &&
        (a.longitude - b.longitude).abs() < eps;
  }
}