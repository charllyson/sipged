import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../markers/marker_changed_data.dart';
import '../tooltip/tooltip_animated_card.dart';
import '../tooltip/tooltip_balloon_tip.dart';

class ClusterMarkerBuilder<T> {
  ClusterMarkerBuilder({
    required this.tagged,
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
    this.inlineEstimatedHeight = 150.0,
    this.inlineBalloonHeight = 4.0,
  });

  final MarkerChangedData<T> tagged;
  final LatLng? selectedMarkerPosition;
  final ValueChanged<MarkerChangedData<T>> onMarkerSelected;

  /// Builder do pin.
  final Widget Function(BuildContext, MarkerChangedData<T>, bool isSelected) markerBuilder;

  final String Function(T data)? titleBuilder;
  final String Function(T data)? subTitleBuilder;
  final void Function(LatLng, String)? onTooltipRequested;

  final Alignment markerAlignment;

  /// Overlay externo opcional.
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
  final double inlineYOffset;
  final double inlineClearance;
  final double inlineEstimatedHeight;
  final double inlineBalloonHeight;

  static bool _sameLatLng(LatLng a, LatLng b, {double eps = 1e-9}) {
    return (a.latitude - b.latitude).abs() < eps &&
        (a.longitude - b.longitude).abs() < eps;
  }

  Marker build(BuildContext context) {
    final point = tagged.point;

    const double pinW = 40.0;
    const double pinH = 60.0;

    final String? title =
        titleBuilder?.call(tagged.data) ?? tagged.properties['label']?.toString();
    final String? subTitle = subTitleBuilder?.call(tagged.data);

    final bool isSelected = selectedMarkerPosition != null &&
        _sameLatLng(point, selectedMarkerPosition!);

    final entries = <MapEntry<String, String>>[
      MapEntry(
        'title',
        (title ?? '').trim().isEmpty ? 'Detalhe' : title!.trim(),
      ),
      if ((subTitle ?? '').trim().isNotEmpty)
        MapEntry('subtitle', subTitle!.trim()),
    ];

    final double markerW = math.max(pinW, inlineMaxWidth);
    final double extraTop = (inlineTooltip && isSelected)
        ? (inlineYOffset +
        inlineEstimatedHeight +
        inlineBalloonHeight +
        inlineClearance)
        : 0.0;
    final double markerH = extraTop + pinH;

    return Marker(
      point: point,
      width: markerW,
      height: markerH,
      alignment: markerAlignment,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (inlineTooltip && isSelected)
            Positioned(
              top: inlineYOffset,
              left: (markerW - inlineMaxWidth) / 2,
              right: (markerW - inlineMaxWidth) / 2,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TooltipAnimatedCard(
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
                    maxWidth: inlineMaxWidth,
                    onDetails: onViewDetails == null
                        ? null
                        : () => onViewDetails!(context, tagged),
                    onClose: onClearSelection,
                  ),
                  TooltipBalloonTip(
                    color: Colors.black87,
                    height: inlineBalloonHeight,
                    width: 12,
                  ),
                ],
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
                child: markerBuilder(context, tagged, isSelected),
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
                  onMarkerSelected(tagged);

                  if (onShowTooltipAcima != null && !inlineTooltip) {
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