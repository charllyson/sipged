class MapBaseLayerModel {
  final String nome;
  final String url;

  MapBaseLayerModel({
    required this.nome,
    required this.url,
  });
}

class MapData {
  static final List<MapBaseLayerModel> mapBase = [
    MapBaseLayerModel(
      nome: 'OSM',
      url: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    ),
    MapBaseLayerModel(
      nome: 'Satélite',
      url: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
    ),
    MapBaseLayerModel(
      nome: 'Esri',
      url: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}',
    ),
    MapBaseLayerModel(
      nome: 'Esri Topo',
      url: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/{z}/{y}/{x}',
    ),
    MapBaseLayerModel(
      nome: 'Sem Mapa',
      url: '',
    ),

  ];
}
