import 'package:flutter/material.dart';
import 'package:siged/_blocs/panels/overview-dashboard/overview_dashboard_style.dart';
import 'package:siged/_services/geo_json_manager.dart';
import 'package:siged/_widgets/map/map_interactive.dart';

class OverviewDashboardMap extends StatelessWidget {
  final GeoJsonManager geoManager;
  final List<String> selectedRegionNames;
  final void Function(String?) onRegionTap;
  final double? height;

  const OverviewDashboardMap({
    super.key,
    required this.geoManager,
    required this.selectedRegionNames,
    required this.onRegionTap,
    this.height = 320,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
          child: MapInteractivePage(
            polygonsChanged: geoManager.regionalPolygons,
            selectedRegionNames: selectedRegionNames,
            onRegionTap: onRegionTap,
            activeMap: true,
            initialZoom: 7.3,
            allowMultiSelect: false,
            showLegend: true,
            polygonChangeColors: OverviewDashboardStyle.regionsColors,
          ),
        ),
      ),
    );
  }
}
