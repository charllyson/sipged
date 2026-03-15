import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:sipged/_blocs/modules/planning/geo/feature/geo_feature_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data.dart';
import 'package:sipged/_widgets/geo/properties/menu/symbology/catalogs/marker_icons_catalog.dart';
import 'package:sipged/_widgets/geo/properties/menu/symbology/geometry/shape_painter.dart';

class GeoNetworkMap extends StatefulWidget {
  const GeoNetworkMap({
    super.key,
    required this.features,
    required this.layersById,
    required this.orderedActiveLayerIds,
    required this.onFeatureTap,
    required this.onControllerReady,
    this.onCameraChanged,
    this.selectedFeatureKey,
    this.loading = false,
    this.onBackgroundTap,
    this.temporaryPointLayers = const {},
    this.temporaryLineLayers = const {},
    this.temporaryPolygonLayers = const {},
    this.distanceMeasurementPoints = const [],
    this.cursor = SystemMouseCursors.basic,
  });

  final List<GeoFeatureData> features;
  final Map<String, GeoLayersData> layersById;
  final List<String> orderedActiveLayerIds;
  final void Function(GeoFeatureData? feature) onFeatureTap;
  final void Function(MapController controller) onControllerReady;
  final void Function(LatLng center, double zoom)? onCameraChanged;
  final String? selectedFeatureKey;
  final bool loading;

  final bool Function(LatLng latLng)? onBackgroundTap;
  final Map<String, List<LatLng>> temporaryPointLayers;
  final Map<String, List<LatLng>> temporaryLineLayers;
  final Map<String, List<LatLng>> temporaryPolygonLayers;
  final List<LatLng> distanceMeasurementPoints;
  final MouseCursor cursor;

  @override
  State<GeoNetworkMap> createState() => _GeoNetworkMapState();
}

class _GeoNetworkMapState extends State<GeoNetworkMap> {
  late final MapController _controller;

  static const String _tileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  static const Distance _distance = Distance();
  static const Color _measureColor = Color(0xFF7C3AED);

  bool _mapReady = false;
  double _lastKnownZoom = 7.0;
  LatLng _lastKnownCenter = const LatLng(-9.6658, -35.7353);

  int _lastStaticVisualSignature = 0;
  int _lastMarkerVisualSignature = 0;
  double _lastMarkerZoomBucket = -999;

  List<Polygon> _cachedPolygons = const [];
  List<Polyline> _cachedPolylines = const [];
  List<Marker> _cachedMarkers = const [];
  List<GeoFeatureData> _cachedOrderedFeaturesForHit = const [];

  @override
  void initState() {
    super.initState();
    _controller = MapController();
  }

