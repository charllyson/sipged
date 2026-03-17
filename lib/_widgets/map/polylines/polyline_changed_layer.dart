library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import 'package:sipged/_widgets/map/polylines/polyline_changed_data.dart';

class _PolylineHitCache {
  final PolylineChangedData polyline;
  final List<Offset> offsets;
  final PolylineScreenBBox? screenBBox;

  const _PolylineHitCache({
    required this.polyline,
    required this.offsets,
    required this.screenBBox,
  });
}

/// Camada única responsável por:
/// - desenhar polylines
/// - filtrar por visibilidade
/// - intermediar hit-test
/// - encaminhar taps ao mapa
///
/// Toda a lógica geométrica principal fica no próprio PolylineChangedData.
class PolylineChangedLayer extends StatelessWidget {
  final List<PolylineChangedData> polylines;
  final double pointerDistanceTolerance;
  final void Function(List<PolylineChangedData> hits, TapUpDetails tap)? onTap;
  final void Function(TapUpDetails tap)? onMiss;
  final bool culling;

  const PolylineChangedLayer({
    super.key,
    this.polylines = const <PolylineChangedData>[],
    this.onTap,
    this.onMiss,
    this.pointerDistanceTolerance = 12,
    this.culling = true,
  });

  @override
  Widget build(BuildContext context) {
    if (polylines.isEmpty) {
      return const SizedBox.shrink();
    }

    final camera = MapCamera.of(context);

    final visible = culling
        ? polylines
        .where((p) => p.isVisibleInMapBounds(camera.visibleBounds))
        .toList(growable: false)
        : polylines;

    if (visible.isEmpty) {
      return const SizedBox.shrink();
    }

    final tappable =
    visible.where((p) => p.hitTestable).toList(growable: false);
    final nonTappable =
    visible.where((p) => !p.hitTestable).toList(growable: false);

    final children = <Widget>[
      RepaintBoundary(
        child: PolylineLayer(
          polylines: nonTappable
              .map((p) => p.buildFlutterPolyline())
              .toList(growable: false),
        ),
      ),
    ];

    if (tappable.isNotEmpty) {
      children.add(_buildInteractiveLayer(context, tappable));
    }

    if (children.length == 1) {
      return children.first;
    }

    return Stack(children: children);
  }

  Widget _buildInteractiveLayer(
      BuildContext context,
      List<PolylineChangedData> tappable,
      ) {
    final camera = MapCamera.of(context);
    final hitCache = _rebuildHitCacheForFrame(camera, tappable);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onDoubleTap: () {},
      onDoubleTapDown: (details) => _zoomMap(details, context),
      onTapUp: (details) {
        _forwardCallToMapOptions(details, context);
        _handlePolylineTap(details, hitCache);
      },
      child: RepaintBoundary(
        child: PolylineLayer(
          polylines: tappable
              .map((p) => p.buildFlutterPolyline())
              .toList(growable: false),
        ),
      ),
    );
  }

  List<_PolylineHitCache> _rebuildHitCacheForFrame(
      MapCamera camera,
      List<PolylineChangedData> lines,
      ) {
    return lines.map((poly) {
      final offsets = poly.projectToScreen(camera);
      final bbox = poly.buildScreenBBox(camera);

      return _PolylineHitCache(
        polyline: poly,
        offsets: offsets,
        screenBBox: bbox,
      );
    }).toList(growable: false);
  }

  void _handlePolylineTap(
      TapUpDetails details,
      List<_PolylineHitCache> visibleLines,
      ) {
    final tap = details.localPosition;

    final Map<double, Map<Object, PolylineChangedData>> candidates = {};

    for (final current in visibleLines) {
      final dist = current.polyline.hitDistance(
        tapPosition: tap,
        projectedOffsets: current.offsets,
        tolerance: pointerDistanceTolerance,
        screenBBox: current.screenBBox,
      );

      if (dist == null) continue;

      final key = current.polyline.tag ?? current.polyline;

      candidates.putIfAbsent(dist, () => <Object, PolylineChangedData>{});
      candidates[dist]![key] = current.polyline;
    }

    if (candidates.isEmpty) {
      onMiss?.call(details);
      return;
    }

    final closest = candidates.keys.reduce(math.min);
    onTap?.call(
      candidates[closest]!.values.toList(growable: false),
      details,
    );
  }

  void _forwardCallToMapOptions(TapUpDetails details, BuildContext context) {
    final camera = MapCamera.of(context);
    final mapOptions = MapOptions.of(context);

    final latLng = camera.screenOffsetToLatLng(details.localPosition);
    final tapPosition = TapPosition(
      details.globalPosition,
      details.localPosition,
    );

    mapOptions.onTap?.call(tapPosition, latLng);
  }

  void _zoomMap(TapDownDetails details, BuildContext context) {
    final camera = MapCamera.of(context);
    final controller = MapController.of(context);

    final center = camera.screenOffsetToLatLng(details.localPosition);
    controller.move(center, camera.zoom + 0.5);
  }
}