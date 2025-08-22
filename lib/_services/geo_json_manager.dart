import 'geo_json_service.dart';
import '../_datas/widgets/regional_geo_json_class.dart';

class GeoJsonManager {

  late List<PolygonChanged> regionalPolygons = [];


  Future<void> loadLimitsRegionalsDERAL() async {
    final geoJsonData = await GeoJsonService.loadPolygonsRegionsOfDERAL(
      assetPath: 'assets/geojson/limits/limites_regionais_der_al.geojson',
    );
    regionalPolygons
      ..clear()
      ..addAll(geoJsonData);
  }

}
