// lib/screens/sectors/traffic/dashboard/accidents_map_panel.dart
import 'package:diacritic/diacritic.dart';
import 'package:flutter/material.dart';
import 'package:siged/_blocs/sectors/transit/accidents/accidents_data.dart';
import 'package:siged/_blocs/sectors/transit/accidents/accidents_state.dart';
import 'package:siged/_widgets/background/background_cleaner.dart';
import 'package:siged/_widgets/map/polygon/polygon_changed.dart';
import 'package:siged/screens/sectors/traffic/dashboard/accident_map_section.dart';

// ===================== Painel do Mapa (lateral) =====================
class AccidentsMapPanel extends StatelessWidget {


  const AccidentsMapPanel({
    super.key,
    required this.state,
    required this.regionalPolygons,
    required this.regionColors,
  });

  final AccidentsState state;
  final List<PolygonChanged> regionalPolygons;
  final Map<String, Color> regionColors;


  Future<List<AccidentsData>> _fetchCityAccidentsFromState(
      String cityName) async {
    String _normalizeCity(String? nome) {
      if (nome == null) return '';
      final noAccent = removeDiacritics(nome);
      final noMultipleSpace =
      noAccent.replaceAll(RegExp(r'\s+'), ' ');
      return noMultipleSpace.trim().toUpperCase();
    }

    final key = _normalizeCity(cityName);
    return state.view
        .where((a) => _normalizeCity(a.city) == key)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const BackgroundClean(),
        AccidentsMapSection(
          regionalPolygons: regionalPolygons,
          selectedRegionNames: const [], // seleção é local no diálogo
          onRegionTap: (_) {}, // handled internamente pelo diálogo
          regionColors: regionColors,
          fetchCityData: _fetchCityAccidentsFromState,
          height: null, // ocupa todo o Expanded
        ),
      ],
    );
  }
}
