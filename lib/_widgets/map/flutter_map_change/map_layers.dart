import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';

import 'package:sipged/_blocs/modules/planning/geo/feature/feature_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data_labels.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data_rule.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data_simple.dart';
import 'package:sipged/_widgets/draw/icons/icons_change_catalog.dart';
import 'package:sipged/_widgets/draw/shapes/shape_painter.dart';

class MapLayers {
  MapLayers._();

  static const Color _measureColor = Color(0xFF7C3AED);
  static const double _referenceZoom = 15.0;
  static const double _minVisualScale = 0.42;
  static const double _maxVisualScale = 1.35;

  static final Expando<Map<String, dynamic>> _featurePropertiesCache =
  Expando<Map<String, dynamic>>('feature_properties_cache');

  static final Expando<_AnchorCacheEntry> _featureAnchorCache =
  Expando<_AnchorCacheEntry>('feature_anchor_cache');

  static List<fm.Marker> buildLabelMarkers({
    required double zoom,
    required Map<String, List<FeatureData>> featuresByLayer,
    required List<String> orderedActiveLayerIds,
    required Map<String, LayerData> layersById,
    required String? selectedFeatureKey,
  }) {
    if (orderedActiveLayerIds.isEmpty || featuresByLayer.isEmpty) {
      return const <fm.Marker>[];
    }

    final out = <fm.Marker>[];

    final int maxLabels;
    if (zoom < 8.5) {
      maxLabels = 80;
    } else if (zoom < 10.0) {
      maxLabels = 160;
    } else if (zoom < 11.5) {
      maxLabels = 280;
    } else if (zoom < 13.0) {
      maxLabels = 450;
    } else {
      maxLabels = 800;
    }

    for (final layerId in orderedActiveLayerIds) {
      final layer = layersById[layerId];
      if (layer == null) continue;

      final features = featuresByLayer[layerId];
      if (features == null || features.isEmpty) continue;

      for (final feature in features) {
        if (out.length >= maxLabels) break;

        if (feature.isPolygonFamily && zoom < 9.0) continue;
        if (feature.isLineFamily && zoom < 8.5) continue;

        final anchor = _labelAnchorForFeature(feature);
        if (anchor == null) continue;

        final labels = resolveLabelsForFeature(
          layer: layer,
          feature: feature,
          zoom: zoom,
        ).where((e) => e.enabled).toList(growable: false);

        if (labels.isEmpty) continue;

        final properties = _featureProperties(feature);
        final isSelected = selectedFeatureKey == feature.selectionKey;

        for (final label in labels) {
          if (out.length >= maxLabels) break;

          if (label.type == LayerSimpleSymbolType.textLayer) {
            final text = _resolveLabelText(label, properties).trim();
            if (text.isEmpty) continue;
          }

          final markerSize = _labelMarkerSize(label);

          out.add(
            fm.Marker(
              point: anchor,
              width: markerSize.width,
              height: markerSize.height,
              child: IgnorePointer(
                child: Center(
                  child: Transform.translate(
                    offset: Offset(
                      label.offsetX,
                      label.offsetY - label.geometryOffset,
                    ),
                    child: _buildLabelWidget(
                      label: label,
                      properties: properties,
                      isSelected: isSelected,
                      zoom: zoom,
                    ),
                  ),
                ),
              ),
            ),
          );
        }
      }

      if (out.length >= maxLabels) break;
    }

    return out;
  }

  static List<LayerDataLabel> resolveLabelsForFeature({
    required LayerData? layer,
    required FeatureData feature,
    required double zoom,
  }) {
    if (layer == null) return const [];

    if (layer.labelRendererType == LabelRendererType.singleLabel) {
      return layer.effectiveLabelLayers;
    }

    final properties = _featureProperties(feature);

    for (final rule in layer.ruleBasedLabels) {
      if (!rule.enabled) continue;
      if (rule.minZoom != null && zoom < rule.minZoom!) continue;
      if (rule.maxZoom != null && zoom > rule.maxZoom!) continue;

      final matched = _matchesLabelRule(rule, properties);
      if (matched) {
        return [rule.style];
      }
    }

    return layer.effectiveLabelLayers;
  }

