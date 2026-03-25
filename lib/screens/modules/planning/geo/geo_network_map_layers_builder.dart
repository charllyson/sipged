import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';

import 'package:sipged/_blocs/modules/planning/geo/feature/geo_feature_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data.dart';
import 'package:sipged/_widgets/draw/icons/icons_change_catalog.dart';
import 'package:sipged/_widgets/draw/shapes/shape_painter.dart';

class GeoNetworkMapLayersBuilder {
  GeoNetworkMapLayersBuilder._();

  static const Color _measureColor = Color(0xFF7C3AED);

  /// Zoom de referência em que os valores configurados no painel
  /// representam praticamente 1:1 o que será mostrado no mapa.
  static const double _referenceZoom = 15.0;

  /// Limites de atenuação/expansão visual.
  static const double _minVisualScale = 0.42;
  static const double _maxVisualScale = 1.35;

  static List<fm.Polygon> buildPolygons({
    required double zoom,
    required Map<String, List<GeoFeatureData>> featuresByLayer,
    required List<String> orderedActiveLayerIds,
    required Map<String, GeoLayersData> layersById,
    required String? selectedFeatureKey,
    required Map<String, List<LatLng>> temporaryPolygonLayers,
  }) {
    final out = <fm.Polygon>[];

    for (final layerId in orderedActiveLayerIds) {
      final layerFeatures = featuresByLayer[layerId];
      if (layerFeatures == null || layerFeatures.isEmpty) continue;

      for (final feature in layerFeatures) {
        if (!feature.isPolygonFamily) continue;

        final layer = layersById[feature.layerId];
        final symbols = resolveSymbolsForFeature(
          layer: layer,
          feature: feature,
          zoom: zoom,
        ).where((e) => e.enabled).toList(growable: false);

        final isSelected = selectedFeatureKey == feature.selectionKey;

        if (symbols.isEmpty) {
          final fallbackFill = layer?.displayColor ?? Colors.blue;
          final fallbackBorderWidth = _adaptStrokeWidth(
            baseWidth: 1.2,
            zoom: zoom,
            min: 0.8,
            max: 3.2,
          );

          for (final ring in feature.polygonRings) {
            if (ring.length < 3) continue;

            out.add(
              fm.Polygon(
                points: ring,
                color: isSelected
                    ? fallbackFill.withValues(alpha: 0.45)
                    : fallbackFill.withValues(alpha: 0.22),
                borderColor: isSelected ? Colors.black : fallbackFill,
                borderStrokeWidth: isSelected
                    ? math.max(
                  _adaptStrokeWidth(
                    baseWidth: 3.0,
                    zoom: zoom,
                    min: 1.8,
                    max: 4.5,
                  ),
                  fallbackBorderWidth + 0.8,
                )
                    : fallbackBorderWidth,
                pattern: const fm.StrokePattern.solid(),
                strokeCap: StrokeCap.butt,
                strokeJoin: StrokeJoin.miter,
              ),
            );
          }
          continue;
        }

        for (final symbol in symbols.reversed) {
          final fillColor = symbol.fillColor;
          final borderColor = isSelected ? Colors.black : symbol.strokeColor;

          final baseBorderWidth = symbol.strokeWidth <= 0 ? 1.2 : symbol.strokeWidth;
          final effectiveBorderWidth = _adaptStrokeWidth(
            baseWidth: isSelected ? (baseBorderWidth + 0.8) : baseBorderWidth,
            zoom: zoom,
            min: isSelected ? 1.8 : 0.8,
            max: isSelected ? 5.0 : 4.0,
          );

          final pattern = _resolveFlutterStrokePattern(
            symbol: symbol,
            zoom: zoom,
            scaledStrokeWidth: effectiveBorderWidth,
          );

          for (final ring in feature.polygonRings) {
            if (ring.length < 3) continue;

            out.add(
              fm.Polygon(
                points: ring,
                color: isSelected
                    ? fillColor.withValues(alpha: 0.45)
                    : fillColor.withValues(alpha: 0.22),
                borderColor: borderColor,
                borderStrokeWidth: effectiveBorderWidth,
                pattern: pattern,
                strokeCap: symbol.uiStrokeCap,
                strokeJoin: symbol.uiStrokeJoin,
              ),
            );
          }
        }
      }
    }

    for (final layerId in orderedActiveLayerIds) {
      final draftPolygon = temporaryPolygonLayers[layerId];
      if (draftPolygon == null || draftPolygon.isEmpty) continue;

      final layer = layersById[layerId];
      final symbols = (layer?.effectiveSymbolLayers ?? const <LayerSimpleSymbolData>[])
          .where((e) => e.enabled)
          .toList(growable: false);

      if (draftPolygon.length >= 3) {
        if (symbols.isEmpty) {
          final color = layer?.displayColor ?? Colors.orange;

          out.add(
            fm.Polygon(
              points: draftPolygon,
              color: color.withValues(alpha: 0.22),
              borderColor: color.withValues(alpha: 0.95),
              borderStrokeWidth: _adaptStrokeWidth(
                baseWidth: 2.5,
                zoom: zoom,
                min: 1.0,
                max: 4.0,
              ),
              pattern: const fm.StrokePattern.solid(),
              strokeCap: StrokeCap.butt,
              strokeJoin: StrokeJoin.miter,
            ),
          );
        } else {
          for (final symbol in symbols.reversed) {
            final baseBorderWidth = symbol.strokeWidth <= 0 ? 2.5 : symbol.strokeWidth;
            final borderWidth = _adaptStrokeWidth(
              baseWidth: baseBorderWidth,
              zoom: zoom,
              min: 1.0,
              max: 4.5,
            );

            out.add(
              fm.Polygon(
                points: draftPolygon,
                color: symbol.fillColor.withValues(alpha: 0.22),
                borderColor: symbol.strokeColor.withValues(alpha: 0.95),
                borderStrokeWidth: borderWidth,
                pattern: _resolveFlutterStrokePattern(
                  symbol: symbol,
                  zoom: zoom,
                  scaledStrokeWidth: borderWidth,
                ),
                strokeCap: symbol.uiStrokeCap,
                strokeJoin: symbol.uiStrokeJoin,
              ),
            );
          }
        }
      }
    }

    return out;
  }

