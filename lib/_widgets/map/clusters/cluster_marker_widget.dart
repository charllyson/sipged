// lib/_widgets/map/clusters/cluster_marker_widget.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../markers/tagged_marker.dart';

class ClusterMarkerBuilder<T> {
  ClusterMarkerBuilder({
    required this.tagged,
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

  final TaggedChangedMarker<T> tagged;
  final LatLng? selectedMarkerPosition;
  final ValueChanged<TaggedChangedMarker<T>> onMarkerSelected;

  final Widget Function(BuildContext, TaggedChangedMarker<T>) markerBuilder;

  final String Function(T data)? titleBuilder;
  final String Function(T data)? subTitleBuilder;

  final void Function(LatLng, String)? onTooltipRequested;

  /// Callback para o PAI abrir tooltip em overlay (fora do Marker).
  final void Function({
  required BuildContext context,
  required LatLng position,
  required List<MapEntry<String, String>> entries,
  VoidCallback? onDetails,
  VoidCallback? onClose,
  })? onShowTooltipAcima;

  final void Function(BuildContext, TaggedChangedMarker<T>)? onViewDetails;
  final VoidCallback? onClearSelection;

  Marker build(BuildContext context) {
    final point = tagged.point;

    // dimensões do seu pin (não altere para não deslocar a âncora)
    const double chipW = 120.0;
    const double chipH = 40.0;

    final String? title =
        titleBuilder?.call(tagged.data) ?? (tagged.properties['label']?.toString());
    final String? subTitle = subTitleBuilder?.call(tagged.data);

    return Marker(
      point: point,
      width: chipW,
      height: chipH,
      alignment: Alignment.center,
      child: Stack(
        children: [
          // camada visual (sem toque)
          IgnorePointer(
            child: SizedBox(
              width: chipW,
              height: chipH,
              child: markerBuilder(context, tagged),
            ),
          ),

          // camada de toque apenas no chip
          Positioned.fill(
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: () {
                  onMarkerSelected(tagged);

                  if (onShowTooltipAcima != null) {
                    final entries = <MapEntry<String, String>>[
                      MapEntry('title',
                          (title ?? '').trim().isEmpty ? 'Detalhe' : title!.trim()),
                      if ((subTitle ?? '').trim().isNotEmpty)
                        MapEntry('subtitle', subTitle!.trim()),
                    ];

                    onShowTooltipAcima!(
                      context: context,
                      position: point,
                      entries: entries,
                      onDetails: onViewDetails == null
                          ? null
                          : () => onViewDetails!(context, tagged),
                      onClose: onClearSelection,
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
