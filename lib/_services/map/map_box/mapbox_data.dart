// lib/_widgets/map/map_box/mapbox_data.dart

/// Dados de um marcador no Mapbox.
class MapboxData {
  final double lon;
  final double lat;

  /// Cor do marcador em formato hex (#rrggbb ou #rrggbbaa).
  final String colorHex;

  /// Label usado em popup simples.
  final String? label;

  /// ID extra para associar com objetos do Flutter (ex: id da OAE, contrato).
  final String? idExtra;

  const MapboxData({
    required this.lon,
    required this.lat,
    this.colorHex = '#ff3333',
    this.label,
    this.idExtra,
  });

  Map<String, dynamic> toJson() => {
    'lon': lon,
    'lat': lat,
    'color': colorHex,
    'label': label ?? '',
    'idExtra': idExtra ?? '',
  };
}

/// Opção de estilo do mapa para o "troca-estilo" interno.
class MapboxStyleOption {
  /// Identificador interno (ex: "streets", "satellite").
  final String id;

  /// Nome legível (ex: "Rúas", "Satélite").
  final String name;

  /// URL do estilo (ex: "mapbox://styles/mapbox/streets-v12").
  final String styleUrl;

  const MapboxStyleOption({
    required this.id,
    required this.name,
    required this.styleUrl,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'styleUrl': styleUrl,
  };
}

/// Configuração geral do mapa Mapbox 3D.
class MapboxMapConfig {
  final String accessToken;

  /// Estilo principal do mapa.
  ///
  /// Ex: 'mapbox://styles/mapbox/streets-v12'
  final String styleUrl;

  /// Lista de estilos alternativos para o seletor interno (botões no mapa).
  ///
  /// Se vazia, o HTML usará alguns padrões do Mapbox.
  final List<MapboxStyleOption> alternateStyles;

  /// Índice do estilo inicial na lista [alternateStyles].
  ///
  /// Se estiver fora do range, usa [styleUrl].
  final int initialStyleIndex;

  /// Centro da câmera.
  final double centerLon;
  final double centerLat;

  /// Zoom inicial.
  final double zoom;

  /// Inclinação da câmera (0 = top-down, 60+ = mais 3D).
  final double pitch;

  /// Rotação/bearing inicial (0 = Norte para cima).
  final double bearing;

  /// Zoom mínimo e máximo permitidos.
  final double? minZoom;
  final double? maxZoom;

  /// Exagero vertical do terreno 3D.
  ///
  /// 1.0 = natural, 2.0 = duas vezes mais alto, etc.
  final double terrainExaggeration;

  /// Ativa terreno 3D (raster-dem do Mapbox).
  final bool enableTerrain;

  /// Ativa "fog" / atmosfera (efeito visual).
  final bool enableFog;

  /// Ativa camada de prédios 3D (extrude buildings).
  final bool enable3DBuildings;

  /// Mostrar controles nativos do Mapbox (zoom, rotate, compass).
  final bool showNavigationControl;

  /// Mostrar controle de escala.
  final bool showScaleControl;

  /// Mostrar controle de fullscreen (onde suportado).
  final bool showFullscreenControl;

  /// Permitir rotação via gestos.
  final bool enableRotateGestures;

  /// Permitir zoom por scroll.
  final bool enableScrollZoom;

  /// Permitir zoom por double-click.
  final bool enableDoubleClickZoom;

  /// Permitir arrastar o mapa.
  final bool enableDragPan;

  /// Marcadores a serem exibidos.
  final List<MapboxData> markers;

  const MapboxMapConfig({
    required this.accessToken,
    required this.centerLon,
    required this.centerLat,
    required this.zoom,
    this.styleUrl = 'mapbox://styles/mapbox/streets-v12',
    this.alternateStyles = const [],
    this.initialStyleIndex = 0,
    this.pitch = 0,
    this.bearing = 0,
    this.minZoom,
    this.maxZoom,
    this.terrainExaggeration = 1.5,
    this.enableTerrain = true,
    this.enableFog = true,
    this.enable3DBuildings = false,
    this.showNavigationControl = true,
    this.showScaleControl = false,
    this.showFullscreenControl = false,
    this.enableRotateGestures = true,
    this.enableScrollZoom = true,
    this.enableDoubleClickZoom = true,
    this.enableDragPan = true,
    this.markers = const [],
  });

  Map<String, dynamic> toJsonForHtml() => {
    'accessToken': accessToken,
    'styleUrl': styleUrl,
    'alternateStyles': alternateStyles.map((s) => s.toJson()).toList(),
    'initialStyleIndex': initialStyleIndex,
    'centerLon': centerLon,
    'centerLat': centerLat,
    'zoom': zoom,
    'pitch': pitch,
    'bearing': bearing,
    'minZoom': minZoom,
    'maxZoom': maxZoom,
    'terrainExaggeration': terrainExaggeration,
    'enableTerrain': enableTerrain,
    'enableFog': enableFog,
    'enable3DBuildings': enable3DBuildings,
    'showNavigationControl': showNavigationControl,
    'showScaleControl': showScaleControl,
    'showFullscreenControl': showFullscreenControl,
    'enableRotateGestures': enableRotateGestures,
    'enableScrollZoom': enableScrollZoom,
    'enableDoubleClickZoom': enableDoubleClickZoom,
    'enableDragPan': enableDragPan,
    'markers': markers.map((m) => m.toJson()).toList(),
  };
}

class MapboxMarkerTapEvent {
  final String viewId;
  final String? idExtra;
  final String? label;
  final double lon;
  final double lat;

  const MapboxMarkerTapEvent({
    required this.viewId,
    this.idExtra,
    this.label,
    required this.lon,
    required this.lat,
  });
}