  static List<fm.Polyline> buildPolylines({
    required double zoom,
    required Map<String, List<GeoFeatureData>> featuresByLayer,
    required List<String> orderedActiveLayerIds,
    required Map<String, GeoLayersData> layersById,
    required String? selectedFeatureKey,
    required Map<String, List<LatLng>> temporaryLineLayers,
    required Map<String, List<LatLng>> temporaryPolygonLayers,
    required List<LatLng> distanceMeasurementPoints,
  }) {
    final out = <fm.Polyline>[];

    for (final layerId in orderedActiveLayerIds) {
      final layerFeatures = featuresByLayer[layerId];
      if (layerFeatures == null || layerFeatures.isEmpty) continue;

      for (final feature in layerFeatures) {
        if (!feature.isLineFamily) continue;

        final layer = layersById[feature.layerId];
        final symbols = resolveSymbolsForFeature(
          layer: layer,
          feature: feature,
          zoom: zoom,
        ).where((e) => e.enabled).toList(growable: false);

        final isSelected = selectedFeatureKey == feature.selectionKey;

        if (symbols.isEmpty) {
          final fallbackColor = layer?.displayColor ?? Colors.blue;
          final fallbackWidth = _adaptStrokeWidth(
            baseWidth: 3.0,
            zoom: zoom,
            min: 1.1,
            max: 6.0,
          );

          for (final line in feature.lineParts) {
            if (line.length < 2) continue;

            out.add(
              fm.Polyline(
                points: line,
                color: isSelected ? Colors.black : fallbackColor,
                strokeWidth: isSelected
                    ? math.max(
                  _adaptStrokeWidth(
                    baseWidth: 5.0,
                    zoom: zoom,
                    min: 2.0,
                    max: 7.0,
                  ),
                  fallbackWidth + 0.8,
                )
                    : fallbackWidth,
                pattern: const fm.StrokePattern.solid(),
                strokeCap: StrokeCap.butt,
                strokeJoin: StrokeJoin.miter,
              ),
            );
          }
          continue;
        }

        for (final symbol in symbols.reversed) {
          final baseWidth = symbol.strokeWidth <= 0 ? 3.0 : symbol.strokeWidth;
          final effectiveWidth = _adaptStrokeWidth(
            baseWidth: isSelected ? (baseWidth + 1.0) : baseWidth,
            zoom: zoom,
            min: isSelected ? 2.0 : 1.0,
            max: isSelected ? 7.5 : 6.5,
          );

          final effectiveOffsetPixels = _adaptOffsetPixels(
            baseOffsetPixels: symbol.offset,
            baseStrokeWidth: baseWidth,
            zoom: zoom,
          );

          final color = isSelected ? Colors.black : symbol.strokeColor;

          final pattern = _resolveFlutterStrokePattern(
            symbol: symbol,
            zoom: zoom,
            scaledStrokeWidth: effectiveWidth,
          );

          for (final line in feature.lineParts) {
            if (line.length < 2) continue;

            final renderedLine = effectiveOffsetPixels.abs() > 0.0001
                ? _offsetPolylineByScreenPixels(
              points: line,
              offsetPixels: effectiveOffsetPixels,
              zoom: zoom,
            )
                : line;

            out.add(
              fm.Polyline(
                points: renderedLine,
                color: color,
                strokeWidth: effectiveWidth,
                pattern: pattern,
                strokeCap: symbol.uiStrokeCap,
                strokeJoin: symbol.uiStrokeJoin,
              ),
            );
          }
        }
      }
    }

    for (final layerId in orderedActiveLayerIds) {
      final draftLine = temporaryLineLayers[layerId];
      if (draftLine != null && draftLine.length >= 2) {
        final layer = layersById[layerId];
        final symbols = (layer?.effectiveSymbolLayers ?? const <LayerSimpleSymbolData>[])
            .where((e) => e.enabled)
            .toList(growable: false);

        if (symbols.isEmpty) {
          final color = layer?.displayColor ?? Colors.orange;

          out.add(
            fm.Polyline(
              points: draftLine,
              color: color.withValues(alpha: 0.95),
              strokeWidth: _adaptStrokeWidth(
                baseWidth: 4.0,
                zoom: zoom,
                min: 1.2,
                max: 6.0,
              ),
              pattern: const fm.StrokePattern.solid(),
              strokeCap: StrokeCap.butt,
              strokeJoin: StrokeJoin.miter,
            ),
          );
        } else {
          for (final symbol in symbols.reversed) {
            final baseWidth = symbol.strokeWidth <= 0 ? 4.0 : symbol.strokeWidth;
            final width = _adaptStrokeWidth(
              baseWidth: baseWidth,
              zoom: zoom,
              min: 1.2,
              max: 6.5,
            );

            final effectiveOffsetPixels = _adaptOffsetPixels(
              baseOffsetPixels: symbol.offset,
              baseStrokeWidth: baseWidth,
              zoom: zoom,
            );

            final renderedDraftLine = effectiveOffsetPixels.abs() > 0.0001
                ? _offsetPolylineByScreenPixels(
              points: draftLine,
              offsetPixels: effectiveOffsetPixels,
              zoom: zoom,
            )
                : draftLine;

            out.add(
              fm.Polyline(
                points: renderedDraftLine,
                color: symbol.strokeColor.withValues(alpha: 0.95),
                strokeWidth: width,
                pattern: _resolveFlutterStrokePattern(
                  symbol: symbol,
                  zoom: zoom,
                  scaledStrokeWidth: width,
                ),
                strokeCap: symbol.uiStrokeCap,
                strokeJoin: symbol.uiStrokeJoin,
              ),
            );
          }
        }
      }

      final draftPolygon = temporaryPolygonLayers[layerId];
      if (draftPolygon != null && draftPolygon.length >= 2) {
        final layer = layersById[layerId];
        final symbols = (layer?.effectiveSymbolLayers ?? const <LayerSimpleSymbolData>[])
            .where((e) => e.enabled)
            .toList(growable: false);

        final previewPoints =
        draftPolygon.length >= 3 ? [...draftPolygon, draftPolygon.first] : draftPolygon;

        if (symbols.isEmpty) {
          final color = layer?.displayColor ?? Colors.orange;

          out.add(
            fm.Polyline(
              points: previewPoints,
              color: color.withValues(alpha: 0.95),
              strokeWidth: _adaptStrokeWidth(
                baseWidth: 3.0,
                zoom: zoom,
                min: 1.0,
                max: 5.0,
              ),
              pattern: const fm.StrokePattern.solid(),
              strokeCap: StrokeCap.butt,
              strokeJoin: StrokeJoin.miter,
            ),
          );
        } else {
          for (final symbol in symbols.reversed) {
            final baseWidth = symbol.strokeWidth <= 0 ? 3.0 : symbol.strokeWidth;
            final width = _adaptStrokeWidth(
              baseWidth: baseWidth,
              zoom: zoom,
              min: 1.0,
              max: 5.0,
            );

            out.add(
              fm.Polyline(
                points: previewPoints,
                color: symbol.strokeColor.withValues(alpha: 0.95),
                strokeWidth: width,
                pattern: _resolveFlutterStrokePattern(
                  symbol: symbol,
                  zoom: zoom,
                  scaledStrokeWidth: width,
                ),
                strokeCap: symbol.uiStrokeCap,
                strokeJoin: symbol.uiStrokeJoin,
              ),
            );
          }
        }
      }
    }

    if (distanceMeasurementPoints.length >= 2) {
      out.add(
        fm.Polyline(
          points: distanceMeasurementPoints,
          color: _measureColor,
          strokeWidth: _adaptStrokeWidth(
            baseWidth: 4.0,
            zoom: zoom,
            min: 2.0,
            max: 6.0,
          ),
          pattern: const fm.StrokePattern.solid(),
          strokeCap: StrokeCap.round,
          strokeJoin: StrokeJoin.round,
        ),
      );
    }

    return out;
  }

