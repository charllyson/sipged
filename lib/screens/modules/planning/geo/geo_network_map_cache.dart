import 'package:latlong2/latlong.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/geo_feature_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data_labels.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data_rule.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data_simple.dart';

class GeoNetworkMapCache {
  GeoNetworkMapCache._();

  /// Bucket mais "grosso" para elementos estáticos de mapa
  /// (polygons / polylines / hit test).
  ///
  /// Exemplo:
  /// 10.12 -> 10.0
  /// 10.26 -> 10.5
  static double staticZoomBucket(double zoom) {
    return (zoom * 2).round() / 2.0;
  }

  /// Bucket um pouco mais sensível para markers e labels.
  ///
  /// Exemplo:
  /// 10.12 -> 10.0
  /// 10.18 -> 10.25
  /// 10.36 -> 10.25 / 10.5
  static double markerZoomBucket(double zoom) {
    return (zoom * 4).round() / 4.0;
  }

  /// Mantido por compatibilidade, caso algum ponto do projeto ainda use.
  static double zoomBucket(double zoom) {
    return markerZoomBucket(zoom);
  }

  static int pointsSignature(List<LatLng> points) {
    return Object.hashAll(
      points.map((e) => Object.hash(e.latitude, e.longitude)),
    );
  }

  static Map<String, List<GeoFeatureData>> groupFeaturesByLayer(
      List<GeoFeatureData> features,
      ) {
    final out = <String, List<GeoFeatureData>>{};

    for (final feature in features) {
      final layerId = (feature.layerId ?? '').trim();
      if (layerId.isEmpty) continue;

      (out[layerId] ??= <GeoFeatureData>[]).add(feature);
    }

    return out;
  }

  static int layerVisualSignature(GeoLayersData layer) {
    return Object.hashAll([
      layer.id,
      layer.title,
      layer.iconKey,
      layer.colorValue,
      layer.defaultVisible,
      layer.isGroup,
      layer.collectionPath,
      layer.geometryKind,
      layer.supportsConnect,
      layer.isTemporary,
      layer.isSystem,
      layer.rendererType,
      layer.labelRendererType,
      ...layer.symbolLayers.map(symbolVisualSignature),
      ...layer.ruleBasedSymbols.map(ruleVisualSignature),
      ...layer.labelLayers.map(labelVisualSignature),
      ...layer.ruleBasedLabels.map(labelRuleVisualSignature),
      ...layer.children.map(layerVisualSignature),
    ]);
  }

  static int symbolVisualSignature(GeoLayersDataSimple symbol) {
    return Object.hashAll([
      symbol.id,
      symbol.family,
      symbol.type,
      symbol.iconKey,
      symbol.shapeType,
      symbol.width,
      symbol.height,
      symbol.keepAspectRatio,
      symbol.fillColorValue,
      symbol.strokeColorValue,
      symbol.strokeWidth,
      symbol.rotationDegrees,
      symbol.enabled,
      symbol.strokePattern,
      symbol.offset,
      ...symbol.dashArray,
      symbol.title,
      symbol.text,
      symbol.textFontSize,
      symbol.textColorValue,
      symbol.textFontWeight,
      symbol.textOffsetX,
      symbol.textOffsetY,
      symbol.useCustomDashPattern,
      symbol.dashWidth,
      symbol.dashGap,
      symbol.strokeJoin,
      symbol.strokeCap,
    ]);
  }

  static int ruleVisualSignature(GeoLayersDataRule rule) {
    return Object.hashAll([
      rule.id,
      rule.label,
      rule.enabled,
      rule.field,
      rule.operatorType,
      rule.value,
      rule.minZoom,
      rule.maxZoom,
      ...rule.symbolLayers.map(symbolVisualSignature),
    ]);
  }

