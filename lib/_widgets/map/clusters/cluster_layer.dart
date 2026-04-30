// lib/_widgets/map/clusters/cluster_layer.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster_plus/flutter_map_marker_cluster_plus.dart';
import 'package:latlong2/latlong.dart';

import 'cluster_marker.dart';

class ClusterLayer extends StatelessWidget {
  const ClusterLayer({
    super.key,
    required this.markers,
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
    this.inlineClearance = 0.0,
    this.maxClusterRadius = 30,
    this.disableClusteringAtZoom = 17,
    this.spiderfyCluster = true,
    this.zoomToBoundsOnClick = false,
    this.spiderfyCircleRadius = 90,
    this.showPolygon = true,
  });

  final List<Marker> markers;

  final LatLng? selectedMarkerPosition;
  final ValueChanged<Marker> onMarkerSelected;

  final Widget Function(
      BuildContext context,
      Marker marker,
      bool isSelected,
      ) markerBuilder;

  final String Function(Marker marker)? titleBuilder;
  final String Function(Marker marker)? subTitleBuilder;
  final void Function(LatLng position, String title)? onTooltipRequested;

  final Alignment markerAlignment;

  final void Function({
  required BuildContext context,
  required LatLng position,
  required List<MapEntry<String, String>> entries,
  VoidCallback? onDetails,
  VoidCallback? onClose,
  })? onShowTooltipAcima;

  final void Function(BuildContext context, Marker marker)? onViewDetails;
  final VoidCallback? onClearSelection;

  final bool inlineTooltip;
  final double inlineMaxWidth;
  final double inlineEstimatedHeight;
  final double inlineYOffset;
  final double inlineClearance;

  final int maxClusterRadius;
  final int disableClusteringAtZoom;
  final bool spiderfyCluster;
  final bool zoomToBoundsOnClick;
  final int spiderfyCircleRadius;
  final bool showPolygon;

  @override
  Widget build(BuildContext context) {
    final sorted = List<Marker>.from(markers);

    if (selectedMarkerPosition != null) {
      sorted.sort((a, b) {
        final aSel = _same(a.point, selectedMarkerPosition!);
        final bSel = _same(b.point, selectedMarkerPosition!);

        if (aSel == bSel) return 0;
        return aSel ? 1 : -1;
      });
    }

    final builtMarkers = sorted.map((marker) {
      return ClusterMarker(
        marker: marker,
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
      ).build(context);
    }).toList(growable: false);

    return MarkerClusterLayerWidget(
      options: MarkerClusterLayerOptions(
        markers: builtMarkers,
        maxClusterRadius: maxClusterRadius,
        disableClusteringAtZoom: disableClusteringAtZoom,
        spiderfyCluster: spiderfyCluster,
        zoomToBoundsOnClick: zoomToBoundsOnClick,
        spiderfyCircleRadius: spiderfyCircleRadius,
        showPolygon: showPolygon,
        polygonOptions: const PolygonOptions(
          borderColor: Colors.black26,
          color: Color(0x11000000),
          borderStrokeWidth: 1.0,
        ),
        builder: (context, cluster) {
          return Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black54,
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              '${cluster.length}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
      ),
    );
  }

  bool _same(
      LatLng a,
      LatLng b, {
        double eps = 1e-9,
      }) {
    return (a.latitude - b.latitude).abs() < eps &&
        (a.longitude - b.longitude).abs() < eps;
  }
}