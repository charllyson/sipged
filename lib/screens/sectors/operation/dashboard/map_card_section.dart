import 'package:flutter/material.dart';
import 'package:sisged/_datas/documents/contracts/contracts/contract_style.dart';
import 'package:sisged/_services/geo_json_manager.dart';

import 'package:sisged/_widgets/map/map_interactive.dart';

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
    final w = MediaQuery.of(context).size.width;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(width: 6),
        SizedBox(
          height: height,
          width: w - 24,
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: MapInteractivePage(
              regionalPolygons: geoManager.regionalPolygons,
              selectedRegionNames: selectedRegionNames,
              onRegionTap: onRegionTap,
                activeMap: true,
              initialZoom: 7.3,
              allowMultiSelect: false,
              showLegend: true,
              regionColors: ContractStyle.regionsColors
            ),
          ),
        ),
      ],
    );
  }
}
