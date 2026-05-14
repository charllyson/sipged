import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/feature_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data.dart';
import 'package:sipged/_widgets/map/map/map_change.dart';

class LandMap extends StatefulWidget {
  final ContractData contractData;

  const LandMap({
    super.key,
    required this.contractData,
  });

  @override
  State<LandMap> createState() => _LandMapState();
}

class _LandMapState extends State<LandMap> {
  FeatureData? _selectedFeature;

  String get _contractId => widget.contractData.id?.trim() ?? '';

  Object get _visualSignature {
    return Object.hash(
      'land-map',
      _contractId,
      _selectedFeature?.selectionKey,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return MapChange(
          features: const <FeatureData>[],
          layersById: const <String, LayerData>{},
          orderedActiveLayerIds: const <String>[],
          selectedFeatureKey: _selectedFeature?.selectionKey,
          visualDataSignature: _visualSignature,
          initialCenter: const LatLng(-9.6498, -35.7089),
          initialZoom: 10.0,
          minZoom: 3.0,
          maxZoom: 19.0,
          showSearch: true,
          showControls: true,
          showZoomSlider: true,
          showMapTypeButton: true,
          showRotationButton: false,
          enableZoom: true,
          enablePan: true,
          enableRotation: false,
          onControllerReady: (controller) {
          },
          onFeatureTap: (feature) {
            setState(() {
              _selectedFeature = feature;
            });
          },
          onCameraChanged: (center, zoom) {},
          onBackgroundTap: (latLng) {
            if (_selectedFeature != null) {
              setState(() {
                _selectedFeature = null;
              });
            }

            return false;
          },
        );
      },
    );
  }
}