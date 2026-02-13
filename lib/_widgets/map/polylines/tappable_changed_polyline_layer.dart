import 'package:flutter/material.dart';
import 'package:sipged/_widgets/map/polylines/tappable_polylines.dart'
    show TappablePolylineLayer, TaggedPolyline;
import 'tappable_changed_polyline.dart';

class MapTappablePolylineLayer extends StatelessWidget {
  final List<TappableChangedPolyline> polylines;
  final void Function(List<TappableChangedPolyline> tapped, TapUpDetails details) onTap;
  final void Function(TapUpDetails details)? onMiss;
  final bool polylineCulling; // compat: seguimos aceitando esse nome aqui

  const MapTappablePolylineLayer({
    super.key,
    required this.polylines,
    required this.onTap,
    this.onMiss,
    this.polylineCulling = true,
  });

  @override
  Widget build(BuildContext context) {
    // cria TaggedPolyline correspondentes e um mapa reverso pra recuperar o original
    final tagged = <TaggedPolyline>[];
    final reverse = <TaggedPolyline, TappableChangedPolyline>{};

    for (final e in polylines) {
      final t = TaggedPolyline(
        points: e.points,
        color: e.color,
        strokeWidth: e.strokeWidth,
        tag: e.tag,
      );
      tagged.add(t);
      reverse[t] = e;
    }

    return TappablePolylineLayer(
      culling: polylineCulling, // <- nome novo do parâmetro
      polylines: tagged,
      onTap: (hits, details) {
        final tapped = hits.map((tp) => reverse[tp]!).toList(growable: false);
        onTap(tapped, details);
      },
      onMiss: onMiss,
    );
  }
}
