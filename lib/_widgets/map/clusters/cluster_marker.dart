// lib/_widgets/map/clusters/cluster_marker.dart

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:sipged/_widgets/overlays/balloon/balloon_body.dart';
import 'package:sipged/_widgets/overlays/balloon/balloon_tile.dart';
import 'package:sipged/_widgets/overlays/balloon/balloon_tip.dart';

class ClusterMarker {
  ClusterMarker({
    required this.marker,
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
    this.inlineYOffset = 4.0,
    this.inlineClearance = 0.0,
    this.inlineEstimatedHeight = 170.0,
    this.inlineBalloonHeight = 10.0,
  });

  final Marker marker;
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
  final double inlineYOffset;
  final double inlineClearance;
  final double inlineEstimatedHeight;

  /// Mantido por compatibilidade.
  ///
  /// Agora a ponta é renderizada pelo BalloonBody/BalloonPopup.
  final double inlineBalloonHeight;

  static bool _sameLatLng(
      LatLng a,
      LatLng b, {
        double eps = 1e-9,
      }) {
    return (a.latitude - b.latitude).abs() < eps &&
        (a.longitude - b.longitude).abs() < eps;
  }

  Marker build(BuildContext context) {
    final point = marker.point;

    const double pinW = 40.0;
    const double pinH = 60.0;

    final String? title = titleBuilder?.call(marker);
    final String? subTitle = subTitleBuilder?.call(marker);

    final bool isSelected = selectedMarkerPosition != null &&
        _sameLatLng(point, selectedMarkerPosition!);

    final entries = <MapEntry<String, String>>[
      MapEntry(
        'title',
        (title ?? '').trim().isEmpty ? 'Detalhe' : title!.trim(),
      ),
      if ((subTitle ?? '').trim().isNotEmpty)
        MapEntry(
          'subtitle',
          subTitle!.trim(),
        ),
    ];

    final double markerW = math.max(pinW, inlineMaxWidth);

    final double extraTop = (inlineTooltip && isSelected)
        ? inlineYOffset + inlineEstimatedHeight + inlineClearance
        : 0.0;

    final double markerH = extraTop + pinH;

    return Marker(
      key: marker.key,
      point: point,
      width: markerW,
      height: markerH,
      alignment: markerAlignment,
      rotate: marker.rotate,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (inlineTooltip && isSelected)
            Positioned(
              top: inlineYOffset,
              left: (markerW - inlineMaxWidth) / 2,
              width: inlineMaxWidth,
              child: Material(
                type: MaterialType.transparency,
                child: BalloonBody(
                  width: inlineMaxWidth,
                  maxHeight: inlineEstimatedHeight,
                  tipSide: BalloonTipSide.bottom,
                  title: entries
                      .firstWhere(
                        (e) => e.key == 'title',
                    orElse: () => const MapEntry('title', 'Detalhe'),
                  )
                      .value,
                  headerIcon: Icons.place_outlined,
                  actionLabel: onViewDetails == null ? null : 'Detalhes',
                  showAction: onViewDetails != null,
                  onAction: onViewDetails == null
                      ? null
                      : () => onViewDetails!(context, marker),
                  emptyMessage: 'Nenhuma informação encontrada.',
                  items: [
                    BalloonTileData(
                      id: marker.hashCode.toString(),
                      title: entries
                          .firstWhere(
                            (e) => e.key == 'title',
                        orElse: () => const MapEntry('title', 'Detalhe'),
                      )
                          .value,
                      subtitle: () {
                        final s = entries
                            .firstWhere(
                              (e) => e.key == 'subtitle',
                          orElse: () => const MapEntry('subtitle', ''),
                        )
                            .value
                            .trim();

                        return s.isEmpty ? null : s;
                      }(),
                      details: onViewDetails == null
                          ? null
                          : 'Toque para visualizar os detalhes.',
                      icon: Icons.place_outlined,
                      accentColor: Colors.blue.shade800,
                      onTap: onViewDetails == null
                          ? null
                          : () => onViewDetails!(context, marker),
                    ),
                  ],
                ),
              ),
            ),

          Positioned(
            bottom: 0,
            left: (markerW - pinW) / 2,
            width: pinW,
            height: pinH,
            child: IgnorePointer(
              child: SizedBox(
                width: pinW,
                height: pinH,
                child: markerBuilder(
                  context,
                  marker,
                  isSelected,
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 0,
            left: (markerW - pinW) / 2,
            width: pinW,
            height: pinH,
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: () {
                  onMarkerSelected(marker);

                  final currentTitle = entries
                      .firstWhere(
                        (e) => e.key == 'title',
                    orElse: () => const MapEntry('title', 'Detalhe'),
                  )
                      .value;

                  onTooltipRequested?.call(point, currentTitle);

                  if (onShowTooltipAcima != null && !inlineTooltip) {
                    onShowTooltipAcima!(
                      context: context,
                      position: point,
                      entries: entries,
                      onDetails: onViewDetails == null
                          ? null
                          : () => onViewDetails!(context, marker),
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