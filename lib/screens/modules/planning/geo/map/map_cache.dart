import 'package:latlong2/latlong.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/feature_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data_labels.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data_rule.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data_simple.dart';

class MapCache {
  MapCache._();

  static final Expando<int> _layerVisualSignatureCache =
  Expando<int>('layer_visual_signature_cache');

  static final Expando<int> _featureStaticListSignatureCache =
  Expando<int>('feature_static_list_signature_cache');

  static final Expando<int> _featureMarkerListSignatureCache =
  Expando<int>('feature_marker_list_signature_cache');

  static double staticZoomBucket(double zoom) {
    return (zoom * 2).round() / 2.0;
  }

  static double markerZoomBucket(double zoom) {
    return (zoom * 4).round() / 4.0;
  }

  static double zoomBucket(double zoom) {
    return markerZoomBucket(zoom);
  }

  static int pointsSignature(List<LatLng> points) {
    if (points.isEmpty) return 0;

    return Object.hash(
      points.length,
      points.first.latitude,
      points.first.longitude,
      points.last.latitude,
      points.last.longitude,
    );
  }

  static Map<String, List<FeatureData>> groupFeaturesByLayer(
      List<FeatureData> features,
      ) {
    final out = <String, List<FeatureData>>{};

    for (final feature in features) {
      final layerId = (feature.layerId ?? '').trim();
      if (layerId.isEmpty) continue;

      (out[layerId] ??= <FeatureData>[]).add(feature);
    }

    return out;
  }

  static int layerVisualSignature(LayerData layer) {
    final cached = _layerVisualSignatureCache[layer];
    if (cached != null) return cached;

    final signature = Object.hashAll([
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
      layer.symbolLayers.length,
      layer.ruleBasedSymbols.length,
      layer.labelLayers.length,
      layer.ruleBasedLabels.length,
      ...layer.symbolLayers.map(symbolVisualSignature),
      ...layer.ruleBasedSymbols.map(ruleVisualSignature),
      ...layer.labelLayers.map(labelVisualSignature),
      ...layer.ruleBasedLabels.map(labelRuleVisualSignature),
    ]);

    _layerVisualSignatureCache[layer] = signature;
    return signature;
  }

  static int symbolVisualSignature(LayerDataSimple symbol) {
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
      symbol.dashArray.length,
      if (symbol.dashArray.isNotEmpty) symbol.dashArray.first,
      if (symbol.dashArray.length > 1) symbol.dashArray.last,
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

  static int ruleVisualSignature(LayerDataRule rule) {
    return Object.hashAll([
      rule.id,
      rule.label,
      rule.enabled,
      rule.field,
      rule.operatorType,
      rule.value,
      rule.minZoom,
      rule.maxZoom,
      rule.symbolLayers.length,
      ...rule.symbolLayers.map(symbolVisualSignature),
    ]);
  }

  static int labelVisualSignature(LayerDataLabel label) {
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

  static int featureStaticSignature(FeatureData f) {
    return Object.hash(
      f.selectionKey,
      f.layerId,
      f.geometryType,
      f.markerPoints.length,
      f.lineParts.length,
      f.polygonRings.length,
      f.originalProperties.length,
      f.editedProperties.length,
    );
  }

  static int featureMarkerSignature(FeatureData f) {
    return Object.hash(
      f.selectionKey,
      f.layerId,
      f.geometryType,
      f.markerPoints.length,
      f.originalProperties.length,
      f.editedProperties.length,
    );
  }

  static int _featureStaticListSignature(List<FeatureData> features) {
    final cached = _featureStaticListSignatureCache[features];
    if (cached != null) return cached;

    final signature = Object.hashAll([
      features.length,
      if (features.isNotEmpty) featureStaticSignature(features.first),
      if (features.length > 1) featureStaticSignature(features.last),
      ...features.map(featureStaticSignature),
    ]);

    _featureStaticListSignatureCache[features] = signature;
    return signature;
  }

  static int _featureMarkerListSignature(List<FeatureData> features) {
    final cached = _featureMarkerListSignatureCache[features];
    if (cached != null) return cached;

    final signature = Object.hashAll([
      features.length,
      if (features.isNotEmpty) featureMarkerSignature(features.first),
      if (features.length > 1) featureMarkerSignature(features.last),
      ...features.map(featureMarkerSignature),
    ]);

    _featureMarkerListSignatureCache[features] = signature;
    return signature;
  }

  static int _activeLayersVisualSignature({
    required Map<String, LayerData> layersById,
    required List<String> orderedActiveLayerIds,
  }) {
    return Object.hashAll(
      orderedActiveLayerIds.map((layerId) {
        final layer = layersById[layerId];
        if (layer == null) return Object.hash(layerId, 'missing_layer');
        return Object.hash(layerId, layerVisualSignature(layer));
      }),
    );
  }

  static int computeStaticVisualSignature({
    required double zoomBucket,
    required String? selectedFeatureKey,
    required List<FeatureData> features,
    required Map<String, LayerData> layersById,
    required List<String> orderedActiveLayerIds,
    required Map<String, List<LatLng>> temporaryLineLayers,
    required Map<String, List<LatLng>> temporaryPolygonLayers,
    required List<LatLng> distanceMeasurementPoints,
  }) {
    final featureSig = _featureStaticListSignature(features);
    final activeLayersSig = _activeLayersVisualSignature(
      layersById: layersById,
      orderedActiveLayerIds: orderedActiveLayerIds,
    );

    return Object.hashAll([
      'STATIC',
      zoomBucket,
      selectedFeatureKey,
      orderedActiveLayerIds.length,
      activeLayersSig,
      featureSig,
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
    required List<FeatureData> features,
    required Map<String, LayerData> layersById,
    required List<String> orderedActiveLayerIds,
    required Map<String, List<LatLng>> temporaryPointLayers,
    required Map<String, List<LatLng>> temporaryPolygonLayers,
    required List<LatLng> distanceMeasurementPoints,
  }) {
    final featureSig = _featureMarkerListSignature(features);
    final activeLayersSig = _activeLayersVisualSignature(
      layersById: layersById,
      orderedActiveLayerIds: orderedActiveLayerIds,
    );

    return Object.hashAll([
      'MARKERS',
      zoomBucket,
      selectedFeatureKey,
      orderedActiveLayerIds.length,
      activeLayersSig,
      featureSig,
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