import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:siged/_widgets/map/markers/tagged_marker.dart';

class ClusterMarkerBuilder<T> {
  final TaggedChangedMarker<T> tagged;
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

  /// Callback do botão "Ver detalhes" dentro do tooltip do pin
  final void Function(BuildContext context, TaggedChangedMarker<T> marker)? onViewDetails;

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
  });

  Marker build(BuildContext context) {
    final point = tagged.point;
    final isSelected = selectedMarkerPosition == point;
    final title = titleBuilder?.call(tagged.data);
    final subTitle = subTitleBuilder?.call(tagged.data);

    // tamanhos
    const double pinSize = 50;
    const double gapAbovePin = 8;            // distância do tooltip ao pin
    const double tooltipReservedHeight = 120; // reserva de altura total
    final double screenW = MediaQuery.of(context).size.width;
    final double tooltipWidth = (screenW * 0.45).clamp(180.0, 280.0);

    return Marker(
      point: point,
      width: isSelected ? tooltipWidth : pinSize,
      height: isSelected ? (pinSize + tooltipReservedHeight) : pinSize,
      // 👇 corrige aqui

      child: GestureDetector(
        behavior: HitTestBehavior.deferToChild,
        onTap: () {
          onMarkerSelected(tagged);
          if (title != null) onTooltipRequested?.call(tagged.point, title);
          if (subTitle != null) onTooltipRequested?.call(tagged.point, subTitle);

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
          builder: (context, scale, child) {
            return Transform.scale(
              alignment: Alignment.bottomCenter, // escala a partir da base
              scale: scale,
              child: AnimatedOpacity(
                opacity: isSelected ? 1.0 : 0.85,
                duration: const Duration(milliseconds: 200),
                child: child,
              ),
            );
          },
          // 👇 agora o tooltip fica POSICIONADO logo acima do pin
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // PIN na base da área
              Positioned(
                bottom: 0,
                left: (isSelected ? (tooltipWidth - pinSize) / 2 : 0),
                width: pinSize,
                height: pinSize,
                child: Center(child: markerBuilder(context, tagged)),
              ),

              if (isSelected && (title != null || subTitle != null))
                Positioned(
                  // imediatamente acima do pin
                  bottom: pinSize + gapAbovePin,
                  left: 0,
                  right: 0,
                  child: SizedBox(
                    width: tooltipWidth,
                    child: _TooltipCard(
                      maxWidth: tooltipWidth,         // <<< trava o card p/ caber
                      title: title,
                      subTitle: subTitle,
                      onDetails: onViewDetails == null
                          ? null
                          : () => onViewDetails!(context, tagged),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

}

/// Cartão compacto do tooltip com botão "Ver detalhes"
class _TooltipCard extends StatelessWidget {
  const _TooltipCard({
    required this.maxWidth,
    this.title,
    this.subTitle,
    this.onDetails,
  });

  final double maxWidth;
  final String? title;
  final String? subTitle;
  final VoidCallback? onDetails;

  @override
  Widget build(BuildContext context) {
    final hasTitle = (title != null && title!.trim().isNotEmpty);
    final hasSub = (subTitle != null && subTitle!.trim().isNotEmpty);

    const double maxCardHeight = 110; // limite vertical dentro da reserva

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // “triângulo” do balão
        Transform.translate(
          offset: const Offset(0, 6),
          child: CustomPaint(
            size: const Size(12, 6),
            painter: TrianglePainter(color: Colors.black.withOpacity(0.90)),
          ),
        ),
        Material(
          elevation: 6,
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.90),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white12, width: 0.5),
              ),
              child: DefaultTextStyle(
                style: const TextStyle(color: Colors.white, fontSize: 10, height: 1.15),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: maxCardHeight),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hasTitle)
                        Text(
                          title!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      if (hasSub) ...[
                        const SizedBox(height: 2),
                        Text(
                          subTitle!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 9.5,
                          ),
                        ),
                      ],
                      if (onDetails != null) ...[
                        const SizedBox(height: 6),
                        SizedBox(
                          height: 28,
                          child: TextButton.icon(
                            onPressed: onDetails,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              backgroundColor: Colors.white.withOpacity(0.08),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 28),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            icon: const Icon(Icons.info_outline_rounded, size: 14),
                            label: const Text(
                              'Ver detalhes',
                              overflow: TextOverflow.ellipsis, // segurança extra
                              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class TrianglePainter extends CustomPainter {
  final Color color;
  TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = ui.Paint()..color = color;

    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant TrianglePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
