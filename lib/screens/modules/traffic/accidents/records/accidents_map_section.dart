import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:sipged/_widgets/map/flutter_map/map_interactive.dart';

/// Widget responsável apenas pelo MAPA da tela de acidentes.
class AccidentsMapSection extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return MapInteractivePage(
      key: const ValueKey('accidents-map'),
      dropPinOnTap: true,
      activeMap: true,
      showLegend: true,
      showSearch: true,
      showMyLocation: true,
      showChangeMapType: true,
      onControllerReady: onControllerReady,
      onBindSetActivePoint: onBindSetActivePoint,
      onMapTap: (lat, lon) => onMapTap?.call(lat, lon),
    );
  }
}