  @override
  void didUpdateWidget(covariant GeoNetworkMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    final nextBucket = _zoomBucket(_effectiveZoom);
    if (nextBucket != _lastMarkerZoomBucket && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(_ensureMarkerCache);
      });
    }
  }

  void _handleMapReady() {
    if (!mounted) return;

    _mapReady = true;
    widget.onControllerReady(_controller);
  }

  double get _effectiveZoom {
    if (_mapReady) {
      try {
        return _controller.camera.zoom;
      } catch (_) {
        return _lastKnownZoom;
      }
    }
    return _lastKnownZoom;
  }

  LatLng get _effectiveCenter {
    if (_mapReady) {
      try {
        return _controller.camera.center;
      } catch (_) {
        return _lastKnownCenter;
      }
    }
    return _lastKnownCenter;
  }

  double _zoomBucket(double zoom) {
    return (zoom * 10).round() / 10.0;
  }

  int _pointsSignature(List<LatLng> points) {
    return Object.hashAll(
      points.map((e) => Object.hash(e.latitude, e.longitude)),
    );
  }

  int _computeStaticVisualSignature() {
    return Object.hashAll([
      widget.selectedFeatureKey,
      widget.features.length,
      ...widget.features.map((f) => Object.hash(
        f.selectionKey,
        f.layerId,
        f.markerPoints.length,
        f.lineParts.length,
        f.polygonRings.length,
      )),
      widget.layersById.length,
      ...widget.layersById.entries.map(
            (e) => Object.hash(e.key, e.value.hashCode),
      ),
      ...widget.orderedActiveLayerIds,
      ...widget.temporaryLineLayers.entries.map(
            (e) => Object.hash(e.key, _pointsSignature(e.value)),
      ),
      ...widget.temporaryPolygonLayers.entries.map(
            (e) => Object.hash(e.key, _pointsSignature(e.value)),
      ),
      _pointsSignature(widget.distanceMeasurementPoints),
    ]);
  }

  int _computeMarkerVisualSignature(double zoomBucket) {
    return Object.hashAll([
      zoomBucket,
      widget.selectedFeatureKey,
      widget.features.length,
      ...widget.features.map((f) => Object.hash(
        f.selectionKey,
        f.layerId,
        f.markerPoints.length,
      )),
      widget.layersById.length,
      ...widget.layersById.entries.map(
            (e) => Object.hash(e.key, e.value.hashCode),
      ),
      ...widget.temporaryPointLayers.entries.map(
            (e) => Object.hash(e.key, _pointsSignature(e.value)),
      ),
      ...widget.temporaryPolygonLayers.entries.map(
            (e) => Object.hash(e.key, _pointsSignature(e.value)),
      ),
      _pointsSignature(widget.distanceMeasurementPoints),
    ]);
  }

  void _ensureStaticCache() {
    final signature = _computeStaticVisualSignature();
    if (signature == _lastStaticVisualSignature) return;

    _lastStaticVisualSignature = signature;
    _cachedPolygons = _buildPolygons();
    _cachedPolylines = _buildPolylines();
    _cachedOrderedFeaturesForHit = _buildOrderedFeaturesForHit();
  }

  void _ensureMarkerCache() {
    final bucket = _zoomBucket(_effectiveZoom);
    final signature = _computeMarkerVisualSignature(bucket);

    if (signature == _lastMarkerVisualSignature &&
        bucket == _lastMarkerZoomBucket) {
      return;
    }

    _lastMarkerZoomBucket = bucket;
    _lastMarkerVisualSignature = signature;
    _cachedMarkers = _buildMarkers(bucket);
  }

  List<GeoFeatureData> _buildOrderedFeaturesForHit() {
    final orderedLayerIds = widget.orderedActiveLayerIds.reversed.toList();
    final orderedFeatures = <GeoFeatureData>[];

    for (final layerId in orderedLayerIds) {
      orderedFeatures.addAll(
        widget.features.where((e) => e.layerId == layerId),
      );
    }

    return orderedFeatures;
  }

  @override
  Widget build(BuildContext context) {
    _ensureStaticCache();
    _ensureMarkerCache();

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        RepaintBoundary(
          child: MouseRegion(
            cursor: widget.cursor,
            child: FlutterMap(
              mapController: _controller,
              options: MapOptions(
                initialCenter: _lastKnownCenter,
                initialZoom: _lastKnownZoom,
                onMapReady: _handleMapReady,
                onTap: (_, latLng) {
                  final consumed = widget.onBackgroundTap?.call(latLng) ?? false;
                  if (consumed) return;

                  final hit = _findFeatureAt(latLng, _effectiveZoom);

                  if (hit != null) {
                    widget.onFeatureTap(hit);
                    return;
                  }

                  widget.onFeatureTap(null);
                },
                onPositionChanged: (camera, hasGesture) {
                  _lastKnownCenter = camera.center;
                  _lastKnownZoom = camera.zoom;
                  widget.onCameraChanged?.call(camera.center, camera.zoom);

                  final nextBucket = _zoomBucket(camera.zoom);
                  if (nextBucket != _lastMarkerZoomBucket && mounted) {
                    setState(() {
                      _ensureMarkerCache();
                    });
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: _tileUrl,
                  userAgentPackageName: 'com.openai.sipged',
                  panBuffer: 1,
                ),
                if (_cachedPolygons.isNotEmpty)
                  PolygonLayer(polygons: _cachedPolygons),
                if (_cachedPolylines.isNotEmpty)
                  PolylineLayer(polylines: _cachedPolylines),
                if (_cachedMarkers.isNotEmpty)
                  MarkerLayer(markers: _cachedMarkers),
              ],
            ),
          ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: SafeArea(
            minimum: EdgeInsets.zero,
            child: RepaintBoundary(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton.small(
                    heroTag: 'geo_zoom_in',
                    onPressed: !_mapReady
                        ? null
                        : () {
                      final center = _effectiveCenter;
                      final zoom = _effectiveZoom;
                      _controller.move(center, zoom + 1);
                    },
                    child: const Icon(Icons.add),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: 'geo_zoom_out',
                    onPressed: !_mapReady
                        ? null
                        : () {
                      final center = _effectiveCenter;
                      final zoom = _effectiveZoom;
                      _controller.move(center, zoom - 1);
                    },
                    child: const Icon(Icons.remove),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<LayerSimpleSymbolData> _resolveSymbolsForFeature(
      GeoLayersData? layer,
      GeoFeatureData feature,
      double zoom,
      ) {
    if (layer == null) return const [];

    if (layer.rendererType == LayerRendererType.singleSymbol) {
      return layer.effectiveSymbolLayers;
    }

    for (final rule in layer.ruleBasedSymbols) {
      if (!rule.enabled) continue;
      if (rule.minZoom != null && zoom < rule.minZoom!) continue;
      if (rule.maxZoom != null && zoom > rule.maxZoom!) continue;

      if (_matchesRule(rule, feature.properties)) {
        return rule.effectiveSymbolLayers;
      }
    }

    return layer.effectiveSymbolLayers;
  }

  bool _matchesRule(
      LayerRuleData rule,
      Map<String, dynamic> properties,
      ) {
    final field = rule.field.trim();
    if (field.isEmpty) return true;

    final raw = properties[field];
    final left = raw?.toString() ?? '';
    final right = rule.value;

    switch (rule.operatorType) {
      case LayerRuleOperator.equals:
        return left == right;
      case LayerRuleOperator.notEquals:
        return left != right;
      case LayerRuleOperator.contains:
        return left.toLowerCase().contains(right.toLowerCase());
      case LayerRuleOperator.greaterThan:
        return (double.tryParse(left.replaceAll(',', '.')) ?? double.nan) >
            (double.tryParse(right.replaceAll(',', '.')) ?? double.nan);
      case LayerRuleOperator.lessThan:
        return (double.tryParse(left.replaceAll(',', '.')) ?? double.nan) <
            (double.tryParse(right.replaceAll(',', '.')) ?? double.nan);
      case LayerRuleOperator.greaterOrEqual:
        return (double.tryParse(left.replaceAll(',', '.')) ?? double.nan) >=
            (double.tryParse(right.replaceAll(',', '.')) ?? double.nan);
      case LayerRuleOperator.lessOrEqual:
        return (double.tryParse(left.replaceAll(',', '.')) ?? double.nan) <=
            (double.tryParse(right.replaceAll(',', '.')) ?? double.nan);
      case LayerRuleOperator.isEmpty:
        return left.trim().isEmpty;
      case LayerRuleOperator.isNotEmpty:
        return left.trim().isNotEmpty;
    }
  }

  List<Polygon> _buildPolygons() {
    final out = <Polygon>[];

    for (final feature in widget.features) {
      final layer = widget.layersById[feature.layerId];
      final base = layer?.displayColor ?? Colors.blue;
      final isSelected = widget.selectedFeatureKey == feature.selectionKey;

      for (final ring in feature.polygonRings) {
        if (ring.length < 3) continue;

        out.add(
          Polygon(
            points: ring,
            color: isSelected
                ? base.withValues(alpha: 0.45)
                : base.withValues(alpha: 0.22),
            borderColor: isSelected ? Colors.black : base,
            borderStrokeWidth: isSelected ? 3.0 : 1.2,
          ),
        );
      }
    }

    for (final layerId in widget.orderedActiveLayerIds) {
      final draftPolygon = widget.temporaryPolygonLayers[layerId];
      if (draftPolygon == null || draftPolygon.isEmpty) continue;

      final layer = widget.layersById[layerId];
      final color = layer?.displayColor ?? Colors.orange;

      if (draftPolygon.length >= 3) {
        out.add(
          Polygon(
            points: draftPolygon,
            color: color.withValues(alpha: 0.22),
            borderColor: color.withValues(alpha: 0.95),
            borderStrokeWidth: 2.5,
          ),
        );
      }
    }

    return out;
  }

  List<Polyline> _buildPolylines() {
    final out = <Polyline>[];

    for (final feature in widget.features) {
      final layer = widget.layersById[feature.layerId];
      final base = layer?.displayColor ?? Colors.blue;
      final isSelected = widget.selectedFeatureKey == feature.selectionKey;

      for (final line in feature.lineParts) {
        if (line.length < 2) continue;

        out.add(
          Polyline(
            points: line,
            color: isSelected ? Colors.black : base,
            strokeWidth: isSelected ? 5.0 : 3.0,
          ),
        );
      }
    }

    for (final layerId in widget.orderedActiveLayerIds) {
      final draftLine = widget.temporaryLineLayers[layerId];
      if (draftLine != null && draftLine.length >= 2) {
        final layer = widget.layersById[layerId];
        final color = layer?.displayColor ?? Colors.orange;

        out.add(
          Polyline(
            points: draftLine,
            color: color.withValues(alpha: 0.95),
            strokeWidth: 4.0,
          ),
        );
      }

      final draftPolygon = widget.temporaryPolygonLayers[layerId];
      if (draftPolygon != null && draftPolygon.length >= 2) {
        final layer = widget.layersById[layerId];
        final color = layer?.displayColor ?? Colors.orange;

        final previewPoints = draftPolygon.length >= 3
            ? [...draftPolygon, draftPolygon.first]
            : draftPolygon;

        out.add(
          Polyline(
            points: previewPoints,
            color: color.withValues(alpha: 0.95),
            strokeWidth: 3.0,
          ),
        );
      }
    }

    if (widget.distanceMeasurementPoints.length >= 2) {
      out.add(
        Polyline(
          points: widget.distanceMeasurementPoints,
          color: _measureColor,
          strokeWidth: 4.0,
        ),
      );
    }

    return out;
  }

  List<Marker> _buildMarkers(double zoom) {
    final out = <Marker>[];

    for (final feature in widget.features) {
      final layer = widget.layersById[feature.layerId];
      final isSelected = widget.selectedFeatureKey == feature.selectionKey;

      final symbols = _resolveSymbolsForFeature(layer, feature, zoom)
          .where((e) => e.enabled)
          .toList(growable: false);

      final maxWidth =
      symbols.isEmpty ? 42.0 : symbols.map((e) => e.width).fold(0.0, math.max);
      final maxHeight = symbols.isEmpty
          ? 42.0
          : symbols.map((e) => e.height).fold(0.0, math.max);

      final markerWidth = (maxWidth + 18).clamp(42.0, 140.0);
      final markerHeight = (maxHeight + 18).clamp(42.0, 140.0);

      for (final point in feature.markerPoints) {
        out.add(
          Marker(
            point: point,
            width: markerWidth,
            height: markerHeight,
            child: GestureDetector(
              onTap: () => widget.onFeatureTap(feature),
              child: Center(
                child: SizedBox(
                  width: markerWidth,
                  height: markerHeight,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (isSelected)
                        Container(
                          width: markerWidth * 0.60,
                          height: markerHeight * 0.60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.10),
                          ),
                        ),
                      ...symbols.reversed.map(
                            (symbol) => _buildSymbolWidget(
                          symbol: symbol,
                          isSelected: isSelected,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }

    for (final layerId in widget.orderedActiveLayerIds) {
      final points = widget.temporaryPointLayers[layerId];
      if (points != null && points.isNotEmpty) {
        final layer = widget.layersById[layerId];
        final symbols = (layer?.effectiveSymbolLayers ??
            const <LayerSimpleSymbolData>[])
            .where((e) => e.enabled)
            .toList(growable: false);

        final maxWidth =
        symbols.isEmpty ? 42.0 : symbols.map((e) => e.width).fold(0.0, math.max);
        final maxHeight = symbols.isEmpty
            ? 42.0
            : symbols.map((e) => e.height).fold(0.0, math.max);

        final markerWidth = (maxWidth + 18).clamp(42.0, 140.0);
        final markerHeight = (maxHeight + 18).clamp(42.0, 140.0);

        for (final point in points) {
          out.add(
            Marker(
              point: point,
              width: markerWidth,
              height: markerHeight,
              child: IgnorePointer(
                child: Center(
                  child: SizedBox(
                    width: markerWidth,
                    height: markerHeight,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: markerWidth * 0.62,
                          height: markerHeight * 0.62,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.orange.withValues(alpha: 0.14),
                          ),
                        ),
                        ...symbols.reversed.map(
                              (symbol) => _buildSymbolWidget(
                            symbol: symbol,
                            isSelected: false,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }
      }

      final polygonVertices = widget.temporaryPolygonLayers[layerId];
      if (polygonVertices != null && polygonVertices.isNotEmpty) {
        final layer = widget.layersById[layerId];
        final color = layer?.displayColor ?? Colors.orange;

        for (final point in polygonVertices) {
          out.add(
            Marker(
              point: point,
              width: 20,
              height: 20,
              child: IgnorePointer(
                child: Center(
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ),
            ),
          );
        }
      }
    }

    for (int i = 0; i < widget.distanceMeasurementPoints.length; i++) {
      final point = widget.distanceMeasurementPoints[i];

      out.add(
        Marker(
          point: point,
          width: 28,
          height: 28,
          child: IgnorePointer(
            child: Center(
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: _measureColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  '${i + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return out;
  }

  Widget _buildSymbolWidget({
    required LayerSimpleSymbolData symbol,
    required bool isSelected,
  }) {
    if (symbol.type == LayerSimpleSymbolType.svgMarker) {
      final iconData = IconsCatalog.iconFor(symbol.iconKey);

      return Transform.rotate(
        angle: symbol.rotationDegrees * math.pi / 180,
        child: Icon(
          iconData,
          size: math.max(symbol.width, symbol.height),
          color: isSelected ? Colors.black : symbol.fillColor,
        ),
      );
    }

    return Transform.rotate(
      angle: symbol.rotationDegrees * math.pi / 180,
      child: SizedBox(
        width: symbol.width,
        height: symbol.height,
        child: CustomPaint(
          painter: ShapePainter(
            shape: symbol.shapeType,
            fillColor: isSelected
                ? symbol.fillColor.withValues(alpha: 0.75)
                : symbol.fillColor,
            strokeColor: isSelected ? Colors.black : symbol.strokeColor,
            strokeWidth: symbol.strokeWidth,
            rotationDegrees: 0,
          ),
        ),
      ),
    );
  }

  GeoFeatureData? _findFeatureAt(LatLng tap, double zoom) {
    final orderedFeatures = _cachedOrderedFeaturesForHit;

    for (final feature in orderedFeatures) {
      if (_hitMarker(feature, tap, zoom)) return feature;
      if (_hitLine(feature, tap, zoom)) return feature;
      if (_hitPolygon(feature, tap)) return feature;
    }

    return null;
  }

  bool _hitMarker(GeoFeatureData feature, LatLng tap, double zoom) {
    final toleranceMeters = zoom >= 14 ? 20.0 : zoom >= 10 ? 60.0 : 120.0;

    for (final p in feature.markerPoints) {
      if (_distance.as(LengthUnit.Meter, tap, p) <= toleranceMeters) {
        return true;
      }
    }
    return false;
  }

  bool _hitLine(GeoFeatureData feature, LatLng tap, double zoom) {
    final toleranceMeters = zoom >= 14 ? 25.0 : zoom >= 10 ? 80.0 : 200.0;

    for (final line in feature.lineParts) {
      for (int i = 0; i < line.length - 1; i++) {
        final a = line[i];
        final b = line[i + 1];

        final da = _distance.as(LengthUnit.Meter, tap, a);
        final db = _distance.as(LengthUnit.Meter, tap, b);
        final seg = _distance.as(LengthUnit.Meter, a, b);

        if (seg <= 0) continue;

        if ((da + db - seg).abs() <= toleranceMeters) {
          return true;
        }
      }
    }

    return false;
  }

  bool _hitPolygon(GeoFeatureData feature, LatLng tap) {
    for (final ring in feature.polygonRings) {
      if (_pointInPolygon(tap, ring)) return true;
    }
    return false;
  }

  bool _pointInPolygon(LatLng point, List<LatLng> polygon) {
    if (polygon.length < 3) return false;

    bool inside = false;
    int j = polygon.length - 1;

    for (int i = 0; i < polygon.length; i++) {
      final xi = polygon[i].longitude;
      final yi = polygon[i].latitude;
      final xj = polygon[j].longitude;
      final yj = polygon[j].latitude;

      final intersect = ((yi > point.latitude) != (yj > point.latitude)) &&
          (point.longitude <
              (xj - xi) * (point.latitude - yi) /
                  ((yj - yi) == 0 ? 0.0000001 : (yj - yi)) +
                  xi);

      if (intersect) inside = !inside;
      j = i;
    }

    return inside;
  }
}