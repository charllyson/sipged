
import 'package:sipged/_widgets/map/base/map_data.dart';

class MapTypes {
  static const List<MapData> mapBase = [
    MapData(
      nome: 'OSM',
      url: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    ),
    MapData(
      nome: 'Satélite',
      url: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
    ),
    MapData(
      nome: 'Esri',
      url: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}',
    ),
    MapData(
      nome: 'Esri Topo',
      url: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/{z}/{y}/{x}',
    ),
    MapData(
      nome: 'Sem Mapa',
      url: '',
    ),
  ];
}