// lib/_widgets/map/markers/cluster_marker_builder.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:siged/_widgets/map/markers/balloon_tip.dart';
import 'package:siged/_widgets/map/markers/tooltip_card.dart';
import 'tagged_marker.dart';

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
    this.onClearSelection, // 👈 novo
  });

  final TaggedChangedMarker<T> tagged;
  final LatLng? selectedMarkerPosition;
  final ValueChanged<TaggedChangedMarker<T>> onMarkerSelected;

  /// constrói o PIN visual
  final Widget Function(BuildContext context, TaggedChangedMarker<T> marker) markerBuilder;

  /// texto do tooltip
  final String Function(T data)? titleBuilder;
  final String Function(T data)? subTitleBuilder;

  /// integrações opcionais
  final void Function(LatLng, String)? onTooltipRequested;
  final void Function({
  required BuildContext context,
  required LatLng position,
  required List<MapEntry<String, String>> entries,
  })? onShowTooltipAcima;

  final void Function(BuildContext context, TaggedChangedMarker<T> marker)? onViewDetails;
  final VoidCallback? onClearSelection;

  Marker build(BuildContext context) {
    final point = tagged.point;
    final isSelected = selectedMarkerPosition == point;

    final String? title = titleBuilder?.call(tagged.data);
    final String? subTitle = subTitleBuilder?.call(tagged.data);

    // tamanhos
    const double pinSize = 50;
    const double gapAbovePin = 8;
    const double reservedTooltipHeight = 120; // espaço vertical previsto para o card

    // largura do tooltip, com clamp
    final double screenW = MediaQuery.of(context).size.width;
    final double tooltipWidth = math.min(280.0, math.max(180.0, screenW * 0.45));

    // altura/largura finais do Marker (precisam comportar o tooltip)
    final double markerWidth = isSelected ? tooltipWidth : pinSize;
    final double markerHeight = isSelected ? (pinSize + reservedTooltipHeight) : pinSize;

    return Marker(
      point: point,
      width: markerWidth,
      height: markerHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // =============== PIN (único com animação de scale) ===============
          Positioned(
            bottom: 0,
            left: isSelected ? (tooltipWidth - pinSize) / 2 : 0,
            width: pinSize,
            height: pinSize,
            child: Center(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  // alterna seleção
                  onMarkerSelected(tagged);

                  // callbacks opcionais
                  final t = titleBuilder?.call(tagged.data);
                  final s = subTitleBuilder?.call(tagged.data);
                  if (t != null && t.isNotEmpty) onTooltipRequested?.call(tagged.point, t);
                  if (s != null && s.isNotEmpty) onTooltipRequested?.call(tagged.point, s);

                  final entries = tagged.properties.entries
                      .where((e) => e.value != null && e.value.toString().isNotEmpty)
                      .map((e) => MapEntry(e.key, e.value.toString()))
                      .toList();

                  onShowTooltipAcima?.call(
                    context: context,
                    position: tagged.point,
                    entries: entries,
                  );
                },
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 1.0, end: isSelected ? 1.6 : 1.0),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutBack,
                  builder: (context, scale, pin) => Transform.scale(
                    alignment: Alignment.bottomCenter,
                    scale: scale,
                    child: pin,
                  ),
                  child: markerBuilder(context, tagged),
                ),
              ),
            ),
          ),

          // =============== TOOLTIP (sem scale, largura fixa) ===============
          if (isSelected && ((title?.trim().isNotEmpty ?? false) || (subTitle?.trim().isNotEmpty ?? false)))
            Positioned(
              bottom: pinSize + gapAbovePin,
              left: 0,
              right: 0,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  width: tooltipWidth,
                  child: TooltipCard(
                    maxWidth: tooltipWidth,
                    title: title,
                    subTitle: subTitle,
                    onDetails: onViewDetails == null ? null : () => onViewDetails!(context, tagged),
                    onClose: onClearSelection, // 👈 agora limpa seleção de verdade
                  ),
                ),
              ),
            ),

          // =============== SETA (alinhada ao centro do tooltip) ===============
          if (isSelected)
            Positioned(
              bottom: pinSize + 2,
              left: 0,
              right: 0,
              child: SizedBox(
                width: tooltipWidth,
                child: const Center(
                  child: BalloonTip(color: Color(0xE6000000)), // mesma cor do card
                ),
              ),
            ),
        ],
      ),
    );
  }
}
