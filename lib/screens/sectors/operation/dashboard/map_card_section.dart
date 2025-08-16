import 'package:flutter/material.dart';
import 'package:sisged/_datas/documents/contracts/contracts/contract_style.dart';
import 'package:sisged/_services/geo_json_manager.dart';

import '../../../../_widgets/map/mapa_page.dart';
import '../../../../_datas/documents/contracts/contracts/contracts_data.dart';

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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(width: 6),
        SizedBox(
          height: height,
          width: MediaQuery.of(context).size.width - 24,
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: MapaInterativoPage(
              geoManager: geoManager,
              selectedRegionNames: selectedRegionNames,
              onRegionTap: onRegionTap,
              activeMap: true,
              initialZoom: 7.6,
              regionColors: ContractStyle.regionsColors,
              allowMultiSelect: false,
              showLegend: true,
            ),
          ),
        ),
      ],
    );
  }
}