  static int labelVisualSignature(GeoLabelStyleData label) {
    return Object.hashAll([
      label.id,
      label.title,
      label.text,
      label.enabled,
      label.type,
      label.fontSize,
      label.colorValue,
      label.fontWeight,
      label.offsetX,
      label.offsetY,
      label.iconKey,
      label.shapeType,
      label.width,
      label.height,
      label.keepAspectRatio,
      label.fillColorValue,
      label.strokeColorValue,
      label.strokeWidth,
      label.rotationDegrees,
      label.geometryOffset,
    ]);
  }

  static int labelRuleVisualSignature(GeoLabelRuleData rule) {
    return Object.hashAll([
      rule.id,
      rule.label,
      rule.enabled,
      rule.field,
      rule.operatorType,
      rule.value,
      rule.minZoom,
      rule.maxZoom,
      labelVisualSignature(rule.style),
    ]);
  }

  static int featureStaticSignature(GeoFeatureData f) {
    return Object.hashAll([
      f.selectionKey,
      f.layerId,
      f.geometryType,
      f.markerPoints.length,
      f.lineParts.length,
      f.polygonRings.length,
      Object.hashAll(
        f.editedProperties.entries.map((e) => Object.hash(e.key, e.value)),
      ),
      Object.hashAll(
        f.originalProperties.entries.map((e) => Object.hash(e.key, e.value)),
      ),
    ]);
  }

  static int featureMarkerSignature(GeoFeatureData f) {
    return Object.hashAll([
      f.selectionKey,
      f.layerId,
      f.geometryType,
      f.markerPoints.length,
      Object.hashAll(
        f.editedProperties.entries.map((e) => Object.hash(e.key, e.value)),
      ),
      Object.hashAll(
        f.originalProperties.entries.map((e) => Object.hash(e.key, e.value)),
      ),
    ]);
  }

  static int computeStaticVisualSignature({
    required double zoomBucket,
    required String? selectedFeatureKey,
    required List<GeoFeatureData> features,
    required Map<String, GeoLayersData> layersById,
    required List<String> orderedActiveLayerIds,
    required Map<String, List<LatLng>> temporaryLineLayers,
    required Map<String, List<LatLng>> temporaryPolygonLayers,
    required List<LatLng> distanceMeasurementPoints,
  }) {
    return Object.hashAll([
      'STATIC',
      zoomBucket,
      selectedFeatureKey,
      features.length,
      ...features.map(featureStaticSignature),
      layersById.length,
      ...layersById.entries.map(
            (e) => Object.hash(e.key, layerVisualSignature(e.value)),
      ),
      ...orderedActiveLayerIds,
      ...temporaryLineLayers.entries.map(
            (e) => Object.hash(e.key, pointsSignature(e.value)),
      ),
      ...temporaryPolygonLayers.entries.map(
            (e) => Object.hash(e.key, pointsSignature(e.value)),
      ),
      pointsSignature(distanceMeasurementPoints),
    ]);
  }

  static int computeMarkerVisualSignature({
    required double zoomBucket,
    required String? selectedFeatureKey,
    required List<GeoFeatureData> features,
    required Map<String, GeoLayersData> layersById,
    required List<String> orderedActiveLayerIds,
    required Map<String, List<LatLng>> temporaryPointLayers,
    required Map<String, List<LatLng>> temporaryPolygonLayers,
    required List<LatLng> distanceMeasurementPoints,
  }) {
    return Object.hashAll([
      'MARKERS',
      zoomBucket,
      selectedFeatureKey,
      features.length,
      ...features.map(featureMarkerSignature),
      layersById.length,
      ...layersById.entries.map(
            (e) => Object.hash(e.key, layerVisualSignature(e.value)),
      ),
      ...orderedActiveLayerIds,
      ...temporaryPointLayers.entries.map(
            (e) => Object.hash(e.key, pointsSignature(e.value)),
      ),
      ...temporaryPolygonLayers.entries.map(
            (e) => Object.hash(e.key, pointsSignature(e.value)),
      ),
      pointsSignature(distanceMeasurementPoints),
    ]);
  }
}