  static List<fm.Marker> buildMarkers({
    required double zoom,
    required Map<String, List<GeoFeatureData>> featuresByLayer,
    required List<String> orderedActiveLayerIds,
    required Map<String, GeoLayersData> layersById,
    required String? selectedFeatureKey,
    required Map<String, List<LatLng>> temporaryPointLayers,
    required Map<String, List<LatLng>> temporaryPolygonLayers,
    required List<LatLng> distanceMeasurementPoints,
    required void Function(GeoFeatureData feature) onFeatureTap,
  }) {
    final out = <fm.Marker>[];

    for (final layerId in orderedActiveLayerIds) {
      final layerFeatures = featuresByLayer[layerId];
      if (layerFeatures == null || layerFeatures.isEmpty) continue;

      for (final feature in layerFeatures) {
        if (!feature.isPointFamily) continue;

        final layer = layersById[feature.layerId];
        final isSelected = selectedFeatureKey == feature.selectionKey;

        final symbols = resolveSymbolsForFeature(
          layer: layer,
          feature: feature,
          zoom: zoom,
        ).where((e) => e.enabled).toList(growable: false);

        final maxWidth = symbols.isEmpty
            ? 42.0
            : symbols.map((e) => e.width).fold(0.0, math.max);
        final maxHeight = symbols.isEmpty
            ? 42.0
            : symbols.map((e) => e.height).fold(0.0, math.max);

        final markerWidth = (maxWidth + 18).clamp(42.0, 140.0);
        final markerHeight = (maxHeight + 18).clamp(42.0, 140.0);

        for (final point in feature.markerPoints) {
          out.add(
            fm.Marker(
              point: point,
              width: markerWidth,
              height: markerHeight,
              child: GestureDetector(
                onTap: () => onFeatureTap(feature),
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
                              (symbol) => buildSymbolWidget(
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
    }

    for (final layerId in orderedActiveLayerIds) {
      final points = temporaryPointLayers[layerId];
      if (points != null && points.isNotEmpty) {
        final layer = layersById[layerId];
        final symbols = (layer?.effectiveSymbolLayers ?? const <LayerSimpleSymbolData>[])
            .where((e) => e.enabled)
            .toList(growable: false);

        final maxWidth = symbols.isEmpty
            ? 42.0
            : symbols.map((e) => e.width).fold(0.0, math.max);
        final maxHeight = symbols.isEmpty
            ? 42.0
            : symbols.map((e) => e.height).fold(0.0, math.max);

        final markerWidth = (maxWidth + 18).clamp(42.0, 140.0);
        final markerHeight = (maxHeight + 18).clamp(42.0, 140.0);

        for (final point in points) {
          out.add(
            fm.Marker(
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
                              (symbol) => buildSymbolWidget(
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

      final polygonVertices = temporaryPolygonLayers[layerId];
      if (polygonVertices != null && polygonVertices.isNotEmpty) {
        final layer = layersById[layerId];
        final color = layer?.displayColor ?? Colors.orange;

        for (final point in polygonVertices) {
          out.add(
            fm.Marker(
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

    for (int i = 0; i < distanceMeasurementPoints.length; i++) {
      final point = distanceMeasurementPoints[i];

      out.add(
        fm.Marker(
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

  static List<LayerSimpleSymbolData> resolveSymbolsForFeature({
    required GeoLayersData? layer,
    required GeoFeatureData feature,
    required double zoom,
  }) {
    if (layer == null) return const [];

    if (layer.rendererType == LayerRendererType.singleSymbol) {
      return layer.effectiveSymbolLayers;
    }

    for (final rule in layer.ruleBasedSymbols) {
      if (!rule.enabled) continue;
      if (rule.minZoom != null && zoom < rule.minZoom!) continue;
      if (rule.maxZoom != null && zoom > rule.maxZoom!) continue;

      if (_matchesRule(rule, feature.properties)) {
        return rule.effectiveSymbolLayers(
          geometryKind: layer.geometryKind,
          fallbackIconKey: layer.iconKey,
          fallbackColorValue: layer.colorValue,
        );
      }
    }

    return layer.effectiveSymbolLayers;
  }

  static bool _matchesRule(
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

  static Widget buildSymbolWidget({
    required LayerSimpleSymbolData symbol,
    required bool isSelected,
  }) {
    if (symbol.family != LayerSymbolFamily.point) {
      return const SizedBox.shrink();
    }

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

  static fm.StrokePattern _resolveFlutterStrokePattern({
    required LayerSimpleSymbolData symbol,
    required double zoom,
    required double scaledStrokeWidth,
  }) {
    switch (symbol.strokePattern) {
      case LayerStrokePattern.solid:
        return const fm.StrokePattern.solid();

      case LayerStrokePattern.dashed:
        final rawSegments = symbol.effectiveDashArray.isNotEmpty
            ? symbol.effectiveDashArray
            : const <double>[12, 8];

        final segments = _adaptDashSegments(
          rawSegments: rawSegments,
          zoom: zoom,
        );

        if (segments.length >= 2) {
          return fm.StrokePattern.dashed(segments: segments);
        }

        return fm.StrokePattern.dashed(
          segments: _adaptDashSegments(
            rawSegments: const <double>[12, 8],
            zoom: zoom,
          ),
        );

      case LayerStrokePattern.dotted:
        final baseGap = symbol.useCustomDashPattern ? symbol.dashGap : 6.0;
        final effectiveGap = _adaptGap(
          baseGap: baseGap,
          zoom: zoom,
        );

        final safeWidth = scaledStrokeWidth <= 0 ? 1.0 : scaledStrokeWidth;
        final spacingFactor = (effectiveGap / safeWidth).clamp(0.35, 8.0);

        return fm.StrokePattern.dotted(
          spacingFactor: spacingFactor,
        );
    }
  }

  static List<LatLng> _offsetPolylineByScreenPixels({
    required List<LatLng> points,
    required double offsetPixels,
    required double zoom,
  }) {
    if (points.length < 2 || offsetPixels.abs() < 0.0001) {
      return points;
    }

    final out = <LatLng>[];
    final averageLatitude =
        points.map((e) => e.latitude).reduce((a, b) => a + b) / points.length;
    final metersPerPixel = _metersPerPixel(averageLatitude, zoom);
    final offsetMeters = offsetPixels * metersPerPixel;

    for (int i = 0; i < points.length; i++) {
      final current = points[i];

      LatLng? prev;
      LatLng? next;

      if (i > 0) prev = points[i - 1];
      if (i < points.length - 1) next = points[i + 1];

      if (prev == null && next == null) {
        out.add(current);
        continue;
      }

      final dir = _averageDirection(prev, current, next);
      final normal = _leftNormal(dir.dx, dir.dy);

      out.add(
        _movePointMeters(
          current,
          eastMeters: normal.dx * offsetMeters,
          northMeters: normal.dy * offsetMeters,
        ),
      );
    }

    return out;
  }

  static double _visualScaleForZoom(double zoom) {
    final delta = zoom - _referenceZoom;

    // Escala suave.
    // Zoom menor => reduz o peso visual.
    // Zoom maior => aumenta moderadamente.
    final scale = math.pow(2.0, delta * 0.18).toDouble();

    return scale.clamp(_minVisualScale, _maxVisualScale);
  }

  static double _adaptStrokeWidth({
    required double baseWidth,
    required double zoom,
    double min = 0.8,
    double max = 8.0,
  }) {
    final safeBase = baseWidth <= 0 ? 1.0 : baseWidth;
    final scaled = safeBase * _visualScaleForZoom(zoom);
    return scaled.clamp(min, max);
  }

  static double _adaptGap({
    required double baseGap,
    required double zoom,
  }) {
    final safeBase = baseGap <= 0 ? 1.0 : baseGap;
    final scale = _visualScaleForZoom(zoom);

    // Gap sofre uma pequena compressão extra em zoom menor,
    // para o tracejado não “abrir” demais ao afastar.
    final adapted = safeBase * math.pow(scale, 0.92).toDouble();
    return adapted.clamp(1.0, 64.0);
  }

  static List<double> _adaptDashSegments({
    required List<double> rawSegments,
    required double zoom,
  }) {
    final scale = _visualScaleForZoom(zoom);

    return rawSegments
        .map((value) {
      final safe = value <= 0 ? 0.5 : value;
      final adapted = safe * math.pow(scale, 0.92).toDouble();
      return adapted.clamp(0.75, 80.0);
    })
        .toList(growable: false);
  }

  static double _adaptOffsetPixels({
    required double baseOffsetPixels,
    required double baseStrokeWidth,
    required double zoom,
  }) {
    if (baseOffsetPixels.abs() < 0.0001) return 0.0;

    final scale = _visualScaleForZoom(zoom);

    // Offset deve reduzir mais agressivamente que a espessura
    // quando o usuário afasta o mapa, para não “abrir” demais
    // as linhas paralelas.
    final zoomAdjusted = baseOffsetPixels * math.pow(scale, 1.10).toDouble();

    // Clamp visual relativo à espessura base da linha.
    // Ajuda muito em linha dupla / linha com miolo branco.
    final safeStroke = baseStrokeWidth <= 0 ? 1.0 : baseStrokeWidth;
    final maxAbsOffset = math.max(2.0, safeStroke * 2.2);

    return zoomAdjusted.clamp(-maxAbsOffset, maxAbsOffset);
  }

  static double _metersPerPixel(double latitude, double zoom) {
    final latRad = latitude * math.pi / 180.0;
    return (156543.03392804097 * math.cos(latRad)) / math.pow(2.0, zoom);
  }

  static Offset _averageDirection(LatLng? prev, LatLng current, LatLng? next) {
    double dx = 0;
    double dy = 0;

    if (prev != null) {
      dx += _metersEast(prev, current);
      dy += _metersNorth(prev, current);
    }

    if (next != null) {
      dx += _metersEast(current, next);
      dy += _metersNorth(current, next);
    }

    final length = math.sqrt((dx * dx) + (dy * dy));
    if (length == 0) {
      return const Offset(1, 0);
    }

    return Offset(dx / length, dy / length);
  }

  static Offset _leftNormal(double dx, double dy) {
    final nx = -dy;
    final ny = dx;
    final length = math.sqrt((nx * nx) + (ny * ny));

    if (length == 0) return const Offset(0, 0);
    return Offset(nx / length, ny / length);
  }

  static double _metersEast(LatLng from, LatLng to) {
    final avgLatRad = ((from.latitude + to.latitude) / 2) * math.pi / 180.0;
    final metersPerDegreeLon = 111320.0 * math.cos(avgLatRad);
    return (to.longitude - from.longitude) * metersPerDegreeLon;
  }

  static double _metersNorth(LatLng from, LatLng to) {
    return (to.latitude - from.latitude) * 111320.0;
  }

  static LatLng _movePointMeters(
      LatLng point, {
        required double eastMeters,
        required double northMeters,
      }) {
    final latOffset = northMeters / 111320.0;
    final cosLat = math.cos(point.latitude * math.pi / 180.0).abs();
    final safeCosLat = cosLat < 0.00001 ? 0.00001 : cosLat;
    final lonOffset = eastMeters / (111320.0 * safeCosLat);

    return LatLng(
      point.latitude + latOffset,
      point.longitude + lonOffset,
    );
  }
}