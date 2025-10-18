// lib/_widgets/map/clusters/cluster_marker_widget.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../markers/tagged_marker.dart';
import '../tooltip/tooltip_animated_card.dart';
import '../tooltip/tooltip_balloon_tip.dart';

class ClusterMarkerBuilder<T> {
  ClusterMarkerBuilder({
    required this.tagged,
    required this.selectedMarkerPosition,
    required this.onMarkerSelected,

    /// Builder do pin (visual inalterado)
    required this.markerBuilder,

    this.titleBuilder,
    this.subTitleBuilder,

    // ainda suportado, caso você queira continuar usando overlay externo
    this.onTooltipRequested,
    this.onShowTooltipAcima,

    this.onViewDetails,
    this.onClearSelection,

    // Configurações do tooltip inline
    this.inlineTooltip = true,
    this.inlineMaxWidth = 280,
    this.inlineYOffset = 4.0,     // ▼ card quase encostado no ponto
    this.inlineClearance = 0.0,   // ▼ SEM espaçamento entre balão e pin
    this.inlineEstimatedHeight = 150.0,
    this.inlineBalloonHeight = 4.0, // ▼ balão pequeno, “colado”
    required this.markerAlignment,
  });

  final TaggedChangedMarker<T> tagged;
  final LatLng? selectedMarkerPosition;
  final ValueChanged<TaggedChangedMarker<T>> onMarkerSelected;

  /// Agora o builder recebe isSelected (sem mudar o visual do pin)
  final Widget Function(BuildContext, TaggedChangedMarker<T>, bool isSelected) markerBuilder;

  final String Function(T data)? titleBuilder;
  final String Function(T data)? subTitleBuilder;
  final void Function(LatLng, String)? onTooltipRequested;
  final Alignment markerAlignment;

  /// Pai pode desenhar tooltip em overlay fora do marker (opcional)
  final void Function({
  required BuildContext context,
  required LatLng position,
  required List<MapEntry<String, String>> entries,
  VoidCallback? onDetails,
  VoidCallback? onClose,
  })? onShowTooltipAcima;

  final void Function(BuildContext, TaggedChangedMarker<T>)? onViewDetails;
  final VoidCallback? onClearSelection;

  // Config do tooltip inline
  final bool inlineTooltip;
  final double inlineMaxWidth;
  final double inlineYOffset;       // espaço do topo até o card
  final double inlineClearance;     // espaço entre card+balão e pin (0 = colado)
  final double inlineEstimatedHeight;
  final double inlineBalloonHeight;

  static bool _sameLatLng(LatLng a, LatLng b, {double eps = 1e-9}) {
    return (a.latitude - b.latitude).abs() < eps &&
        (a.longitude - b.longitude).abs() < eps;
  }

  Marker build(BuildContext context) {
    final point = tagged.point;

    // retângulo do pin (visual existente)
    const double chipW = 40.0;
    const double chipH = 60.0;

    final String? title =
        titleBuilder?.call(tagged.data) ?? (tagged.properties['label']?.toString());
    final String? subTitle = subTitleBuilder?.call(tagged.data);

    final bool isSelected =
        selectedMarkerPosition != null && _sameLatLng(point, selectedMarkerPosition!);

    // entradas para o tooltip (inline ou overlay)
    final entries = <MapEntry<String, String>>[
      MapEntry('title', (title ?? '').trim().isEmpty ? 'Detalhe' : title!.trim()),
      if ((subTitle ?? '').trim().isNotEmpty) MapEntry('subtitle', subTitle!.trim()),
    ];

    // LARGURA do Marker precisa comportar o card (sem alterar o visual)
    final double markerW = math.max(chipW, inlineMaxWidth);

    // ALTURA do Marker:
    // topo (offset) + altura do card + balão + clearance + altura do pin
    final double extraTop = (inlineTooltip && isSelected)
        ? (inlineYOffset + inlineEstimatedHeight + inlineBalloonHeight + inlineClearance)
        : 0.0;
    final double markerH = extraTop + chipH;

    return Marker(
      point: point,
      width: markerW,
      height: markerH,
      alignment: markerAlignment,
      child: Stack(
        clipBehavior: Clip.hardEdge, // hit-test acompanha o novo tamanho
        children: [
          // ===================== TOOLTIP INLINE (CLICÁVEL) =====================
          if (inlineTooltip && isSelected)
            Positioned(
              // O card nasce do TOPO do Marker (que é o ponto do mapa)
              top: inlineYOffset,
              left: (markerW - inlineMaxWidth) / 2,
              right: (markerW - inlineMaxWidth) / 2,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TooltipAnimatedCard(
                    title: entries
                        .firstWhere((e) => e.key == 'title', orElse: () => const MapEntry('title', 'Detalhe'))
                        .value,
                    subtitle: () {
                      final s = entries
                          .firstWhere((e) => e.key == 'subtitle', orElse: () => const MapEntry('subtitle', ''))
                          .value
                          .trim();
                      return s.isEmpty ? null : s;
                    }(),
                    maxWidth: inlineMaxWidth,
                    onDetails: onViewDetails == null ? null : () => onViewDetails!(context, tagged),
                    onClose: onClearSelection,
                  ),
                  const TooltipBalloonTip(color: Colors.black87, height: 4, width: 12),
                ],
              ),
            ),

          // ===================== PIN (visual) =====================
          Positioned(
            // O pin continua embaixo, visual inalterado
            bottom: 0,
            left: (markerW - chipW) / 2,
            width: chipW,
            height: chipH,
            child: IgnorePointer(
              child: SizedBox(
                width: chipW,
                height: chipH,
                child: markerBuilder(context, tagged, isSelected),
              ),
            ),
          ),

          // ===================== toque SÓ no pin =====================
          Positioned(
            bottom: 0,
            left: (markerW - chipW) / 2,
            width: chipW,
            height: chipH,
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
                      onDetails: onViewDetails == null ? null : () => onViewDetails!(context, tagged),
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
