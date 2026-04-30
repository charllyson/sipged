import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:sipged/_blocs/modules/planning/geo/feature/feature_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data.dart';
import 'package:sipged/_widgets/map/map/map_change.dart';

/// Widget responsável apenas pelo MAPA da tela de acidentes.
class AccidentsMapSection extends StatefulWidget {
  final void Function(MapController controller)? onControllerReady;
  final void Function(void Function(LatLng) setActivePoint)? onBindSetActivePoint;
  final void Function(double lat, double lon)? onMapTap;

  const AccidentsMapSection({
    super.key,
    this.onControllerReady,
    this.onBindSetActivePoint,
    this.onMapTap,
  });

  @override
  State<AccidentsMapSection> createState() => _AccidentsMapSectionState();
}

class _AccidentsMapSectionState extends State<AccidentsMapSection> {
  LatLng? _activePoint;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      widget.onBindSetActivePoint?.call(_setActivePoint);
    });
  }

  void _setActivePoint(LatLng point) {
    if (!mounted) return;

    setState(() {
      _activePoint = point;
    });
  }

  List<Marker> get _markers {
    final point = _activePoint;

    if (point == null) {
      return const <Marker>[];
    }

    return [
      Marker(
        point: point,
        width: 46,
        height: 46,
        alignment: Alignment.topCenter,
        child: const Icon(
          Icons.location_on,
          color: Color(0xFFD32F2F),
          size: 42,
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return MapChange(
      key: const ValueKey('accidents-map'),

      features: const <FeatureData>[],
      layersById: const <String, LayerData>{},
      orderedActiveLayerIds: const <String>[],

      selectedFeatureKey: null,
      loading: false,

      visualDataSignature: Object.hash(
        'accidents-map',
        _activePoint?.latitude,
        _activePoint?.longitude,
      ),

      initialCenter: const LatLng(-9.6658, -35.7353),
      initialZoom: 9,
      minZoom: 4,
      maxZoom: 19,

      showSearch: true,
      showControls: true,

      externalMarkers: _markers,

      onControllerReady: (controller) {
        widget.onControllerReady?.call(controller);
      },

      onCameraChanged: (_, _) {},

      onFeatureTap: (_) {},

      onBackgroundTap: (latLng) {
        _setActivePoint(latLng);
        widget.onMapTap?.call(latLng.latitude, latLng.longitude);

        return true;
      },
    );
  }
}