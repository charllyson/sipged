
import 'package:sipged/_widgets/map/base/map_flutter_data.dart';

class MapFlutterTypes {
  static const List<MapFlutterData> mapBase = [
    MapFlutterData(
      nome: 'OSM',
      url: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    ),
    MapFlutterData(
      nome: 'Satélite',
      url: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
    ),
    MapFlutterData(
      nome: 'Esri',
      url: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}',
    ),
    MapFlutterData(
      nome: 'Esri Topo',
      url: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/{z}/{y}/{x}',
    ),
    MapFlutterData(
      nome: 'Sem Mapa',
      url: '',
    ),
  ];
}