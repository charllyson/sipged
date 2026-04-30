import 'package:flutter/material.dart';

import 'package:sipged/_widgets/map/base/map_data.dart';

class MapTypes {
  static const List<MapData> mapBase = [
    MapData(
      nome: 'Padrão',
      description:
      'Equilíbrio entre ruas, bairros, referências urbanas e leitura geral.',
      url: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      previewUrl: 'https://tile.openstreetmap.org/12/1642/2304.png',
      icon: Icons.map_rounded,
      category: 'Essenciais',
      accentColor: Color(0xFF1976D2),
    ),
    MapData(
      nome: 'Satélite',
      description:
      'Imagem real do território para inspeção visual e contexto geográfico.',
      url:
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
      previewUrl:
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/12/2304/1642',
      icon: Icons.satellite_alt_rounded,
      category: 'Imagem',
      accentColor: Color(0xFF6D4C41),
    ),
    MapData(
      nome: 'Ruas',
      description: 'Base clara focada em vias, nomes urbanos e navegação.',
      url:
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}',
      previewUrl:
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/12/2304/1642',
      icon: Icons.alt_route_rounded,
      category: 'Operacional',
      accentColor: Color(0xFF1565C0),
    ),
    MapData(
      nome: 'Topográfico',
      description: 'Relevo, feições físicas e leitura territorial ampliada.',
      url:
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/{z}/{y}/{x}',
      previewUrl:
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/12/2304/1642',
      icon: Icons.terrain_rounded,
      category: 'Análise',
      accentColor: Color(0xFF558B2F),
    ),
    MapData(
      nome: 'Claro',
      description:
      'Visual limpo para sobrepor camadas, gráficos e dados temáticos.',
      url: 'https://basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
      previewUrl: 'https://basemaps.cartocdn.com/light_all/12/1642/2304.png',
      icon: Icons.light_mode_rounded,
      category: 'Dashboard',
      accentColor: Color(0xFF00ACC1),
    ),
    MapData(
      nome: 'Escuro',
      description:
      'Base escura para dashboards, contraste visual e painéis técnicos.',
      url: 'https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
      previewUrl: 'https://basemaps.cartocdn.com/dark_all/12/1642/2304.png',
      icon: Icons.dark_mode_rounded,
      category: 'Dashboard',
      accentColor: Color(0xFF7E57C2),
    ),
    MapData(
      nome: 'Voyager',
      description: 'Mapa moderno, colorido e legível para navegação urbana.',
      url:
      'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
      previewUrl:
      'https://basemaps.cartocdn.com/rastertiles/voyager/12/1642/2304.png',
      icon: Icons.travel_explore_rounded,
      category: 'Visual',
      accentColor: Color(0xFFFF8F00),
    ),
    MapData(
      nome: 'Sem mapa',
      description: 'Remove o mapa base e mantém apenas as camadas do SIPGED.',
      url: '',
      previewUrl: '',
      icon: Icons.layers_clear_rounded,
      category: 'Técnico',
      accentColor: Color(0xFF607D8B),
    ),
  ];
}