import 'package:flutter/material.dart';
import 'package:flutter_map_tappable_polyline/flutter_map_tappable_polyline.dart';
import 'tappable_changed_polyline.dart';

class MapTappablePolylineLayer extends StatelessWidget {
  final List<TappableChangedPolyline> polylines;
  final void Function(List<TappableChangedPolyline> tapped, TapUpDetails details) onTap;
  final bool polylineCulling;

  const MapTappablePolylineLayer({
    super.key,
    required this.polylines,
    required this.onTap,
    this.polylineCulling = true,
  });

  @override
  Widget build(BuildContext context) {
    return TappablePolylineLayer(
      polylineCulling: polylineCulling,
      polylines: polylines
          .map((e) => TaggedPolyline(
        points: e.points,
        color: e.color,
        strokeWidth: e.strokeWidth,
        isDotted: e.isDotted,
        tag: e.tag,
      ))
          .toList(),
      onTap: (polys, details) {
        final tapped = polys.map((e) {
          return polylines.firstWhere((p) => p.points == e.points && p.tag == e.tag);
        }).toList();
        onTap(tapped, details);
      },
    );
  }
}
