import 'package:flutter/material.dart';

/// Configuração de uma camada exibida no drawer de camadas.
class PlanningLayers {
  final String id;
  final String title;
  final IconData icon;
  final Color color;
  final bool defaultVisible;
  final bool isGroup;
  final List<PlanningLayers> children;

  const PlanningLayers({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    this.defaultVisible = true,
    this.isGroup = false,
    this.children = const [],
  });
}

/// Lista padrão de camadas do módulo de planejamento.
const List<PlanningLayers> kEnvironmentLayers = [
  // ============================================================
  // LOCALIDADES
  // ============================================================
  PlanningLayers(
    id: 'localidades',
    title: 'LOCALIDADES',
    icon: Icons.folder_open_outlined,
    color: Color(0xFF374151),
    isGroup: true,
    defaultVisible: true,
    children: [],
  ),

  // ============================================================
  // OBRAS DE ARTE (a definir futuramente)
  // ============================================================
  PlanningLayers(
    id: 'obras_arte',
    title: 'OBRAS DE ARTE',
    icon: Icons.folder_open_outlined,
    color: Color(0xFF374151),
    isGroup: true,
    defaultVisible: false,
    children: [],
  ),

  // ============================================================
  // RECURSOS NATURAIS
  // ============================================================
  PlanningLayers(
    id: 'recursos_naturais',
    title: 'RECURSOS NATURAIS',
    icon: Icons.folder_open_outlined,
    color: Color(0xFF166534),
    isGroup: true,
    defaultVisible: false,
    children: [
      PlanningLayers(
        id: 'sigmine',
        title: 'Jazidas de Minério',
        icon: Icons.terrain_outlined,
        color: Color(0xFF2563EB),
        defaultVisible: false,
      ),
      PlanningLayers(
        id: 'land_use_cover',
        title: 'Biomas',
        icon: Icons.landscape_outlined,
        color: Color(0xFF22C55E),
        defaultVisible: false,
      ),
      PlanningLayers(
        id: 'deforestation',
        title: 'Desmatamento',
        icon: Icons.forest_outlined,
        color: Color(0xFFEF4444),
        defaultVisible: false,
      ),
    ],
  ),

  // ============================================================
  // UNIDADES (ENERGIA / AGROINDÚSTRIA)
  // ============================================================
  PlanningLayers(
    id: 'general_units',
    title: 'UNIDADES',
    icon: Icons.folder_open_outlined,
    color: Color(0xFF92400E),
    isGroup: true,
    defaultVisible: false,
    children: [
      PlanningLayers(
        id: 'units_energy',
        title: 'Usinas de Energia',
        icon: Icons.bolt_outlined,
        color: Color(0xFF16A34A),
        defaultVisible: false,
      ),
      PlanningLayers(
        id: 'units_agriculture',
        title: 'Agroindústria',
        icon: Icons.agriculture,
        color: Color(0xFF16A34A),
        defaultVisible: false,
      ),
    ],
  ),

  // ============================================================
  // HISTÓRIA E CULTURA
  // ============================================================
  PlanningLayers(
    id: 'historia_cultura',
    title: 'HISTÓRIA E CULTURA',
    icon: Icons.folder_open_outlined,
    color: Color(0xFF7C3AED),
    isGroup: true,
    defaultVisible: false,
    children: [
      PlanningLayers(
        id: 'ucs',
        title: 'Un. de Conservação',
        icon: Icons.park_outlined,
        color: Color(0xFF16A34A),
        defaultVisible: false,
      ),
      PlanningLayers(
        id: 'ti',
        title: 'Terras Indígenas',
        icon: Icons.elderly,
        color: Color(0xFFDC2626),
        defaultVisible: false,
      ),
      PlanningLayers(
        id: 'sitios_arqueologicos',
        title: 'Arqueológia',
        icon: Icons.hiking_sharp,
        color: Color(0xFF374151),
        defaultVisible: false,
      ),
    ],
  ),

  // ============================================================
  // TRANSPORTES (INCLUI RODOVIAS OSM)
  // ============================================================
  PlanningLayers(
    id: 'transports',
    title: 'TRANSPORTES',
    icon: Icons.folder_open_outlined,
    color: Color(0xFF2563EB),
    isGroup: true,
    defaultVisible: false,
    children: [
      PlanningLayers(
        id: 'federal_road',
        title: 'Rodovias Federais',
        icon: Icons.alt_route_outlined,
        color: Color(0xFFE53935),
        defaultVisible: false,
      ),
      PlanningLayers(
        id: 'state_road',
        title: 'Rodovias Estaduais',
        icon: Icons.emoji_transportation,
        color: Color(0xFFFFA726),
        defaultVisible: false,
      ),
      PlanningLayers(
        id: 'municipal_road',
        title: 'Rodovias Municipais',
        icon: Icons.alt_route,
        color: Color(0xFF3B82F6),
        defaultVisible: false,
      ),
      PlanningLayers(
        id: 'outras_rodovias',
        title: 'Outras Rodovias',
        icon: Icons.alt_route,
        color: Color(0xFF546E7A),
        defaultVisible: false,
      ),
      // ⚠️ IMPORTANTE: este id é usado no botão de corrente
      // para abrir o import vetorial de ferrovias.
      PlanningLayers(
        id: 'railways',
        title: 'Ferrovias',
        icon: Icons.train_outlined,
        color: Color(0xFF1E3A8A),
        defaultVisible: false,
      ),
      PlanningLayers(
        id: 'airport',
        title: 'Aeroportos',
        icon: Icons.local_airport_outlined,
        color: Color(0xFF1E3A8A),
        defaultVisible: false,
      ),
      PlanningLayers(
        id: 'harbor',
        title: 'Portos e Balsas',
        icon: Icons.directions_boat_filled_outlined,
        color: Color(0xFF1E3A8A),
        defaultVisible: false,
      ),
      PlanningLayers(
        id: 'urban_bus_lines',
        title: 'Linhas de Ônibus',
        icon: Icons.directions_bus_filled_outlined,
        color: Color(0xFF22C55E),
        defaultVisible: false,
      ),
      PlanningLayers(
        id: 'metro_lines',
        title: 'Metrô / VLT',
        icon: Icons.tram_outlined,
        color: Color(0xFF0EA5E9),
        defaultVisible: false,
      ),
      PlanningLayers(
        id: 'transport_hubs',
        title: 'Hubs de Transporte',
        icon: Icons.transfer_within_a_station_outlined,
        color: Color(0xFFF97316),
        defaultVisible: false,
      ),
      PlanningLayers(
        id: 'od_flows',
        title: 'Origem–Destino',
        icon: Icons.multiple_stop_outlined,
        color: Color(0xFFF97316),
        defaultVisible: false,
      ),
    ],
  ),

  // ============================================================
  // HIDROGRAFIA
  // ============================================================
  PlanningLayers(
    id: 'hidrografia',
    title: 'HIDROGRAFIA',
    icon: Icons.folder_open_outlined,
    color: Color(0xFF0284C7),
    isGroup: true,
    defaultVisible: false,
    children: [
      PlanningLayers(
        id: 'rain_gauge',
        title: 'Pluviometria (Estações ANA)',
        icon: Icons.thunderstorm_outlined,
        color: Color(0xFF0EA5E9),
        defaultVisible: true,
      ),
      PlanningLayers(
        id: 'weather_open_meteo',
        title: 'Clima (Open-Meteo)',
        icon: Icons.cloud_outlined,
        color: Color(0xFF38BDF8),
        defaultVisible: false,
      ),
      PlanningLayers(
        id: 'rives',
        title: 'Rios',
        icon: Icons.water_outlined,
        color: Color(0xFF0284C7),
        defaultVisible: false,
      ),
      PlanningLayers(
        id: 'dams',
        title: 'Açudes / Barragens',
        icon: Icons.water_drop_outlined,
        color: Color(0xFF0EA5E9),
        defaultVisible: false,
      ),
    ],
  ),

  // ============================================================
  // LIMITES TERRITORIAIS
  // ============================================================
  PlanningLayers(
    id: 'limite_territorial',
    title: 'LIMITE TERRITORIAL',
    icon: Icons.folder_open_outlined,
    color: Color(0xFF374151),
    isGroup: true,
    defaultVisible: false,
    children: [
      PlanningLayers(
        id: 'ibge_cities',
        title: 'Municípios',
        icon: Icons.location_city_outlined,
        color: Color(0xFF0891B2),
        defaultVisible: true,
      ),
      PlanningLayers(
        id: 'ibge_agregados',
        title: 'Indicadores (Agregados)',
        icon: Icons.bar_chart_outlined,
        color: Color(0xFFF97316),
        defaultVisible: false,
      ),
    ],
  ),

  // ============================================================
  // SOCIOECONÔMICO (ESTATÍSTICA / ECONOMIA)
  // ============================================================
  PlanningLayers(
    id: 'socioeconomico',
    title: 'SOCIOECONÔMICO',
    icon: Icons.folder_open_outlined,
    color: Color(0xFF6D28D9),
    isGroup: true,
    defaultVisible: false,
    children: [
      PlanningLayers(
        id: 'ibge_population',
        title: 'População e Densidade',
        icon: Icons.people_alt_outlined,
        color: Color(0xFF0EA5E9),
        defaultVisible: false,
      ),
      PlanningLayers(
        id: 'ibge_pib',
        title: 'PIB e Renda',
        icon: Icons.stacked_bar_chart_outlined,
        color: Color(0xFFF59E0B),
        defaultVisible: false,
      ),
      PlanningLayers(
        id: 'ibge_education',
        title: 'Educação (IDEB)',
        icon: Icons.school_outlined,
        color: Color(0xFF22C55E),
        defaultVisible: false,
      ),
      PlanningLayers(
        id: 'ibge_health',
        title: 'Saúde',
        icon: Icons.local_hospital_outlined,
        color: Color(0xFFEF4444),
        defaultVisible: false,
      ),
      PlanningLayers(
        id: 'ibge_social_vulnerability',
        title: 'Vulnerabilidade',
        icon: Icons.warning_amber_outlined,
        color: Color(0xFFFB7185),
        defaultVisible: false,
      ),
      PlanningLayers(
        id: 'economic_activity_heatmap',
        title: 'Econômia',
        icon: Icons.local_mall_outlined,
        color: Color(0xFF3B82F6),
        defaultVisible: false,
      ),
    ],
  ),

  // ============================================================
  // RISCO E RESILIÊNCIA
  // ============================================================
  PlanningLayers(
    id: 'risco_resiliencia',
    title: 'RISCO E RESILIÊNCIA',
    icon: Icons.folder_open_outlined,
    color: Color(0xFFDC2626),
    isGroup: true,
    defaultVisible: false,
    children: [
      PlanningLayers(
        id: 'flood_risk',
        title: 'Inundação',
        icon: Icons.waves_outlined,
        color: Color(0xFF0EA5E9),
        defaultVisible: false,
      ),
      PlanningLayers(
        id: 'landslide_risk',
        title: 'Deslizamento',
        icon: Icons.terrain_outlined,
        color: Color(0xFFFB923C),
        defaultVisible: false,
      ),
      PlanningLayers(
        id: 'critical_events_history',
        title: 'Eventos Críticos',
        icon: Icons.history_toggle_off_outlined,
        color: Color(0xFF6B7280),
        defaultVisible: false,
      ),
    ],
  ),

  // ============================================================
  // INFRAESTRUTURA (EQUIPAMENTOS PÚBLICOS)
  // ============================================================
  PlanningLayers(
    id: 'infra_urbana',
    title: 'INFRAESTRUTURA',
    icon: Icons.folder_open_outlined,
    color: Color(0xFF059669),
    isGroup: true,
    defaultVisible: false,
    children: [
      PlanningLayers(
        id: 'public_schools',
        title: 'Escolas',
        icon: Icons.school_outlined,
        color: Color(0xFF22C55E),
        defaultVisible: false,
      ),
      PlanningLayers(
        id: 'health_units',
        title: 'Saúde',
        icon: Icons.local_hospital_outlined,
        color: Color(0xFFEF4444),
        defaultVisible: false,
      ),
      PlanningLayers(
        id: 'security_units',
        title: 'Segurança',
        icon: Icons.local_police_outlined,
        color: Color(0xFF3B82F6),
        defaultVisible: false,
      ),
      PlanningLayers(
        id: 'urban_equipment',
        title: 'Assistência',
        icon: Icons.location_city_outlined,
        color: Color(0xFF8B5CF6),
        defaultVisible: false,
      ),
    ],
  ),

  // ============================================================
  // MAPAS DE BASE
  // ============================================================
  PlanningLayers(
    id: 'base_normal',
    title: 'Mapa de Ruas',
    icon: Icons.map_outlined,
    color: Color(0xFF4B5563),
    defaultVisible: false,
  ),
  PlanningLayers(
    id: 'base_satellite',
    title: 'Mapa Satélite',
    icon: Icons.satellite_alt_outlined,
    color: Color(0xFF4B5563),
    defaultVisible: false,
  ),
];
