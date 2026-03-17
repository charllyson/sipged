import 'package:flutter/material.dart';

import 'package:sipged/_blocs/modules/actives/roads/active_roads_data.dart';
import 'package:sipged/_widgets/map/flutter_map/map_interactive.dart';

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

  @override
  Widget build(BuildContext context) {
    final road = widget.road;
    final points = road?.points ?? const [];

    return Container(
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: MapInteractivePage<ActiveRoadsData>(
          key: ValueKey('road-details-map-${road?.id ?? 'new'}'),
          initialZoom: road?.idealDetailMapZoom ?? 15.0,
          activeMap: true,
          showLegend: false,
          showSearch: true,
          initialGeometryPoints: points,
          tappablePolylines: road?.buildDetailPolylines(
            zoom: _currentZoom,
            centerLatitude: _centerLat,
          ) ??
              const [],
          onCameraChanged: (zoom, center) {
            setState(() {
              _currentZoom = zoom;
              _centerLat = center.latitude;
            });
          },
        ),
      ),
    );
  }
}