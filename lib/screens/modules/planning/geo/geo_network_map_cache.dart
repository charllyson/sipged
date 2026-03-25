import 'package:latlong2/latlong.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/geo_feature_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data_rule.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data_simple.dart';

class GeoNetworkMapCache {
  GeoNetworkMapCache._();

  static double zoomBucket(double zoom) {
    return (zoom * 10).round() / 10.0;
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
      (out[feature.layerId] ??= <GeoFeatureData>[]).add(feature);
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
      ...layer.symbolLayers.map(symbolVisualSignature),
      ...layer.ruleBasedSymbols.map(ruleVisualSignature),
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
      zoomBucket,
      selectedFeatureKey,
      features.length,
      ...features.map(
            (f) => Object.hash(
          f.selectionKey,
          f.layerId,
          f.markerPoints.length,
          f.lineParts.length,
          f.polygonRings.length,
          f.properties.toString(),
        ),
      ),
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
    required Map<String, List<LatLng>> temporaryPointLayers,
    required Map<String, List<LatLng>> temporaryPolygonLayers,
    required List<LatLng> distanceMeasurementPoints,
  }) {
    return Object.hashAll([
      zoomBucket,
      selectedFeatureKey,
      features.length,
      ...features.map(
            (f) => Object.hash(
          f.selectionKey,
          f.layerId,
          f.markerPoints.length,
          f.properties.toString(),
        ),
      ),
      layersById.length,
      ...layersById.entries.map(
            (e) => Object.hash(e.key, layerVisualSignature(e.value)),
      ),
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