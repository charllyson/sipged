import 'package:flutter/material.dart';
import '../../../../_widgets/map/mapa_page.dart';
import '../../../../_services/regional_geo_json_class.dart';
import '../../../../_datas/sectors/transit/accidents/accidents_data.dart';

class AccidentsMapSection extends StatefulWidget {
  final List<RegionalPolygon> regionalPolygons;         // <- recebe os polígonos prontos
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
  void _showDialogCity({
    required BuildContext context,
    required String region,
    required List<AccidentsData> dados,
  }) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.6,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: dados.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('MUNICÍPIO: $region',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  const Text('Não há dados disponíveis'),
                ],
              ),
            )
                : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(region,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const Divider(height: 20),
                  ...dados.map(
                        (acc) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _line('Data', acc.date?.toString() ?? 'N/A'),
                        _line('Rodovia', acc.highway ?? 'N/A'),
                        _line('Município', acc.city ?? 'N/A'),
                        _line('Local', acc.location ?? 'N/A'),
                        _line('Tipo', acc.typeOfAccident ?? 'N/A'),
                        _line('Mortes', (acc.death ?? 0).toString()),
                        _line('Feridos',
                            (acc.scoresVictims ?? 0).toString()),
                        const Divider(height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _line(String title, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2.0),
    child: Row(
      children: [
        Expanded(
          flex: 2,
          child: Text('$title:',
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        Expanded(flex: 3, child: Text(value)),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width - 24;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(width: 6),
        SizedBox(
          height: widget.height,
          width: width,
          child: Card(
            color: Colors.white,
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            clipBehavior: Clip.antiAlias,
            child: MapaInterativoPage(
              regionalPolygons: widget.regionalPolygons,
              selectedRegionNames: widget.selectedRegionNames,
              onRegionTap: widget.onRegionTap,
              activeMap: true,
              initialZoom: 8,
              minZoom: 8,
              maxZoom: 8,
              regionColors: widget.regionColors, // calculado no controller
              allowMultiSelect: false,
              showLegend: false,

              getFirebaseData: (cidade, _) async {
                final list = await widget.fetchCityData(cidade);
                return list;
              },
              onShowDialog: (context, region, dados) {
                final list = dados.cast<AccidentsData>();
                _showDialogCity(context: context, region: region, dados: list);
              },
            ),
          ),
        ),
      ],
    );
  }
}
