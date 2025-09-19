import 'mapa_base_data.dart';

class MapBaseLayer {
  static final List<MapBaseData> mapBase = [
    MapBaseData(
      nome: 'OSM',
      url: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    ),
    MapBaseData(
      nome: 'Satélite',
      url: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
    ),
    MapBaseData(
      nome: 'Esri',
      url: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}',
    ),
    MapBaseData(
      nome: 'Esri Topo',
      url: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/{z}/{y}/{x}',
    ),
    MapBaseData(
      nome: 'Sem Mapa',
      url: '',
    ),

  ];
}
