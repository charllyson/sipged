import 'package:flutter/material.dart';
import 'package:siged/screens/sectors/traffic/dashboard/show_city_details.dart';
import '../../../../_widgets/map/map_interactive.dart';
import '../../../../_widgets/map/polygon/polygon_changed.dart';
import '../../../../_blocs/sectors/transit/accidents/accidents_data.dart';

class AccidentsMapSection extends StatefulWidget {
  final List<PolygonChanged> regionalPolygons; // polígonos prontos
  final List<String> selectedRegionNames;
  final void Function(String?) onRegionTap;

  /// Cores já calculadas (cidade -> cor), vindas do controller
  final Map<String, Color> regionColors;

  /// Quem fornece os dados da cidade é o controller (que chama o Bloc)
  final Future<List<AccidentsData>> Function(String city) fetchCityData;

  final double? height;

  const AccidentsMapSection({
    super.key,
    required this.regionalPolygons,
    required this.selectedRegionNames,
    required this.onRegionTap,
    required this.regionColors,
    required this.fetchCityData,
    this.height = 320,
  });

  @override
  State<AccidentsMapSection> createState() => _AccidentsMapSectionState();
}

class _AccidentsMapSectionState extends State<AccidentsMapSection> {
  Future<void> _handleRegionTap(String? region) async {
    // Propaga seleção para o chamador (sincroniza gráficos/filtros)
    widget.onRegionTap(region);

    // Se clicou fora/limpou seleção, não abre diálogo
    if (region == null) return;

    // Carrega e abre o diálogo
    final dados = await widget.fetchCityData(region);
    if (!mounted) return;

    _showDialogCity(
      context: context,
      region: region,
      dados: dados,
    );
  }

  void _showDialogCity({
    required BuildContext context,
    required String region,
    required List<AccidentsData> dados,
  }) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        child: ShowCityDetails(dados: dados, region: region)
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return MapInteractivePage(
      polygonsChanged: widget.regionalPolygons,
      selectedRegionNames: widget.selectedRegionNames,
      onRegionTap: _handleRegionTap, // <- busca & abre diálogo
      activeMap: true,
      showSearch: true,
      polygonChangeColors: widget.regionColors, // calculado no controller
      allowMultiSelect: false,
      showLegend: false,
    );
  }
}