  static bool _matchesLabelRule(
      GeoLabelRuleData rule,
      Map<String, dynamic> properties,
      ) {
    final field = rule.field.trim();
    if (field.isEmpty) return true;

    final raw = _readPropertyValue(properties, field);
    final left = _normalizeText(raw);
    final right = _normalizeText(rule.value);

    switch (rule.operatorType) {
      case LayerRuleOperator.equals:
        return left == right;
      case LayerRuleOperator.notEquals:
        return left != right;
      case LayerRuleOperator.contains:
        return right.isEmpty ? left.isEmpty : left.contains(right);
      case LayerRuleOperator.greaterThan:
        return _toDouble(raw) > _toDouble(rule.value);
      case LayerRuleOperator.lessThan:
        return _toDouble(raw) < _toDouble(rule.value);
      case LayerRuleOperator.greaterOrEqual:
        return _toDouble(raw) >= _toDouble(rule.value);
      case LayerRuleOperator.lessOrEqual:
        return _toDouble(raw) <= _toDouble(rule.value);
      case LayerRuleOperator.isEmpty:
        return left.isEmpty;
      case LayerRuleOperator.isNotEmpty:
        return left.isNotEmpty;
    }
  }

  static Widget _buildLabelWidget({
    required LayerDataLabel label,
    required Map<String, dynamic> properties,
    required bool isSelected,
    required double zoom,
  }) {
    switch (label.type) {
      case LayerSimpleSymbolType.textLayer:
        final text = _resolveLabelText(label, properties);
        if (text.trim().isEmpty) {
          return const SizedBox.shrink();
        }

        final fontSize = _adaptTextSize(
          baseSize: label.fontSize,
          zoom: zoom,
          min: 8,
          max: 28,
        );

        return Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: label.fontWeight,
            color: isSelected ? Colors.black : label.color,
            height: 1.0,
          ),
        );

      case LayerSimpleSymbolType.svgMarker:
        return Transform.rotate(
          angle: label.rotationDegrees * math.pi / 180,
          child: Icon(
            IconsCatalog.iconFor(label.iconKey),
            size: math.max(label.width, label.height),
            color: isSelected ? Colors.black : label.fillColor,
          ),
        );

