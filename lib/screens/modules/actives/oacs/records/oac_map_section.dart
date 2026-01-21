import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:siged/_widgets/map/flutter_map/map_interactive.dart';

class OacMapSection extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return MapInteractivePage(
      key: const ValueKey('oacs-map'),
      dropPinOnTap: true,
      activeMap: true,
      showLegend: true,
      showSearch: true,
      onControllerReady: onControllerReady,
      onBindSetActivePoint: onBindSetActivePoint,
      onMapTap: (lat, lon) => onMapTap?.call(lat, lon),
    );
  }
}
