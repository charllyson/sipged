import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:sipged/_blocs/modules/planning/geo/generic/geo_feature_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data.dart';
import 'package:sipged/_widgets/geo/layer/editor/symbology/icons_catalog.dart';
import 'package:sipged/_widgets/geo/layer/simple_shape_painter.dart';

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
  });

  final List<GeoFeatureData> features;
  final Map<String, GeoLayersData> layersById;
  final List<String> orderedActiveLayerIds;
  final void Function(GeoFeatureData? feature) onFeatureTap;
  final void Function(MapController controller) onControllerReady;
  final void Function(LatLng center, double zoom)? onCameraChanged;
  final String? selectedFeatureKey;
  final bool loading;

  @override
  State<GeoNetworkMap> createState() => _GeoNetworkMapState();
}

class _GeoNetworkMapState extends State<GeoNetworkMap> {
  late final MapController _controller;

  static const String _tileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  static const Distance _distance = Distance();

  @override
  void initState() {
    super.initState();
    _controller = MapController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onControllerReady(_controller);
      _fitToFeaturesIfNeeded();
    });
  }

  @override
  void didUpdateWidget(covariant GeoNetworkMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldKeys =
    oldWidget.features.map((e) => e.selectionKey).toList(growable: false);
    final newKeys =
    widget.features.map((e) => e.selectionKey).toList(growable: false);

    final styleHashOld = _styleHash(oldWidget.layersById);
    final styleHashNew = _styleHash(widget.layersById);

    if (!listEquals(oldKeys, newKeys) || styleHashOld != styleHashNew) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _fitToFeaturesIfNeeded();
      });
    }
  }

  String _styleHash(Map<String, GeoLayersData> map) {
    return map.entries.map((e) {
      final l = e.value;
      return '${e.key}_${l.iconKey}_${l.colorValue}_${l.symbolLayers.length}';
    }).join('|');
  }

  void _fitToFeaturesIfNeeded() {
    if (widget.features.isEmpty) return;

    final allPoints = <LatLng>[];
    for (final f in widget.features) {
      allPoints.addAll(f.markerPoints);
      for (final line in f.lineParts) {
        allPoints.addAll(line);
      }
      for (final ring in f.polygonRings) {
        allPoints.addAll(ring);
      }
    }

    if (allPoints.isEmpty) return;

    if (allPoints.length == 1) {
      _controller.move(allPoints.first, 14);
      return;
    }

    double minLat = allPoints.first.latitude;
    double maxLat = allPoints.first.latitude;
    double minLng = allPoints.first.longitude;
    double maxLng = allPoints.first.longitude;

    for (final p in allPoints) {
      minLat = math.min(minLat, p.latitude);
      maxLat = math.max(maxLat, p.latitude);
      minLng = math.min(minLng, p.longitude);
      maxLng = math.max(maxLng, p.longitude);
    }

    _controller.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(
          LatLng(minLat, minLng),
          LatLng(maxLat, maxLng),
        ),
        padding: const EdgeInsets.all(32),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final polygons = _buildPolygons();
    final polylines = _buildPolylines();
    final markers = _buildMarkers();

    return Stack(
      children: [
        FlutterMap(
          mapController: _controller,
          options: MapOptions(
            initialCenter: const LatLng(-9.6658, -35.7353),
            initialZoom: 7.0,
            onTap: (_, latLng) {
              final hit = _findFeatureAt(latLng, _controller.camera.zoom);
              widget.onFeatureTap(hit);
            },
            onPositionChanged: (camera, hasGesture) {
              widget.onCameraChanged?.call(camera.center, camera.zoom);
            },
          ),
          children: [
            TileLayer(
              urlTemplate: _tileUrl,
              userAgentPackageName: 'com.openai.sipged',
            ),
            if (polygons.isNotEmpty) PolygonLayer(polygons: polygons),
            if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
            if (markers.isNotEmpty) MarkerLayer(markers: markers),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: Column(
            children: [
              FloatingActionButton.small(
                heroTag: 'geo_zoom_in',
                onPressed: () {
                  _controller.move(
                    _controller.camera.center,
                    _controller.camera.zoom + 1,
                  );
                },
                child: const Icon(Icons.add),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'geo_zoom_out',
                onPressed: () {
                  _controller.move(
                    _controller.camera.center,
                    _controller.camera.zoom - 1,
                  );
                },
                child: const Icon(Icons.remove),
              ),
            ],
          ),
        ),
        if (widget.loading)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: true,
              child: Container(
                color: Colors.black12,
                alignment: Alignment.topCenter,
                padding: const EdgeInsets.only(top: 20),
                child: const Card(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Carregando camadas...'),
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

    return out;
  }

  List<Marker> _buildMarkers() {
    final out = <Marker>[];

    for (final feature in widget.features) {
      final layer = widget.layersById[feature.layerId];
      final isSelected = widget.selectedFeatureKey == feature.selectionKey;
      final symbols =
      (layer?.effectiveSymbolLayers ?? const <LayerSimpleSymbolData>[])
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
          painter: SimpleShapePainter(
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
    final orderedLayerIds = widget.orderedActiveLayerIds.reversed.toList();

    final orderedFeatures = <GeoFeatureData>[];
    for (final layerId in orderedLayerIds) {
      orderedFeatures.addAll(
        widget.features.where((e) => e.layerId == layerId),
      );
    }

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