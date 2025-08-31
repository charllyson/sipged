import 'package:flutter/material.dart';
import 'package:siged/_blocs/documents/contracts/contracts/contract_style.dart';
import 'package:siged/_blocs/widgets/map/geo_json_manager.dart';
import 'package:siged/_widgets/map/map_interactive.dart';

class MapContractSection extends StatelessWidget {
  final GeoJsonManager geoManager;
  final List<String> selectedRegionNames;
  final void Function(String?) onRegionTap;
  final double? height;

  const MapContractSection({
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
            regionalPolygons: geoManager.regionalPolygons,
            selectedRegionNames: selectedRegionNames,
            onRegionTap: onRegionTap,
            activeMap: true,
            initialZoom: 7.3,
            allowMultiSelect: false,
            showLegend: true,
            regionColors: ContractStyle.regionsColors,
          ),
        ),
      ),
    );
  }
}