      case LayerSimpleSymbolType.simpleMarker:
        return Transform.rotate(
          angle: label.rotationDegrees * math.pi / 180,
          child: SizedBox(
            width: label.width,
            height: label.height,
            child: CustomPaint(
              painter: ShapePainter(
                shape: label.shapeType,
                fillColor: isSelected
                    ? label.fillColor.withValues(alpha: 0.82)
                    : label.fillColor,
                strokeColor: isSelected ? Colors.black : label.strokeColor,
                strokeWidth: label.strokeWidth,
                rotationDegrees: 0,
              ),
            ),
          ),
        );
    }
  }

  static String _resolveLabelText(
      LayerDataLabel label,
      Map<String, dynamic> properties,
      ) {
    final raw = label.text.trim();
    if (raw.isEmpty) return '';

    final propertyValue = _readPropertyValue(properties, raw);
    if (propertyValue != null && propertyValue.toString().trim().isNotEmpty) {
      return propertyValue.toString();
    }

    return raw;
  }

  static Size _labelMarkerSize(LayerDataLabel label) {
    switch (label.type) {
      case LayerSimpleSymbolType.textLayer:
        return const Size(180, 36);
      case LayerSimpleSymbolType.svgMarker:
      case LayerSimpleSymbolType.simpleMarker:
        final w = (label.width + 24).clamp(32.0, 140.0);
        final h = (label.height + 24).clamp(32.0, 140.0);
        return Size(w, h);
    }
  }

  static LatLng? _labelAnchorForFeature(FeatureData feature) {
    final signature = _featureAnchorSignature(feature);
    final cached = _featureAnchorCache[feature];

    if (cached != null && cached.signature == signature) {
      return cached.anchor;
    }

    LatLng? anchor;

    if (feature.markerPoints.isNotEmpty) {
      anchor = feature.markerPoints.first;
    } else if (feature.lineParts.isNotEmpty) {
      final line = feature.lineParts.reduce((a, b) {
        return _polylineLength(a) >= _polylineLength(b) ? a : b;
      });
      anchor = _polylineMidPoint(line);
    } else if (feature.polygonRings.isNotEmpty) {
      final ring = feature.polygonRings.reduce((a, b) {
        return _ringAreaAbs(a) >= _ringAreaAbs(b) ? a : b;
      });
      anchor = _boundsCenter(ring);
    }

    _featureAnchorCache[feature] = _AnchorCacheEntry(
      signature: signature,
      anchor: anchor,
    );

    return anchor;
  }

  static int _featureAnchorSignature(FeatureData feature) {
    LatLng? firstMarker;
    LatLng? lastMarker;
    if (feature.markerPoints.isNotEmpty) {
      firstMarker = feature.markerPoints.first;
      lastMarker = feature.markerPoints.last;
    }

    LatLng? firstLinePoint;
    LatLng? lastLinePoint;
    if (feature.lineParts.isNotEmpty && feature.lineParts.first.isNotEmpty) {
      firstLinePoint = feature.lineParts.first.first;
      final lastPart = feature.lineParts.last;
      if (lastPart.isNotEmpty) {
        lastLinePoint = lastPart.last;
      }
    }

    LatLng? firstPolygonPoint;
    LatLng? lastPolygonPoint;
    if (feature.polygonRings.isNotEmpty &&
        feature.polygonRings.first.isNotEmpty) {
      firstPolygonPoint = feature.polygonRings.first.first;
      final lastRing = feature.polygonRings.last;
      if (lastRing.isNotEmpty) {
        lastPolygonPoint = lastRing.last;
      }
    }

    return Object.hashAll([
      feature.selectionKey,
      feature.geometryType,
      feature.markerPoints.length,
      feature.lineParts.length,
      feature.polygonRings.length,
      firstMarker?.latitude.toStringAsFixed(6),
      firstMarker?.longitude.toStringAsFixed(6),
      lastMarker?.latitude.toStringAsFixed(6),
      lastMarker?.longitude.toStringAsFixed(6),
      firstLinePoint?.latitude.toStringAsFixed(6),
      firstLinePoint?.longitude.toStringAsFixed(6),
      lastLinePoint?.latitude.toStringAsFixed(6),
      lastLinePoint?.longitude.toStringAsFixed(6),
      firstPolygonPoint?.latitude.toStringAsFixed(6),
      firstPolygonPoint?.longitude.toStringAsFixed(6),
      lastPolygonPoint?.latitude.toStringAsFixed(6),
      lastPolygonPoint?.longitude.toStringAsFixed(6),
    ]);
  }

  static double _polylineLength(List<LatLng> points) {
    if (points.length < 2) return 0;
    double total = 0;
    for (int i = 1; i < points.length; i++) {
      total += const Distance().as(LengthUnit.Meter, points[i - 1], points[i]);
    }
    return total;
  }

  static LatLng _polylineMidPoint(List<LatLng> points) {
    if (points.isEmpty) return const LatLng(0, 0);
    if (points.length == 1) return points.first;

    final total = _polylineLength(points);
    if (total <= 0) return points[points.length ~/ 2];

    final half = total / 2;
    double acc = 0;

    for (int i = 1; i < points.length; i++) {
      final a = points[i - 1];
      final b = points[i];
      final segment = const Distance().as(LengthUnit.Meter, a, b);

      if (acc + segment >= half) {
        final remain = half - acc;
        final t = segment == 0 ? 0.0 : remain / segment;
        return LatLng(
          a.latitude + ((b.latitude - a.latitude) * t),
          a.longitude + ((b.longitude - a.longitude) * t),
        );
      }
      acc += segment;
    }

    return points[points.length ~/ 2];
  }

  static double _ringAreaAbs(List<LatLng> ring) {
    if (ring.length < 3) return 0;
    double area = 0;
    for (int i = 0; i < ring.length; i++) {
      final p1 = ring[i];
      final p2 = ring[(i + 1) % ring.length];
      area += (p1.longitude * p2.latitude) - (p2.longitude * p1.latitude);
    }
    return area.abs() / 2;
  }

  static LatLng _boundsCenter(List<LatLng> points) {
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    return LatLng(
      (minLat + maxLat) / 2,
      (minLng + maxLng) / 2,
    );
  }

  static double _adaptTextSize({
    required double baseSize,
    required double zoom,
    required double min,
    required double max,
  }) {
    final safeBase = baseSize <= 0 ? 12.0 : baseSize;
    final scaled = safeBase * _visualScaleForZoom(zoom);
    return scaled.clamp(min, max);
  }

  static List<fm.Polygon> buildPolygons({
    required double zoom,
    required Map<String, List<FeatureData>> featuresByLayer,
    required List<String> orderedActiveLayerIds,
    required Map<String, LayerData> layersById,
    required String? selectedFeatureKey,
    required Map<String, List<LatLng>> temporaryPolygonLayers,
  }) {
    final out = <fm.Polygon>[];

    for (final layerId in orderedActiveLayerIds) {
      final layerFeatures = featuresByLayer[layerId];
      if (layerFeatures == null || layerFeatures.isEmpty) continue;

      for (final feature in layerFeatures) {
        if (!feature.isPolygonFamily) continue;

        final featureLayerId = (feature.layerId ?? '').trim();
        final layer = layersById[featureLayerId];
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

          final baseBorderWidth =
          symbol.strokeWidth <= 0 ? 1.2 : symbol.strokeWidth;
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
      final symbols = (layer?.effectiveSymbolLayers ?? const <LayerDataSimple>[])
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
            final baseBorderWidth =
            symbol.strokeWidth <= 0 ? 2.5 : symbol.strokeWidth;
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
    required Map<String, List<FeatureData>> featuresByLayer,
    required List<String> orderedActiveLayerIds,
    required Map<String, LayerData> layersById,
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

        final featureLayerId = (feature.layerId ?? '').trim();
        final layer = layersById[featureLayerId];
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
        final symbols = (layer?.effectiveSymbolLayers ?? const <LayerDataSimple>[])
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
        final symbols = (layer?.effectiveSymbolLayers ?? const <LayerDataSimple>[])
            .where((e) => e.enabled)
            .toList(growable: false);

        final previewPoints = draftPolygon.length >= 3
            ? [...draftPolygon, draftPolygon.first]
            : draftPolygon;

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
    required Map<String, List<FeatureData>> featuresByLayer,
    required List<String> orderedActiveLayerIds,
    required Map<String, LayerData> layersById,
    required String? selectedFeatureKey,
    required Map<String, List<LatLng>> temporaryPointLayers,
    required Map<String, List<LatLng>> temporaryPolygonLayers,
    required List<LatLng> distanceMeasurementPoints,
  }) {
    final out = <fm.Marker>[];

    for (final layerId in orderedActiveLayerIds) {
      final layerFeatures = featuresByLayer[layerId];
      if (layerFeatures == null || layerFeatures.isEmpty) continue;

      for (final feature in layerFeatures) {
        if (!feature.isPointFamily) continue;

        final featureLayerId = (feature.layerId ?? '').trim();
        final layer = layersById[featureLayerId];
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
              child: IgnorePointer(
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

    return out;
  }

  static List<LayerDataSimple> resolveSymbolsForFeature({
    required LayerData? layer,
    required FeatureData feature,
    required double zoom,
  }) {
    if (layer == null) return const [];

    if (layer.rendererType == LayerRendererType.singleSymbol) {
      return layer.effectiveSymbolLayers;
    }

    final properties = _featureProperties(feature);

    for (final rule in layer.ruleBasedSymbols) {
      if (!rule.enabled) continue;
      if (rule.minZoom != null && zoom < rule.minZoom!) continue;
      if (rule.maxZoom != null && zoom > rule.maxZoom!) continue;

      final matched = _matchesRule(rule, properties);

      if (matched) {
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
      LayerDataRule rule,
      Map<String, dynamic> properties,
      ) {
    final field = rule.field.trim();
    if (field.isEmpty) return true;

    final raw = _readPropertyValue(properties, field);
    final left = _normalizeText(raw);
    final right = _normalizeText(rule.value);

    switch (rule.operatorType) {
      case LayerRuleOperator.equals:
        return left == right;
      case LayerRuleOperator.notEquals:
        return left != right;
      case LayerRuleOperator.contains:
        return right.isEmpty ? left.isEmpty : left.contains(right);
      case LayerRuleOperator.greaterThan:
        return _toDouble(raw) > _toDouble(rule.value);
      case LayerRuleOperator.lessThan:
        return _toDouble(raw) < _toDouble(rule.value);
      case LayerRuleOperator.greaterOrEqual:
        return _toDouble(raw) >= _toDouble(rule.value);
      case LayerRuleOperator.lessOrEqual:
        return _toDouble(raw) <= _toDouble(rule.value);
      case LayerRuleOperator.isEmpty:
        return left.isEmpty;
      case LayerRuleOperator.isNotEmpty:
        return left.isNotEmpty;
    }
  }

  static Map<String, dynamic> _featureProperties(FeatureData feature) {
    final cached = _featurePropertiesCache[feature];
    if (cached != null) return cached;

    final out = <String, dynamic>{};
    out.addAll(feature.originalProperties);
    out.addAll(feature.editedProperties);

    _featurePropertiesCache[feature] = out;
    return out;
  }

  static dynamic _readPropertyValue(
      Map<String, dynamic> properties,
      String field,
      ) {
    if (properties.containsKey(field)) {
      return properties[field];
    }

    final normalizedTarget = field.trim().toLowerCase();

    for (final entry in properties.entries) {
      final key = entry.key.trim().toLowerCase();
      if (key == normalizedTarget) {
        return entry.value;
      }
    }

    return null;
  }

  static String _normalizeText(dynamic value) {
    if (value == null) return '';
    return value.toString().trim().toLowerCase();
  }

  static double _toDouble(dynamic value) {
    if (value == null) return double.nan;
    return double.tryParse(
      value.toString().trim().replaceAll(',', '.'),
    ) ??
        double.nan;
  }

  static Widget buildSymbolWidget({
    required LayerDataSimple symbol,
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
    required LayerDataSimple symbol,
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
    final adapted = safeBase * math.pow(scale, 0.92).toDouble();
    return adapted.clamp(1.0, 64.0);
  }

  static List<double> _adaptDashSegments({
    required List<double> rawSegments,
    required double zoom,
  }) {
    final scale = _visualScaleForZoom(zoom);

    return rawSegments.map((value) {
      final safe = value <= 0 ? 0.5 : value;
      final adapted = safe * math.pow(scale, 0.92).toDouble();
      return adapted.clamp(0.75, 80.0);
    }).toList(growable: false);
  }

  static double _adaptOffsetPixels({
    required double baseOffsetPixels,
    required double baseStrokeWidth,
    required double zoom,
  }) {
    if (baseOffsetPixels.abs() < 0.0001) return 0.0;

    final scale = _visualScaleForZoom(zoom);
    final zoomAdjusted = baseOffsetPixels * math.pow(scale, 1.10).toDouble();

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

class _AnchorCacheEntry {
  final int signature;
  final LatLng? anchor;

  const _AnchorCacheEntry({
    required this.signature,
    required this.anchor,
  });
}