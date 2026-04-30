import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:sipged/_blocs/modules/planning/geo/feature/feature_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data.dart';
import 'package:sipged/_widgets/map/map/map_change.dart';

class GeoNetworkMapArea extends StatelessWidget {
  const GeoNetworkMapArea({
    super.key,
    required this.visualDataSignature,
    required this.features,
    required this.layersById,
    required this.orderedActiveLayerIds,
    required this.selectedFeatureKey,
    required this.loading,
    required this.cursor,
    required this.temporaryPointLayers,
    required this.temporaryLineLayers,
    required this.temporaryPolygonLayers,
    required this.distanceMeasurementPoints,
    required this.onControllerReady,
    required this.onBackgroundTap,
    required this.onFeatureTap,
  });

  final Object visualDataSignature;

  final List<FeatureData> features;
  final Map<String, LayerData> layersById;
  final List<String> orderedActiveLayerIds;

  final String? selectedFeatureKey;
  final bool loading;
  final MouseCursor cursor;

  final Map<String, List<LatLng>> temporaryPointLayers;
  final Map<String, List<LatLng>> temporaryLineLayers;
  final Map<String, List<LatLng>> temporaryPolygonLayers;

  final List<LatLng> distanceMeasurementPoints;

  final ValueChanged<MapController> onControllerReady;
  final bool Function(LatLng latLng) onBackgroundTap;
  final ValueChanged<FeatureData?> onFeatureTap;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: MapChange(
        visualDataSignature: visualDataSignature,
        features: features,
        layersById: layersById,
        orderedActiveLayerIds: orderedActiveLayerIds,
        selectedFeatureKey: selectedFeatureKey,
        loading: loading,
        onControllerReady: onControllerReady,
        onCameraChanged: (_, _) {},
        cursor: cursor,
        temporaryPointLayers: temporaryPointLayers,
        temporaryLineLayers: temporaryLineLayers,
        temporaryPolygonLayers: temporaryPolygonLayers,
        distanceMeasurementPoints: distanceMeasurementPoints,
        onBackgroundTap: onBackgroundTap,
        onFeatureTap: onFeatureTap,
      ),
    );
  }
}