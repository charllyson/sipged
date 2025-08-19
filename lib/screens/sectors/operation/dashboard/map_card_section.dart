import 'package:flutter/material.dart';
import 'package:sisged/_datas/documents/contracts/contracts/contract_style.dart';
import 'package:sisged/_services/geo_json_manager.dart';

import '../../../../_widgets/map/map_interactive.dart';

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
              // 🔹 polígonos regionais vindos do GeoJsonManager
              regionalPolygons: geoManager.regionalPolygons,

              // 🔹 seleção/controladores externos
              selectedRegionNames: selectedRegionNames,
              onRegionTap: onRegionTap,

              // 🔹 mapa/zoom/legenda
              activeMap: true,
              initialZoom: 7.6,
              allowMultiSelect: false,
              showLegend: true,

              // 🔹 coloração por região (mantém seu ContractStyle)
              regionColors: ContractStyle.regionsColors,

              // (opcionais) se usar polylines/markers no futuro:
              // tappablePolylines: ...,
              // onSelectPolyline: ...,
              // onShowPolylineTooltip: ...,
              // taggedMarkers: ...,
              // clusterWidgetBuilder: ...,
            ),
          ),
        ),
      ],
    );
  }
}
