library flutter_map_tappable_polyline_v8;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Polyline com 'tag' (herda Polyline público do flutter_map v8)
class TaggedPolyline extends Polyline {
  final String? tag;
  final List<Offset> _offsets = <Offset>[];

  TaggedPolyline({
    required super.points,
    super.strokeWidth = 1.0,
    super.color = const Color(0xFF00FF00),
    super.borderStrokeWidth = 0.0,
    super.borderColor = const Color(0xFFFFFF00),
    super.gradientColors,
    super.colorsStop,
    // ⚠️ `isDotted` não é mais suportado no Polyline público do v8
    this.tag,
  });
}

/// Camada clicável compatível com flutter_map ^8.2.1
class TappablePolylineLayer extends StatelessWidget {
  final List<TaggedPolyline> polylines;

  /// Distância máxima (px) do toque até o segmento para considerar hit
  final double pointerDistanceTolerance;

  /// Chamado quando 1+ polylines foram atingidas
  final void Function(List<TaggedPolyline> hits, TapUpDetails tap)? onTap;

  /// Chamado quando nada foi atingido
  final void Function(TapUpDetails tap)? onMiss;

  /// Se true, faz culling manual por bounds visível
  final bool culling;

  const TappablePolylineLayer({
    super.key,
    this.polylines = const <TaggedPolyline>[],
    this.onTap,
    this.onMiss,
    this.pointerDistanceTolerance = 15,
    this.culling = false,
  });

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);

    // Filtra por bounds visível (opcional)
    final visible = culling
        ? polylines
        .where((p) => p.boundingBox.isOverlapping(camera.visibleBounds))
        .toList(growable: false)
        : polylines;

    _rebuildOffsetsForFrame(context, visible);

    // Desenho: PolylineLayer oficial
    // Tap: GestureDetector por cima (hit-test custom)
    return GestureDetector(
      onDoubleTap: () {}, // necessário p/ onDoubleTapDown disparar
      onDoubleTapDown: (details) => _zoomMap(details, context),
      onTapUp: (details) {
        _forwardCallToMapOptions(details, context);
        _handlePolylineTap(details);
      },
      child: PolylineLayer(
        polylines: visible,
        // ⚠️ no v8 não existe mais `polylineCulling`; o culling estável é interno,
        // e aqui fazemos um culling manual opcional via `culling` acima.
      ),
    );
  }

  void _rebuildOffsetsForFrame(BuildContext context, List<TaggedPolyline> lines) {
    final cam = MapCamera.of(context);

    for (final poly in lines) {
      poly._offsets.clear();

      for (final latLng in poly.points) {
        // v8.2.1: LatLng -> Offset (px locais do widget)
        final Offset p = cam.latLngToScreenOffset(latLng);
        poly._offsets.add(p);
      }
    }
  }


  void _handlePolylineTap(TapUpDetails details) {
    final Map<double, List<TaggedPolyline>> candidates = {};

    for (final current in polylines) {
      final offs = current._offsets;
      for (var j = 0; j < offs.length - 1; j++) {
        final a = offs[j];
        final b = offs[j + 1];
        final tap = details.localPosition;

        final dist = _pointToSegmentDistance(tap, a, b);
        final inside = _isProjectionInsideSegment(tap, a, b);

        if (dist <= pointerDistanceTolerance && inside) {
          candidates[dist] ??= <TaggedPolyline>[];
          candidates[dist]!.add(current);
        }
      }
    }

    if (candidates.isEmpty) {
      onMiss?.call(details);
      return;
    }

    final closest = candidates.keys.reduce(math.min);
    onTap?.call(candidates[closest]!, details);
  }

  // Distância euclidiana ponto->segmento (em px)
  double _pointToSegmentDistance(Offset p, Offset a, Offset b) {
    final vx = b.dx - a.dx, vy = b.dy - a.dy;
    final wx = p.dx - a.dx, wy = p.dy - a.dy;

    final c1 = wx * vx + wy * vy;
    if (c1 <= 0) return _dist(p, a);

    final c2 = vx * vx + vy * vy;
    if (c2 <= c1) return _dist(p, b);

    final t = c1 / c2;
    final proj = Offset(a.dx + t * vx, a.dy + t * vy);
    return _dist(p, proj);
  }

  bool _isProjectionInsideSegment(Offset p, Offset a, Offset b) {
    final vx = b.dx - a.dx, vy = b.dy - a.dy;
    final wx = p.dx - a.dx, wy = p.dy - a.dy;

    final c1 = wx * vx + wy * vy;
    if (c1 <= 0) return false;
    final c2 = vx * vx + vy * vy;
    if (c2 <= c1) return false;
    return true;
  }

  double _dist(Offset p, Offset q) {
    final dx = p.dx - q.dx, dy = p.dy - q.dy;
    return math.sqrt(dx * dx + dy * dy);
  }

  void _forwardCallToMapOptions(TapUpDetails details, BuildContext context) {
    final camera = MapCamera.of(context);
    final mapOptions = MapOptions.of(context);

    // Ponto local (Offset) -> LatLng
    final LatLng latLng = camera.screenOffsetToLatLng(details.localPosition);

    final tapPosition = TapPosition(details.globalPosition, details.localPosition);
    mapOptions.onTap?.call(tapPosition, latLng);
  }

  void _zoomMap(TapDownDetails details, BuildContext context) {
    final cam = MapCamera.of(context);
    final ctl = MapController.of(context);

    // Ponto local (Offset) -> LatLng
    final LatLng center = cam.screenOffsetToLatLng(details.localPosition);

    ctl.move(center, cam.zoom + 0.5);
  }

}
