import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'package:sipged/_blocs/modules/actives/roads/active_roads_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/feature_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data.dart';
import 'package:sipged/_widgets/map/map/map_change.dart';

class RoadDetailsMapSection extends StatefulWidget {
  final ActiveRoadsData? road;

  const RoadDetailsMapSection({
    super.key,
    this.road,
  });

  @override
  State<RoadDetailsMapSection> createState() => _RoadDetailsMapSectionState();
}

class _RoadDetailsMapSectionState extends State<RoadDetailsMapSection> {
  double _currentZoom = 12.0;
  double _centerLat = -9.65;

  LatLng get _fallbackCenter {
    final points = widget.road?.points ?? const <LatLng>[];

    if (points.isEmpty) {
      return const LatLng(-9.6658, -35.7353);
    }

    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;

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

  @override
  void didUpdateWidget(covariant RoadDetailsMapSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.road?.id != widget.road?.id) {
      _currentZoom = widget.road?.idealDetailMapZoom ?? 15.0;
      _centerLat = _fallbackCenter.latitude;
    }
  }

  @override
  Widget build(BuildContext context) {
    final road = widget.road;
    final points = road?.points ?? const <LatLng>[];

    final initialZoom = road?.idealDetailMapZoom ?? 15.0;

    return Container(
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: MapChange(
          key: ValueKey('road-details-map-${road?.id ?? 'new'}'),

          features: const <FeatureData>[],
          layersById: const <String, LayerData>{},
          orderedActiveLayerIds: const <String>[],

          selectedFeatureKey: null,
          loading: false,

          visualDataSignature: Object.hash(
            'road-details-map',
            road?.id,
            points.length,
            _currentZoom,
            _centerLat,
          ),

          initialCenter: _fallbackCenter,
          initialZoom: initialZoom,
          minZoom: 4,
          maxZoom: 18,

          showSearch: true,
          showControls: true,

          initialGeometryPoints: points,
          fitInitialGeometryOnce: points.isNotEmpty,

          externalPolylines: road?.buildDetailPolylines(
            zoom: _currentZoom,
            centerLatitude: _centerLat,
          ) ??
              const [],

          onControllerReady: (_) {},

          onCameraChanged: (center, zoom) {
            if (!mounted) return;

            setState(() {
              _currentZoom = zoom;
              _centerLat = center.latitude;
            });
          },

          onFeatureTap: (_) {},
        ),
      ),
    );
  }
}