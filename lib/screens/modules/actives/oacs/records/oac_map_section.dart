import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:sipged/_blocs/modules/planning/geo/feature/feature_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data.dart';
import 'package:sipged/_widgets/map/map/map_change.dart';

class OacMapSection extends StatefulWidget {
  final void Function(MapController controller)? onControllerReady;
  final void Function(void Function(LatLng) setActivePoint)? onBindSetActivePoint;
  final void Function(double lat, double lon)? onMapTap;

  const OacMapSection({
    super.key,
    this.onControllerReady,
    this.onBindSetActivePoint,
    this.onMapTap,
  });

  @override
  State<OacMapSection> createState() => _OacMapSectionState();
}

class _OacMapSectionState extends State<OacMapSection> {
  LatLng? _activePoint;

  static const LatLng _initialCenter = LatLng(-9.6658, -35.7353);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onBindSetActivePoint?.call(_setActivePoint);
    });
  }

  @override
  void didUpdateWidget(covariant OacMapSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.onBindSetActivePoint != widget.onBindSetActivePoint) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.onBindSetActivePoint?.call(_setActivePoint);
      });
    }
  }

  void _setActivePoint(LatLng point) {
    if (!mounted) return;

    setState(() {
      _activePoint = point;
    });
  }

  List<Marker> _buildActivePointMarkers() {
    final point = _activePoint;
    if (point == null) return const <Marker>[];

    return <Marker>[
      Marker(
        point: point,
        width: 42,
        height: 42,
        alignment: Alignment.topCenter,
        child: const IgnorePointer(
          child: Icon(
            Icons.location_on,
            size: 42,
            color: Color(0xFFD32F2F),
            shadows: [
              Shadow(
                blurRadius: 8,
                color: Colors.black38,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return MapChange(
      key: const ValueKey('oacs-map'),

      features: const <FeatureData>[],
      layersById: const <String, LayerData>{},
      orderedActiveLayerIds: const <String>[],

      selectedFeatureKey: null,
      loading: false,

      visualDataSignature: Object.hash(
        'oacs-map',
        _activePoint?.latitude,
        _activePoint?.longitude,
      ),

      initialCenter: _initialCenter,
      initialZoom: 7.8,
      minZoom: 4,
      maxZoom: 18,

      showSearch: true,
      showControls: true,

      externalMarkers: _buildActivePointMarkers(),

      onControllerReady: (controller) {
        widget.onControllerReady?.call(controller);
      },

      onFeatureTap: (_) {},

      onBackgroundTap: (latLng) {
        _setActivePoint(latLng);
        widget.onMapTap?.call(latLng.latitude, latLng.longitude);

        return true;
      },
    );
  }
}