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

  ClusterMarkerBuilder({
    required this.tagged,
    required this.selectedMarkerPosition,
    required this.onMarkerSelected,
    required this.markerBuilder,
    this.titleBuilder,
    this.subTitleBuilder,
    this.onTooltipRequested,
    this.onShowTooltipAcima,
  });

  Marker build(BuildContext context) {
    final point = tagged.point;
    final isSelected = selectedMarkerPosition == point;
    final title = titleBuilder?.call(tagged.data);
    final subTitle = subTitleBuilder?.call(tagged.data);

    return Marker(
      width: 50,
      height: 50,
      point: point,
      child: GestureDetector(
        onTapDown: (_) {
          onTooltipRequested?.call(tagged.point, title ?? '');
          onTooltipRequested?.call(tagged.point, subTitle ?? '');
          onMarkerSelected(tagged);
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
              scale: scale,
              child: AnimatedOpacity(
                opacity: isSelected ? 1.0 : 0.85,
                duration: const Duration(milliseconds: 200),
                child: child,
              ),
            );
          },
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              if (isSelected && title != null)
                Positioned(
                  top: -36,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(color: Colors.white, fontSize: 9),
                          softWrap: true,
                        ),
                        if (subTitle != null)
                          Text(
                          subTitle,
                          style: const TextStyle(color: Colors.grey, fontSize: 7.5),
                          softWrap: true,
                        ),
                      ],
                    ),
                  ),
                ),
              markerBuilder(context, tagged),
            ],
          ),
        ),
      ),
    );
  }
}
