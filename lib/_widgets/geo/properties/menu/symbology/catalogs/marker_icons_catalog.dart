import 'package:flutter/material.dart';

@immutable
class MarkerIconsOption {
  final String key;
  final IconData icon;
  final String label;

  const MarkerIconsOption({
    required this.key,
    required this.icon,
    required this.label,
  });
}

class IconsCatalog {
  IconsCatalog._();

  static final Map<String, MarkerIconsOption> _icons = {
    'add_location_alt_outlined': const MarkerIconsOption(
      key: 'add_location_alt_outlined',
      icon: Icons.add_location_alt_outlined,
      label: 'Adicionar localização',
    ),
    'agriculture': const MarkerIconsOption(
      key: 'agriculture',
      icon: Icons.agriculture,
      label: 'Agro / Agricultura',
    ),
    'agriculture_outlined': const MarkerIconsOption(
      key: 'agriculture_outlined',
      icon: Icons.agriculture_outlined,
      label: 'Agricultura',
    ),
    'air_outlined': const MarkerIconsOption(
      key: 'air_outlined',
      icon: Icons.air_outlined,
      label: 'Ar',
    ),
    'alt_route': const MarkerIconsOption(
      key: 'alt_route',
      icon: Icons.alt_route,
      label: 'Rota alternativa',
    ),
    'alt_route_outlined': const MarkerIconsOption(
      key: 'alt_route_outlined',
      icon: Icons.alt_route_outlined,
      label: 'Rodovia / Rota',
    ),
    'anchor_outlined': const MarkerIconsOption(
      key: 'anchor_outlined',
      icon: Icons.anchor_outlined,
      label: 'Âncora',
    ),
    'apartment_outlined': const MarkerIconsOption(
      key: 'apartment_outlined',
      icon: Icons.apartment_outlined,
      label: 'Edificação',
    ),
    'architecture_outlined': const MarkerIconsOption(
      key: 'architecture_outlined',
      icon: Icons.architecture_outlined,
      label: 'Arquitetura',
    ),
    'assured_workload_outlined': const MarkerIconsOption(
      key: 'assured_workload_outlined',
      icon: Icons.assured_workload_outlined,
      label: 'Estrutura',
    ),
    'assist_walker_outlined': const MarkerIconsOption(
      key: 'assist_walker_outlined',
      icon: Icons.assist_walker_outlined,
      label: 'Caminho',
    ),
    'attractions_outlined': const MarkerIconsOption(
      key: 'attractions_outlined',
      icon: Icons.attractions_outlined,
      label: 'Atrações',
    ),
    'bar_chart_outlined': const MarkerIconsOption(
      key: 'bar_chart_outlined',
      icon: Icons.bar_chart_outlined,
      label: 'Gráfico de barras',
    ),
    'battery_charging_full_outlined': const MarkerIconsOption(
      key: 'battery_charging_full_outlined',
      icon: Icons.battery_charging_full_outlined,
      label: 'Energia',
    ),
    'beach_access_outlined': const MarkerIconsOption(
      key: 'beach_access_outlined',
      icon: Icons.beach_access_outlined,
      label: 'Praia',
    ),
    'bolt_outlined': const MarkerIconsOption(
      key: 'bolt_outlined',
      icon: Icons.bolt_outlined,
      label: 'Energia elétrica',
    ),
    'bridge_outlined': const MarkerIconsOption(
      key: 'bridge_outlined',
      icon: Icons.brunch_dining_outlined,
      label: 'Ponte',
    ),
    'business_outlined': const MarkerIconsOption(
      key: 'business_outlined',
      icon: Icons.business_outlined,
      label: 'Empresa',
    ),
    'cabin_outlined': const MarkerIconsOption(
      key: 'cabin_outlined',
      icon: Icons.cabin_outlined,
      label: 'Cabana',
    ),
    'campaign_outlined': const MarkerIconsOption(
      key: 'campaign_outlined',
      icon: Icons.campaign_outlined,
      label: 'Campanha',
    ),
    'category_outlined': const MarkerIconsOption(
      key: 'category_outlined',
      icon: Icons.category_outlined,
      label: 'Categoria',
    ),
    'cell_tower_outlined': const MarkerIconsOption(
      key: 'cell_tower_outlined',
      icon: Icons.cell_tower_outlined,
      label: 'Torre',
    ),
    'church_outlined': const MarkerIconsOption(
      key: 'church_outlined',
      icon: Icons.church_outlined,
      label: 'Igreja',
    ),
    'cloud_outlined': const MarkerIconsOption(
      key: 'cloud_outlined',
      icon: Icons.cloud_outlined,
      label: 'Nuvem',
    ),
    'co2_outlined': const MarkerIconsOption(
      key: 'co2_outlined',
      icon: Icons.co2_outlined,
      label: 'CO2',
    ),
    'commute_outlined': const MarkerIconsOption(
      key: 'commute_outlined',
      icon: Icons.commute_outlined,
      label: 'Transporte',
    ),
    'construction_outlined': const MarkerIconsOption(
      key: 'construction_outlined',
      icon: Icons.construction_outlined,
      label: 'Construção',
    ),
    'crisis_alert_outlined': const MarkerIconsOption(
      key: 'crisis_alert_outlined',
      icon: Icons.crisis_alert_outlined,
      label: 'Alerta',
    ),
    'directions_boat_filled_outlined': const MarkerIconsOption(
      key: 'directions_boat_filled_outlined',
      icon: Icons.directions_boat_filled_outlined,
      label: 'Barco / Porto',
    ),
    'directions_bus_filled_outlined': const MarkerIconsOption(
      key: 'directions_bus_filled_outlined',
      icon: Icons.directions_bus_filled_outlined,
      label: 'Linha de ônibus',
    ),
    'directions_bus_outlined': const MarkerIconsOption(
      key: 'directions_bus_outlined',
      icon: Icons.directions_bus_outlined,
      label: 'Ônibus',
    ),
    'electric_bolt_outlined': const MarkerIconsOption(
      key: 'electric_bolt_outlined',
      icon: Icons.electric_bolt_outlined,
      label: 'Energia elétrica',
    ),
    'electric_meter_outlined': const MarkerIconsOption(
      key: 'electric_meter_outlined',
      icon: Icons.electric_meter_outlined,
      label: 'Medidor',
    ),
    'elderly': const MarkerIconsOption(
      key: 'elderly',
      icon: Icons.elderly,
      label: 'Povos / Idoso',
    ),
    'emoji_transportation': const MarkerIconsOption(
      key: 'emoji_transportation',
      icon: Icons.emoji_transportation,
      label: 'Transporte estadual',
    ),
    'engineering_outlined': const MarkerIconsOption(
      key: 'engineering_outlined',
      icon: Icons.engineering_outlined,
      label: 'Engenharia',
    ),
    'factory_outlined': const MarkerIconsOption(
      key: 'factory_outlined',
      icon: Icons.factory_outlined,
      label: 'Fábrica',
    ),
    'fire_hydrant_alt_outlined': const MarkerIconsOption(
      key: 'fire_hydrant_alt_outlined',
      icon: Icons.fire_hydrant_alt_outlined,
      label: 'Hidrante',
    ),
    'flight_outlined': const MarkerIconsOption(
      key: 'flight_outlined',
      icon: Icons.flight_outlined,
      label: 'Voo',
    ),
    'flood_outlined': const MarkerIconsOption(
      key: 'flood_outlined',
      icon: Icons.flood_outlined,
      label: 'Inundação',
    ),
    'folder_open_outlined': const MarkerIconsOption(
      key: 'folder_open_outlined',
      icon: Icons.folder_open_outlined,
      label: 'Pasta',
    ),
    'forest_outlined': const MarkerIconsOption(
      key: 'forest_outlined',
      icon: Icons.forest_outlined,
      label: 'Floresta / Desmatamento',
    ),
    'foundation_outlined': const MarkerIconsOption(
      key: 'foundation_outlined',
      icon: Icons.foundation_outlined,
      label: 'Fundação',
    ),
    'grass_outlined': const MarkerIconsOption(
      key: 'grass_outlined',
      icon: Icons.grass_outlined,
      label: 'Vegetação',
    ),
    'grid_on_outlined': const MarkerIconsOption(
      key: 'grid_on_outlined',
      icon: Icons.grid_on_outlined,
      label: 'Grade',
    ),
    'hexagon_outlined': const MarkerIconsOption(
      key: 'hexagon_outlined',
      icon: Icons.hexagon_outlined,
      label: 'Polígono',
    ),
    'hiking_outlined': const MarkerIconsOption(
      key: 'hiking_outlined',
      icon: Icons.hiking_outlined,
      label: 'Trilha',
    ),
    'hiking_sharp': const MarkerIconsOption(
      key: 'hiking_sharp',
      icon: Icons.hiking_sharp,
      label: 'Arqueologia / Trilha',
    ),
    'history_toggle_off_outlined': const MarkerIconsOption(
      key: 'history_toggle_off_outlined',
      icon: Icons.history_toggle_off_outlined,
      label: 'Histórico',
    ),
    'home_work_outlined': const MarkerIconsOption(
      key: 'home_work_outlined',
      icon: Icons.home_work_outlined,
      label: 'Imóvel',
    ),
    'hub_outlined': const MarkerIconsOption(
      key: 'hub_outlined',
      icon: Icons.hub_outlined,
      label: 'Hub',
    ),
    'landscape_outlined': const MarkerIconsOption(
      key: 'landscape_outlined',
      icon: Icons.landscape_outlined,
      label: 'Paisagem / Bioma',
    ),
    'layers_outlined': const MarkerIconsOption(
      key: 'layers_outlined',
      icon: Icons.layers_outlined,
      label: 'Camada',
    ),
    'link': const MarkerIconsOption(
      key: 'link',
      icon: Icons.link,
      label: 'Link',
    ),
    'local_airport_outlined': const MarkerIconsOption(
      key: 'local_airport_outlined',
      icon: Icons.local_airport_outlined,
      label: 'Aeroporto',
    ),
    'local_hospital_outlined': const MarkerIconsOption(
      key: 'local_hospital_outlined',
      icon: Icons.local_hospital_outlined,
      label: 'Saúde / Hospital',
    ),
    'local_mall_outlined': const MarkerIconsOption(
      key: 'local_mall_outlined',
      icon: Icons.local_mall_outlined,
      label: 'Economia / Comércio',
    ),
    'local_police_outlined': const MarkerIconsOption(
      key: 'local_police_outlined',
      icon: Icons.local_police_outlined,
      label: 'Segurança',
    ),
    'location_city_outlined': const MarkerIconsOption(
      key: 'location_city_outlined',
      icon: Icons.location_city_outlined,
      label: 'Cidade / Assistência',
    ),
    'location_on_outlined': const MarkerIconsOption(
      key: 'location_on_outlined',
      icon: Icons.location_on_outlined,
      label: 'Ponto',
    ),
    'map_outlined': const MarkerIconsOption(
      key: 'map_outlined',
      icon: Icons.map_outlined,
      label: 'Mapa',
    ),
    'mosque_outlined': const MarkerIconsOption(
      key: 'mosque_outlined',
      icon: Icons.mosque_outlined,
      label: 'Mesquita',
    ),
    'multiple_stop_outlined': const MarkerIconsOption(
      key: 'multiple_stop_outlined',
      icon: Icons.multiple_stop_outlined,
      label: 'Origem–Destino',
    ),
    'park_outlined': const MarkerIconsOption(
      key: 'park_outlined',
      icon: Icons.park_outlined,
      label: 'Parque / Conservação',
    ),
    'people_alt_outlined': const MarkerIconsOption(
      key: 'people_alt_outlined',
      icon: Icons.people_alt_outlined,
      label: 'População',
    ),
    'place_outlined': const MarkerIconsOption(
      key: 'place_outlined',
      icon: Icons.place_outlined,
      label: 'Local',
    ),
    'polyline_outlined': const MarkerIconsOption(
      key: 'polyline_outlined',
      icon: Icons.polyline_outlined,
      label: 'Linha',
    ),
    'precision_manufacturing_outlined': const MarkerIconsOption(
      key: 'precision_manufacturing_outlined',
      icon: Icons.precision_manufacturing_outlined,
      label: 'Indústria',
    ),
    'radio_outlined': const MarkerIconsOption(
      key: 'radio_outlined',
      icon: Icons.radio_outlined,
      label: 'Rádio',
    ),
    'route_outlined': const MarkerIconsOption(
      key: 'route_outlined',
      icon: Icons.route_outlined,
      label: 'Rota',
    ),
    'sailing_outlined': const MarkerIconsOption(
      key: 'sailing_outlined',
      icon: Icons.sailing_outlined,
      label: 'Náutico',
    ),
    'satellite_alt_outlined': const MarkerIconsOption(
      key: 'satellite_alt_outlined',
      icon: Icons.satellite_alt_outlined,
      label: 'Satélite',
    ),
    'schema_outlined': const MarkerIconsOption(
      key: 'schema_outlined',
      icon: Icons.schema_outlined,
      label: 'Esquema',
    ),
    'school_outlined': const MarkerIconsOption(
      key: 'school_outlined',
      icon: Icons.school_outlined,
      label: 'Escola / Educação',
    ),
    'science_outlined': const MarkerIconsOption(
      key: 'science_outlined',
      icon: Icons.science_outlined,
      label: 'Ciência',
    ),
    'shield_outlined': const MarkerIconsOption(
      key: 'shield_outlined',
      icon: Icons.shield_outlined,
      label: 'Proteção',
    ),
    'signpost_outlined': const MarkerIconsOption(
      key: 'signpost_outlined',
      icon: Icons.signpost_outlined,
      label: 'Sinalização',
    ),
    'solar_power_outlined': const MarkerIconsOption(
      key: 'solar_power_outlined',
      icon: Icons.solar_power_outlined,
      label: 'Energia solar',
    ),
    'stacked_bar_chart_outlined': const MarkerIconsOption(
      key: 'stacked_bar_chart_outlined',
      icon: Icons.stacked_bar_chart_outlined,
      label: 'PIB / Renda',
    ),
    'storefront_outlined': const MarkerIconsOption(
      key: 'storefront_outlined',
      icon: Icons.storefront_outlined,
      label: 'Comércio',
    ),
    'table_view_outlined': const MarkerIconsOption(
      key: 'table_view_outlined',
      icon: Icons.table_view_outlined,
      label: 'Tabela',
    ),
    'terrain_outlined': const MarkerIconsOption(
      key: 'terrain_outlined',
      icon: Icons.terrain_outlined,
      label: 'Terreno / Minério / Deslizamento',
    ),
    'thunderstorm_outlined': const MarkerIconsOption(
      key: 'thunderstorm_outlined',
      icon: Icons.thunderstorm_outlined,
      label: 'Pluviometria / Tempestade',
    ),
    'timeline': const MarkerIconsOption(
      key: 'timeline',
      icon: Icons.timeline,
      label: 'Linha do tempo',
    ),
    'timeline_outlined': const MarkerIconsOption(
      key: 'timeline_outlined',
      icon: Icons.timeline_outlined,
      label: 'Linha',
    ),
    'traffic_outlined': const MarkerIconsOption(
      key: 'traffic_outlined',
      icon: Icons.traffic_outlined,
      label: 'Trânsito',
    ),
    'train_outlined': const MarkerIconsOption(
      key: 'train_outlined',
      icon: Icons.train_outlined,
      label: 'Trem / Ferrovia',
    ),
    'transfer_within_a_station_outlined': const MarkerIconsOption(
      key: 'transfer_within_a_station_outlined',
      icon: Icons.transfer_within_a_station_outlined,
      label: 'Hub de transporte',
    ),
    'tram_outlined': const MarkerIconsOption(
      key: 'tram_outlined',
      icon: Icons.tram_outlined,
      label: 'Metrô / VLT',
    ),
    'warning_amber_outlined': const MarkerIconsOption(
      key: 'warning_amber_outlined',
      icon: Icons.warning_amber_outlined,
      label: 'Vulnerabilidade / Alerta',
    ),
    'waves_outlined': const MarkerIconsOption(
      key: 'waves_outlined',
      icon: Icons.waves_outlined,
      label: 'Inundação / Ondas',
    ),
    'water_drop_outlined': const MarkerIconsOption(
      key: 'water_drop_outlined',
      icon: Icons.water_drop_outlined,
      label: 'Barragem / Gota',
    ),
    'water_outlined': const MarkerIconsOption(
      key: 'water_outlined',
      icon: Icons.water_outlined,
      label: 'Rio / Água',
    ),
    'wb_sunny_outlined': const MarkerIconsOption(
      key: 'wb_sunny_outlined',
      icon: Icons.wb_sunny_outlined,
      label: 'Sol',
    ),
    'warehouse_outlined': const MarkerIconsOption(
      key: 'warehouse_outlined',
      icon: Icons.warehouse_outlined,
      label: 'Galpão',
    ),
    'work_outline': const MarkerIconsOption(
      key: 'work_outline',
      icon: Icons.work_outline,
      label: 'Trabalho',
    ),
  };

  static IconData iconFor(String key) {
    return _icons[key]?.icon ?? Icons.layers_outlined;
  }

  static String labelFor(String key) {
    return _icons[key]?.label ?? key;
  }

  static List<MarkerIconsOption> get options =>
      _icons.values.toList(growable: false);
}