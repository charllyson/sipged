import 'package:flutter/material.dart';

@immutable
class IconsChangeCatalog {
  final String key;
  final IconData icon;
  final String label;

  const IconsChangeCatalog({
    required this.key,
    required this.icon,
    required this.label,
  });
}

class IconsCatalog {
  IconsCatalog._();

  static final Map<String, IconsChangeCatalog> _icons = {
    'add_location_alt_outlined': const IconsChangeCatalog(
      key: 'add_location_alt_outlined',
      icon: Icons.add_location_alt_outlined,
      label: 'Adicionar localização',
    ),
    'agriculture': const IconsChangeCatalog(
      key: 'agriculture',
      icon: Icons.agriculture,
      label: 'Agro / Agricultura',
    ),
    'agriculture_outlined': const IconsChangeCatalog(
      key: 'agriculture_outlined',
      icon: Icons.agriculture_outlined,
      label: 'Agricultura',
    ),
    'air_outlined': const IconsChangeCatalog(
      key: 'air_outlined',
      icon: Icons.air_outlined,
      label: 'Ar',
    ),
    'alt_route': const IconsChangeCatalog(
      key: 'alt_route',
      icon: Icons.alt_route,
      label: 'Rota alternativa',
    ),
    'alt_route_outlined': const IconsChangeCatalog(
      key: 'alt_route_outlined',
      icon: Icons.alt_route_outlined,
      label: 'Rodovia / Rota',
    ),
    'anchor_outlined': const IconsChangeCatalog(
      key: 'anchor_outlined',
      icon: Icons.anchor_outlined,
      label: 'Âncora',
    ),
    'apartment_outlined': const IconsChangeCatalog(
      key: 'apartment_outlined',
      icon: Icons.apartment_outlined,
      label: 'Edificação',
    ),
    'architecture_outlined': const IconsChangeCatalog(
      key: 'architecture_outlined',
      icon: Icons.architecture_outlined,
      label: 'Arquitetura',
    ),
    'assured_workload_outlined': const IconsChangeCatalog(
      key: 'assured_workload_outlined',
      icon: Icons.assured_workload_outlined,
      label: 'Estrutura',
    ),
    'assist_walker_outlined': const IconsChangeCatalog(
      key: 'assist_walker_outlined',
      icon: Icons.assist_walker_outlined,
      label: 'Caminho',
    ),
    'attractions_outlined': const IconsChangeCatalog(
      key: 'attractions_outlined',
      icon: Icons.attractions_outlined,
      label: 'Atrações',
    ),
    'bar_chart_outlined': const IconsChangeCatalog(
      key: 'bar_chart_outlined',
      icon: Icons.bar_chart_outlined,
      label: 'Gráfico de barras',
    ),
    'battery_charging_full_outlined': const IconsChangeCatalog(
      key: 'battery_charging_full_outlined',
      icon: Icons.battery_charging_full_outlined,
      label: 'Energia',
    ),
    'beach_access_outlined': const IconsChangeCatalog(
      key: 'beach_access_outlined',
      icon: Icons.beach_access_outlined,
      label: 'Praia',
    ),
    'bolt_outlined': const IconsChangeCatalog(
      key: 'bolt_outlined',
      icon: Icons.bolt_outlined,
      label: 'Energia elétrica',
    ),
    'bridge_outlined': const IconsChangeCatalog(
      key: 'bridge_outlined',
      icon: Icons.brunch_dining_outlined,
      label: 'Ponte',
    ),
    'business_outlined': const IconsChangeCatalog(
      key: 'business_outlined',
      icon: Icons.business_outlined,
      label: 'Empresa',
    ),
    'cabin_outlined': const IconsChangeCatalog(
      key: 'cabin_outlined',
      icon: Icons.cabin_outlined,
      label: 'Cabana',
    ),
    'campaign_outlined': const IconsChangeCatalog(
      key: 'campaign_outlined',
      icon: Icons.campaign_outlined,
      label: 'Campanha',
    ),
    'category_outlined': const IconsChangeCatalog(
      key: 'category_outlined',
      icon: Icons.category_outlined,
      label: 'Categoria',
    ),
    'cell_tower_outlined': const IconsChangeCatalog(
      key: 'cell_tower_outlined',
      icon: Icons.cell_tower_outlined,
      label: 'Torre',
    ),
    'church_outlined': const IconsChangeCatalog(
      key: 'church_outlined',
      icon: Icons.church_outlined,
      label: 'Igreja',
    ),
    'cloud_outlined': const IconsChangeCatalog(
      key: 'cloud_outlined',
      icon: Icons.cloud_outlined,
      label: 'Nuvem',
    ),
    'co2_outlined': const IconsChangeCatalog(
      key: 'co2_outlined',
      icon: Icons.co2_outlined,
      label: 'CO2',
    ),
    'commute_outlined': const IconsChangeCatalog(
      key: 'commute_outlined',
      icon: Icons.commute_outlined,
      label: 'Transporte',
    ),
    'construction_outlined': const IconsChangeCatalog(
      key: 'construction_outlined',
      icon: Icons.construction_outlined,
      label: 'Construção',
    ),
    'crisis_alert_outlined': const IconsChangeCatalog(
      key: 'crisis_alert_outlined',
      icon: Icons.crisis_alert_outlined,
      label: 'Alerta',
    ),
    'directions_boat_filled_outlined': const IconsChangeCatalog(
      key: 'directions_boat_filled_outlined',
      icon: Icons.directions_boat_filled_outlined,
      label: 'Barco / Porto',
    ),
    'directions_bus_filled_outlined': const IconsChangeCatalog(
      key: 'directions_bus_filled_outlined',
      icon: Icons.directions_bus_filled_outlined,
      label: 'Linha de ônibus',
    ),
    'directions_bus_outlined': const IconsChangeCatalog(
      key: 'directions_bus_outlined',
      icon: Icons.directions_bus_outlined,
      label: 'Ônibus',
    ),
    'electric_bolt_outlined': const IconsChangeCatalog(
      key: 'electric_bolt_outlined',
      icon: Icons.electric_bolt_outlined,
      label: 'Energia elétrica',
    ),
    'electric_meter_outlined': const IconsChangeCatalog(
      key: 'electric_meter_outlined',
      icon: Icons.electric_meter_outlined,
      label: 'Medidor',
    ),
    'elderly': const IconsChangeCatalog(
      key: 'elderly',
      icon: Icons.elderly,
      label: 'Povos / Idoso',
    ),
    'emoji_transportation': const IconsChangeCatalog(
      key: 'emoji_transportation',
      icon: Icons.emoji_transportation,
      label: 'Transporte estadual',
    ),
    'engineering_outlined': const IconsChangeCatalog(
      key: 'engineering_outlined',
      icon: Icons.engineering_outlined,
      label: 'Engenharia',
    ),
    'factory_outlined': const IconsChangeCatalog(
      key: 'factory_outlined',
      icon: Icons.factory_outlined,
      label: 'Fábrica',
    ),
    'fire_hydrant_alt_outlined': const IconsChangeCatalog(
      key: 'fire_hydrant_alt_outlined',
      icon: Icons.fire_hydrant_alt_outlined,
      label: 'Hidrante',
    ),
    'flight_outlined': const IconsChangeCatalog(
      key: 'flight_outlined',
      icon: Icons.flight_outlined,
      label: 'Voo',
    ),
    'flood_outlined': const IconsChangeCatalog(
      key: 'flood_outlined',
      icon: Icons.flood_outlined,
      label: 'Inundação',
    ),
    'folder_open_outlined': const IconsChangeCatalog(
      key: 'folder_open_outlined',
      icon: Icons.folder_open_outlined,
      label: 'Pasta',
    ),
    'forest_outlined': const IconsChangeCatalog(
      key: 'forest_outlined',
      icon: Icons.forest_outlined,
      label: 'Floresta / Desmatamento',
    ),
    'foundation_outlined': const IconsChangeCatalog(
      key: 'foundation_outlined',
      icon: Icons.foundation_outlined,
      label: 'Fundação',
    ),
    'grass_outlined': const IconsChangeCatalog(
      key: 'grass_outlined',
      icon: Icons.grass_outlined,
      label: 'Vegetação',
    ),
    'grid_on_outlined': const IconsChangeCatalog(
      key: 'grid_on_outlined',
      icon: Icons.grid_on_outlined,
      label: 'Grade',
    ),
    'hexagon_outlined': const IconsChangeCatalog(
      key: 'hexagon_outlined',
      icon: Icons.hexagon_outlined,
      label: 'Polígono',
    ),
    'hiking_outlined': const IconsChangeCatalog(
      key: 'hiking_outlined',
      icon: Icons.hiking_outlined,
      label: 'Trilha',
    ),
    'hiking_sharp': const IconsChangeCatalog(
      key: 'hiking_sharp',
      icon: Icons.hiking_sharp,
      label: 'Arqueologia / Trilha',
    ),
    'history_toggle_off_outlined': const IconsChangeCatalog(
      key: 'history_toggle_off_outlined',
      icon: Icons.history_toggle_off_outlined,
      label: 'Histórico',
    ),
    'home_work_outlined': const IconsChangeCatalog(
      key: 'home_work_outlined',
      icon: Icons.home_work_outlined,
      label: 'Imóvel',
    ),
    'hub_outlined': const IconsChangeCatalog(
      key: 'hub_outlined',
      icon: Icons.hub_outlined,
      label: 'Hub',
    ),
    'landscape_outlined': const IconsChangeCatalog(
      key: 'landscape_outlined',
      icon: Icons.landscape_outlined,
      label: 'Paisagem / Bioma',
    ),
    'layers_outlined': const IconsChangeCatalog(
      key: 'layers_outlined',
      icon: Icons.layers_outlined,
      label: 'Camada',
    ),
    'link': const IconsChangeCatalog(
      key: 'link',
      icon: Icons.link,
      label: 'Link',
    ),
    'local_airport_outlined': const IconsChangeCatalog(
      key: 'local_airport_outlined',
      icon: Icons.local_airport_outlined,
      label: 'Aeroporto',
    ),
    'local_hospital_outlined': const IconsChangeCatalog(
      key: 'local_hospital_outlined',
      icon: Icons.local_hospital_outlined,
      label: 'Saúde / Hospital',
    ),
    'local_mall_outlined': const IconsChangeCatalog(
      key: 'local_mall_outlined',
      icon: Icons.local_mall_outlined,
      label: 'Economia / Comércio',
    ),
    'local_police_outlined': const IconsChangeCatalog(
      key: 'local_police_outlined',
      icon: Icons.local_police_outlined,
      label: 'Segurança',
    ),
    'location_city_outlined': const IconsChangeCatalog(
      key: 'location_city_outlined',
      icon: Icons.location_city_outlined,
      label: 'Cidade / Assistência',
    ),
    'location_on_outlined': const IconsChangeCatalog(
      key: 'location_on_outlined',
      icon: Icons.location_on_outlined,
      label: 'Ponto',
    ),
    'map_outlined': const IconsChangeCatalog(
      key: 'map_outlined',
      icon: Icons.map_outlined,
      label: 'Mapa',
    ),
    'mosque_outlined': const IconsChangeCatalog(
      key: 'mosque_outlined',
      icon: Icons.mosque_outlined,
      label: 'Mesquita',
    ),
    'multiple_stop_outlined': const IconsChangeCatalog(
      key: 'multiple_stop_outlined',
      icon: Icons.multiple_stop_outlined,
      label: 'Origem–Destino',
    ),
    'park_outlined': const IconsChangeCatalog(
      key: 'park_outlined',
      icon: Icons.park_outlined,
      label: 'Parque / Conservação',
    ),
    'people_alt_outlined': const IconsChangeCatalog(
      key: 'people_alt_outlined',
      icon: Icons.people_alt_outlined,
      label: 'População',
    ),
    'place_outlined': const IconsChangeCatalog(
      key: 'place_outlined',
      icon: Icons.place_outlined,
      label: 'Local',
    ),
    'polyline_outlined': const IconsChangeCatalog(
      key: 'polyline_outlined',
      icon: Icons.polyline_outlined,
      label: 'Linha',
    ),
    'precision_manufacturing_outlined': const IconsChangeCatalog(
      key: 'precision_manufacturing_outlined',
      icon: Icons.precision_manufacturing_outlined,
      label: 'Indústria',
    ),
    'radio_outlined': const IconsChangeCatalog(
      key: 'radio_outlined',
      icon: Icons.radio_outlined,
      label: 'Rádio',
    ),
    'route_outlined': const IconsChangeCatalog(
      key: 'route_outlined',
      icon: Icons.route_outlined,
      label: 'Rota',
    ),
    'sailing_outlined': const IconsChangeCatalog(
      key: 'sailing_outlined',
      icon: Icons.sailing_outlined,
      label: 'Náutico',
    ),
    'satellite_alt_outlined': const IconsChangeCatalog(
      key: 'satellite_alt_outlined',
      icon: Icons.satellite_alt_outlined,
      label: 'Satélite',
    ),
    'schema_outlined': const IconsChangeCatalog(
      key: 'schema_outlined',
      icon: Icons.schema_outlined,
      label: 'Esquema',
    ),
    'school_outlined': const IconsChangeCatalog(
      key: 'school_outlined',
      icon: Icons.school_outlined,
      label: 'Escola / Educação',
    ),
    'science_outlined': const IconsChangeCatalog(
      key: 'science_outlined',
      icon: Icons.science_outlined,
      label: 'Ciência',
    ),
    'shield_outlined': const IconsChangeCatalog(
      key: 'shield_outlined',
      icon: Icons.shield_outlined,
      label: 'Proteção',
    ),
    'signpost_outlined': const IconsChangeCatalog(
      key: 'signpost_outlined',
      icon: Icons.signpost_outlined,
      label: 'Sinalização',
    ),
    'solar_power_outlined': const IconsChangeCatalog(
      key: 'solar_power_outlined',
      icon: Icons.solar_power_outlined,
      label: 'Energia solar',
    ),
    'stacked_bar_chart_outlined': const IconsChangeCatalog(
      key: 'stacked_bar_chart_outlined',
      icon: Icons.stacked_bar_chart_outlined,
      label: 'PIB / Renda',
    ),
    'storefront_outlined': const IconsChangeCatalog(
      key: 'storefront_outlined',
      icon: Icons.storefront_outlined,
      label: 'Comércio',
    ),
    'table_view_outlined': const IconsChangeCatalog(
      key: 'table_view_outlined',
      icon: Icons.table_view_outlined,
      label: 'Tabela',
    ),
    'terrain_outlined': const IconsChangeCatalog(
      key: 'terrain_outlined',
      icon: Icons.terrain_outlined,
      label: 'Terreno / Minério / Deslizamento',
    ),
    'thunderstorm_outlined': const IconsChangeCatalog(
      key: 'thunderstorm_outlined',
      icon: Icons.thunderstorm_outlined,
      label: 'Pluviometria / Tempestade',
    ),
    'timeline': const IconsChangeCatalog(
      key: 'timeline',
      icon: Icons.timeline,
      label: 'Linha do tempo',
    ),
    'timeline_outlined': const IconsChangeCatalog(
      key: 'timeline_outlined',
      icon: Icons.timeline_outlined,
      label: 'Linha',
    ),
    'traffic_outlined': const IconsChangeCatalog(
      key: 'traffic_outlined',
      icon: Icons.traffic_outlined,
      label: 'Trânsito',
    ),
    'train_outlined': const IconsChangeCatalog(
      key: 'train_outlined',
      icon: Icons.train_outlined,
      label: 'Trem / Ferrovia',
    ),
    'transfer_within_a_station_outlined': const IconsChangeCatalog(
      key: 'transfer_within_a_station_outlined',
      icon: Icons.transfer_within_a_station_outlined,
      label: 'Hub de transporte',
    ),
    'tram_outlined': const IconsChangeCatalog(
      key: 'tram_outlined',
      icon: Icons.tram_outlined,
      label: 'Metrô / VLT',
    ),
    'warning_amber_outlined': const IconsChangeCatalog(
      key: 'warning_amber_outlined',
      icon: Icons.warning_amber_outlined,
      label: 'Vulnerabilidade / Alerta',
    ),
    'waves_outlined': const IconsChangeCatalog(
      key: 'waves_outlined',
      icon: Icons.waves_outlined,
      label: 'Inundação / Ondas',
    ),
    'water_drop_outlined': const IconsChangeCatalog(
      key: 'water_drop_outlined',
      icon: Icons.water_drop_outlined,
      label: 'Barragem / Gota',
    ),
    'water_outlined': const IconsChangeCatalog(
      key: 'water_outlined',
      icon: Icons.water_outlined,
      label: 'Rio / Água',
    ),
    'wb_sunny_outlined': const IconsChangeCatalog(
      key: 'wb_sunny_outlined',
      icon: Icons.wb_sunny_outlined,
      label: 'Sol',
    ),
    'warehouse_outlined': const IconsChangeCatalog(
      key: 'warehouse_outlined',
      icon: Icons.warehouse_outlined,
      label: 'Galpão',
    ),
    'work_outline': const IconsChangeCatalog(
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

  static List<IconsChangeCatalog> get options =>
      _icons.values.toList(growable: false);
}