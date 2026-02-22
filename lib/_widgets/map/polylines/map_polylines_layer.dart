// lib/_widgets/map/flutter_map/layers/map_polylines_layer.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import 'package:sipged/_widgets/map/polylines/tappable_changed_polyline.dart';
import 'package:sipged/_widgets/map/polylines/tappable_changed_polyline_layer.dart';

class MapPolylinesLayer extends StatelessWidget {
  final List<TappableChangedPolyline> polylines;
  final void Function(List<TappableChangedPolyline> tapped, TapUpDetails details) onTap;

  const MapPolylinesLayer({
    super.key,
    required this.polylines,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tappable = polylines.where((p) => p.hitTestable).toList(growable: false);
    final nonTappable = polylines.where((p) => !p.hitTestable).toList(growable: false);

    final children = <Widget>[];

    if (nonTappable.isNotEmpty) {
      children.add(
        PolylineLayer(
          polylines: nonTappable
              .map(
                (p) => Polyline(
              points: p.points,
              color: p.color,
              strokeWidth: p.strokeWidth,
            ),
          )
              .toList(growable: false),
        ),
      );
    }

    if (tappable.isNotEmpty) {
      children.add(
        MapTappablePolylineLayer(
          polylines: tappable,
          onTap: onTap,
          polylineCulling: true,
        ),
      );
    }

    if (children.isEmpty) return const SizedBox.shrink();
    if (children.length == 1) return children.first;

    return Stack(children: children);
  }
}
