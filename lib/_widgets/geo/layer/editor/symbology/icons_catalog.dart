import 'package:flutter/material.dart';

class IconsOption {
  final String key;
  final IconData icon;
  final String label;

  const IconsOption({
    required this.key,
    required this.icon,
    required this.label,
  });
}

class IconsCatalog {
  IconsCatalog._();

  static final Map<String, IconsOption> _icons = {
    'add_location_alt_outlined': const IconsOption(
      key: 'add_location_alt_outlined',
      icon: Icons.add_location_alt_outlined,
      label: 'Adicionar localização',
    ),
    'agriculture': const IconsOption(
      key: 'agriculture',
      icon: Icons.agriculture,
      label: 'Agro / Agricultura',
    ),
    'agriculture_outlined': const IconsOption(
      key: 'agriculture_outlined',
      icon: Icons.agriculture_outlined,
      label: 'Agricultura',
    ),
    'air_outlined': const IconsOption(
      key: 'air_outlined',
      icon: Icons.air_outlined,
      label: 'Ar',
    ),
    'alt_route': const IconsOption(
      key: 'alt_route',
      icon: Icons.alt_route,
      label: 'Rota alternativa',
    ),
    'alt_route_outlined': const IconsOption(
      key: 'alt_route_outlined',
      icon: Icons.alt_route_outlined,
      label: 'Rodovia / Rota',
    ),
    'anchor_outlined': const IconsOption(
      key: 'anchor_outlined',
      icon: Icons.anchor_outlined,
      label: 'Âncora',
    ),
    'apartment_outlined': const IconsOption(
      key: 'apartment_outlined',
      icon: Icons.apartment_outlined,
      label: 'Edificação',
    ),
    'architecture_outlined': const IconsOption(
      key: 'architecture_outlined',
      icon: Icons.architecture_outlined,
      label: 'Arquitetura',
    ),
    'assured_workload_outlined': const IconsOption(
      key: 'assured_workload_outlined',
      icon: Icons.assured_workload_outlined,
      label: 'Estrutura',
    ),
    'assist_walker_outlined': const IconsOption(
      key: 'assist_walker_outlined',
      icon: Icons.assist_walker_outlined,
      label: 'Caminho',
    ),
    'attractions_outlined': const IconsOption(
      key: 'attractions_outlined',
      icon: Icons.attractions_outlined,
      label: 'Atrações',
    ),
    'bar_chart_outlined': const IconsOption(
      key: 'bar_chart_outlined',
      icon: Icons.bar_chart_outlined,
      label: 'Gráfico de barras',
    ),
    'battery_charging_full_outlined': const IconsOption(
      key: 'battery_charging_full_outlined',
      icon: Icons.battery_charging_full_outlined,
      label: 'Energia',
    ),
    'beach_access_outlined': const IconsOption(
      key: 'beach_access_outlined',
      icon: Icons.beach_access_outlined,
      label: 'Praia',
    ),
    'bolt_outlined': const IconsOption(
      key: 'bolt_outlined',
      icon: Icons.bolt_outlined,
      label: 'Energia elétrica',
    ),
    'bridge_outlined': const IconsOption(
      key: 'bridge_outlined',
      icon: Icons.brunch_dining_outlined,
      label: 'Ponte',
    ),
    'business_outlined': const IconsOption(
      key: 'business_outlined',
      icon: Icons.business_outlined,
      label: 'Empresa',
    ),
    'cabin_outlined': const IconsOption(
      key: 'cabin_outlined',
      icon: Icons.cabin_outlined,
      label: 'Cabana',
    ),
    'campaign_outlined': const IconsOption(
      key: 'campaign_outlined',
      icon: Icons.campaign_outlined,
      label: 'Campanha',
    ),
    'category_outlined': const IconsOption(
      key: 'category_outlined',
      icon: Icons.category_outlined,
      label: 'Categoria',
    ),
    'cell_tower_outlined': const IconsOption(
      key: 'cell_tower_outlined',
      icon: Icons.cell_tower_outlined,
      label: 'Torre',
    ),
    'church_outlined': const IconsOption(
      key: 'church_outlined',
      icon: Icons.church_outlined,
      label: 'Igreja',
    ),
    'cloud_outlined': const IconsOption(
      key: 'cloud_outlined',
      icon: Icons.cloud_outlined,
      label: 'Nuvem',
    ),
    'co2_outlined': const IconsOption(
      key: 'co2_outlined',
      icon: Icons.co2_outlined,
      label: 'CO2',
    ),
    'commute_outlined': const IconsOption(
      key: 'commute_outlined',
      icon: Icons.commute_outlined,
      label: 'Transporte',
    ),
    'construction_outlined': const IconsOption(
      key: 'construction_outlined',
      icon: Icons.construction_outlined,
      label: 'Construção',
    ),
    'crisis_alert_outlined': const IconsOption(
      key: 'crisis_alert_outlined',
      icon: Icons.crisis_alert_outlined,
      label: 'Alerta',
    ),
    'directions_boat_filled_outlined': const IconsOption(
      key: 'directions_boat_filled_outlined',
      icon: Icons.directions_boat_filled_outlined,
      label: 'Barco / Porto',
    ),
    'directions_bus_filled_outlined': const IconsOption(
      key: 'directions_bus_filled_outlined',
      icon: Icons.directions_bus_filled_outlined,
      label: 'Linha de ônibus',
    ),
    'directions_bus_outlined': const IconsOption(
      key: 'directions_bus_outlined',
      icon: Icons.directions_bus_outlined,
      label: 'Ônibus',
    ),
    'electric_bolt_outlined': const IconsOption(
      key: 'electric_bolt_outlined',
      icon: Icons.electric_bolt_outlined,
      label: 'Energia elétrica',
    ),
    'electric_meter_outlined': const IconsOption(
      key: 'electric_meter_outlined',
      icon: Icons.electric_meter_outlined,
      label: 'Medidor',
    ),
    'elderly': const IconsOption(
      key: 'elderly',
      icon: Icons.elderly,
      label: 'Povos / Idoso',
    ),
    'emoji_transportation': const IconsOption(
      key: 'emoji_transportation',
      icon: Icons.emoji_transportation,
      label: 'Transporte estadual',
    ),
    'engineering_outlined': const IconsOption(
      key: 'engineering_outlined',
      icon: Icons.engineering_outlined,
      label: 'Engenharia',
    ),
    'factory_outlined': const IconsOption(
      key: 'factory_outlined',
      icon: Icons.factory_outlined,
      label: 'Fábrica',
    ),
    'fire_hydrant_alt_outlined': const IconsOption(
      key: 'fire_hydrant_alt_outlined',
      icon: Icons.fire_hydrant_alt_outlined,
      label: 'Hidrante',
    ),
    'flight_outlined': const IconsOption(
      key: 'flight_outlined',
      icon: Icons.flight_outlined,
      label: 'Voo',
    ),
    'flood_outlined': const IconsOption(
      key: 'flood_outlined',
      icon: Icons.flood_outlined,
      label: 'Inundação',
    ),
    'folder_open_outlined': const IconsOption(
      key: 'folder_open_outlined',
      icon: Icons.folder_open_outlined,
      label: 'Pasta',
    ),
    'forest_outlined': const IconsOption(
      key: 'forest_outlined',
      icon: Icons.forest_outlined,
      label: 'Floresta / Desmatamento',
    ),
    'foundation_outlined': const IconsOption(
      key: 'foundation_outlined',
      icon: Icons.foundation_outlined,
      label: 'Fundação',
    ),
    'grass_outlined': const IconsOption(
      key: 'grass_outlined',
      icon: Icons.grass_outlined,
      label: 'Vegetação',
    ),
    'grid_on_outlined': const IconsOption(
      key: 'grid_on_outlined',
      icon: Icons.grid_on_outlined,
      label: 'Grade',
    ),
    'hexagon_outlined': const IconsOption(
      key: 'hexagon_outlined',
      icon: Icons.hexagon_outlined,
      label: 'Polígono',
    ),
    'hiking_outlined': const IconsOption(
      key: 'hiking_outlined',
      icon: Icons.hiking_outlined,
      label: 'Trilha',
    ),
    'hiking_sharp': const IconsOption(
      key: 'hiking_sharp',
      icon: Icons.hiking_sharp,
      label: 'Arqueologia / Trilha',
    ),
    'history_toggle_off_outlined': const IconsOption(
      key: 'history_toggle_off_outlined',
      icon: Icons.history_toggle_off_outlined,
      label: 'Histórico',
    ),
    'home_work_outlined': const IconsOption(
      key: 'home_work_outlined',
      icon: Icons.home_work_outlined,
      label: 'Imóvel',
    ),
    'hub_outlined': const IconsOption(
      key: 'hub_outlined',
      icon: Icons.hub_outlined,
      label: 'Hub',
    ),
    'landscape_outlined': const IconsOption(
      key: 'landscape_outlined',
      icon: Icons.landscape_outlined,
      label: 'Paisagem / Bioma',
    ),
    'layers_outlined': const IconsOption(
      key: 'layers_outlined',
      icon: Icons.layers_outlined,
      label: 'Camada',
    ),
    'link': const IconsOption(
      key: 'link',
      icon: Icons.link,
      label: 'Link',
    ),
    'local_airport_outlined': const IconsOption(
      key: 'local_airport_outlined',
      icon: Icons.local_airport_outlined,
      label: 'Aeroporto',
    ),
    'local_hospital_outlined': const IconsOption(
      key: 'local_hospital_outlined',
      icon: Icons.local_hospital_outlined,
      label: 'Saúde / Hospital',
    ),
    'local_mall_outlined': const IconsOption(
      key: 'local_mall_outlined',
      icon: Icons.local_mall_outlined,
      label: 'Economia / Comércio',
    ),
    'local_police_outlined': const IconsOption(
      key: 'local_police_outlined',
      icon: Icons.local_police_outlined,
      label: 'Segurança',
    ),
    'location_city_outlined': const IconsOption(
      key: 'location_city_outlined',
      icon: Icons.location_city_outlined,
      label: 'Cidade / Assistência',
    ),
    'location_on_outlined': const IconsOption(
      key: 'location_on_outlined',
      icon: Icons.location_on_outlined,
      label: 'Ponto',
    ),
    'map_outlined': const IconsOption(
      key: 'map_outlined',
      icon: Icons.map_outlined,
      label: 'Mapa',
    ),
    'mosque_outlined': const IconsOption(
      key: 'mosque_outlined',
      icon: Icons.mosque_outlined,
      label: 'Mesquita',
    ),
    'multiple_stop_outlined': const IconsOption(
      key: 'multiple_stop_outlined',
      icon: Icons.multiple_stop_outlined,
      label: 'Origem–Destino',
    ),
    'park_outlined': const IconsOption(
      key: 'park_outlined',
      icon: Icons.park_outlined,
      label: 'Parque / Conservação',
    ),
    'people_alt_outlined': const IconsOption(
      key: 'people_alt_outlined',
      icon: Icons.people_alt_outlined,
      label: 'População',
    ),
    'place_outlined': const IconsOption(
      key: 'place_outlined',
      icon: Icons.place_outlined,
      label: 'Local',
    ),
    'polyline_outlined': const IconsOption(
      key: 'polyline_outlined',
      icon: Icons.polyline_outlined,
      label: 'Linha',
    ),
    'precision_manufacturing_outlined': const IconsOption(
      key: 'precision_manufacturing_outlined',
      icon: Icons.precision_manufacturing_outlined,
      label: 'Indústria',
    ),
    'radio_outlined': const IconsOption(
      key: 'radio_outlined',
      icon: Icons.radio_outlined,
      label: 'Rádio',
    ),
    'route_outlined': const IconsOption(
      key: 'route_outlined',
      icon: Icons.route_outlined,
      label: 'Rota',
    ),
    'sailing_outlined': const IconsOption(
      key: 'sailing_outlined',
      icon: Icons.sailing_outlined,
      label: 'Náutico',
    ),
    'satellite_alt_outlined': const IconsOption(
      key: 'satellite_alt_outlined',
      icon: Icons.satellite_alt_outlined,
      label: 'Satélite',
    ),
    'schema_outlined': const IconsOption(
      key: 'schema_outlined',
      icon: Icons.schema_outlined,
      label: 'Esquema',
    ),
    'school_outlined': const IconsOption(
      key: 'school_outlined',
      icon: Icons.school_outlined,
      label: 'Escola / Educação',
    ),
    'science_outlined': const IconsOption(
      key: 'science_outlined',
      icon: Icons.science_outlined,
      label: 'Ciência',
    ),
    'shield_outlined': const IconsOption(
      key: 'shield_outlined',
      icon: Icons.shield_outlined,
      label: 'Proteção',
    ),
    'signpost_outlined': const IconsOption(
      key: 'signpost_outlined',
      icon: Icons.signpost_outlined,
      label: 'Sinalização',
    ),
    'solar_power_outlined': const IconsOption(
      key: 'solar_power_outlined',
      icon: Icons.solar_power_outlined,
      label: 'Energia solar',
    ),
    'stacked_bar_chart_outlined': const IconsOption(
      key: 'stacked_bar_chart_outlined',
      icon: Icons.stacked_bar_chart_outlined,
      label: 'PIB / Renda',
    ),
    'storefront_outlined': const IconsOption(
      key: 'storefront_outlined',
      icon: Icons.storefront_outlined,
      label: 'Comércio',
    ),
    'table_view_outlined': const IconsOption(
      key: 'table_view_outlined',
      icon: Icons.table_view_outlined,
      label: 'Tabela',
    ),
    'terrain_outlined': const IconsOption(
      key: 'terrain_outlined',
      icon: Icons.terrain_outlined,
      label: 'Terreno / Minério / Deslizamento',
    ),
    'thunderstorm_outlined': const IconsOption(
      key: 'thunderstorm_outlined',
      icon: Icons.thunderstorm_outlined,
      label: 'Pluviometria / Tempestade',
    ),
    'timeline': const IconsOption(
      key: 'timeline',
      icon: Icons.timeline,
      label: 'Linha do tempo',
    ),
    'timeline_outlined': const IconsOption(
      key: 'timeline_outlined',
      icon: Icons.timeline_outlined,
      label: 'Linha',
    ),
    'traffic_outlined': const IconsOption(
      key: 'traffic_outlined',
      icon: Icons.traffic_outlined,
      label: 'Trânsito',
    ),
    'train_outlined': const IconsOption(
      key: 'train_outlined',
      icon: Icons.train_outlined,
      label: 'Trem / Ferrovia',
    ),
    'transfer_within_a_station_outlined': const IconsOption(
      key: 'transfer_within_a_station_outlined',
      icon: Icons.transfer_within_a_station_outlined,
      label: 'Hub de transporte',
    ),
    'tram_outlined': const IconsOption(
      key: 'tram_outlined',
      icon: Icons.tram_outlined,
      label: 'Metrô / VLT',
    ),
    'warning_amber_outlined': const IconsOption(
      key: 'warning_amber_outlined',
      icon: Icons.warning_amber_outlined,
      label: 'Vulnerabilidade / Alerta',
    ),
    'waves_outlined': const IconsOption(
      key: 'waves_outlined',
      icon: Icons.waves_outlined,
      label: 'Inundação / Ondas',
    ),
    'water_drop_outlined': const IconsOption(
      key: 'water_drop_outlined',
      icon: Icons.water_drop_outlined,
      label: 'Barragem / Gota',
    ),
    'water_outlined': const IconsOption(
      key: 'water_outlined',
      icon: Icons.water_outlined,
      label: 'Rio / Água',
    ),
    'wb_sunny_outlined': const IconsOption(
      key: 'wb_sunny_outlined',
      icon: Icons.wb_sunny_outlined,
      label: 'Sol',
    ),
    'warehouse_outlined': const IconsOption(
      key: 'warehouse_outlined',
      icon: Icons.warehouse_outlined,
      label: 'Galpão',
    ),
    'work_outline': const IconsOption(
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

  static List<IconsOption> get options =>
      _icons.values.toList(growable: false);
}

class LayerIcon extends StatefulWidget {
  final List<IconsOption>? options;
  final String? selectedKey;
  final ValueChanged<String> onChanged;
  final Color previewColor;
  final double itemSize;
  final int columns;
  final String title;
  final bool showSearch;
  final double maxGridHeight;

  const LayerIcon({
    super.key,
    this.options,
    required this.selectedKey,
    required this.onChanged,
    this.previewColor = Colors.blue,
    this.itemSize = 52,
    this.columns = 6,
    this.title = 'Ícone',
    this.showSearch = true,
    this.maxGridHeight = 320,
  });

  @override
  State<LayerIcon> createState() => _LayerIconState();
}

class _LayerIconState extends State<LayerIcon> {
  late String? _selectedKey;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  List<IconsOption> get _sourceOptions =>
      widget.options ?? IconsCatalog.options;

  List<IconsOption> get _filteredOptions {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _sourceOptions;

    return _sourceOptions.where((option) {
      return option.label.toLowerCase().contains(q) ||
          option.key.toLowerCase().contains(q);
    }).toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _selectedKey = widget.selectedKey;
    _searchController.addListener(() {
      if (!mounted) return;
      setState(() => _query = _searchController.text);
    });
  }

  @override
  void didUpdateWidget(covariant LayerIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedKey != widget.selectedKey) {
      _selectedKey = widget.selectedKey;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int _resolveColumns(double maxWidth) {
    final desired = widget.columns;
    final calculated = (maxWidth / (widget.itemSize + 10)).floor();

    if (calculated < 2) return 2;
    if (calculated > desired) return desired;
    return calculated;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredOptions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        if (widget.showSearch) ...[
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Buscar ícone',
              prefixIcon: const Icon(Icons.search, size: 18),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                onPressed: () => _searchController.clear(),
                icon: const Icon(Icons.close, size: 18),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        SizedBox(
          height: widget.maxGridHeight,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: filtered.isEmpty
                ? const Center(
              child: Text('Nenhum ícone encontrado.'),
            )
                : LayoutBuilder(
              builder: (context, constraints) {
                const spacing = 10.0;
                final crossAxisCount =
                _resolveColumns(constraints.maxWidth);
                final totalSpacing =
                    (crossAxisCount - 1) * spacing;
                final tileWidth =
                ((constraints.maxWidth - totalSpacing) /
                    crossAxisCount)
                    .clamp(40.0, widget.itemSize);

                return Scrollbar(
                  thumbVisibility: true,
                  child: GridView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: filtered.length,
                    gridDelegate:
                    SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: spacing,
                      crossAxisSpacing: spacing,
                      childAspectRatio: 1,
                      mainAxisExtent: tileWidth,
                    ),
                    itemBuilder: (context, index) {
                      final option = filtered[index];
                      final isSelected = option.key == _selectedKey;

                      return Tooltip(
                        message: option.label,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            setState(() => _selectedKey = option.key);
                            widget.onChanged(option.key);
                          },
                          child: AnimatedContainer(
                            duration:
                            const Duration(milliseconds: 120),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? widget.previewColor
                                  .withValues(alpha: 0.12)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? widget.previewColor
                                    : Colors.grey.shade300,
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                BoxShadow(
                                  color: widget.previewColor
                                      .withValues(alpha: 0.18),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                                  : null,
                            ),
                            child: Icon(
                              option.icon,
                              size: tileWidth < 46 ? 18 : 22,
                              color: isSelected
                                  ? widget.previewColor
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}