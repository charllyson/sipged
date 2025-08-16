// lib/screens/sectors/traffic/dashboard/mapa_interativo_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sisged/_blocs/widgets/map_bloc.dart';
import 'package:sisged/_datas/widgets/map_data.dart';
import '../../_services/regional_geo_json_class.dart';
import '../../_services/geo_json_manager.dart'; // opcional (retrocompat)
import 'legend/map_legend_widget.dart';

class MapaInterativoPage extends StatefulWidget {
  // Map options
  final double? initialZoom;
  final double? maxZoom;
  final double? minZoom;
  final bool activeMap;
  final bool allowMultiSelect;
  final bool showLegend;

  // 🔁 Preferível: receba polígonos prontos
  final List<RegionalPolygon>? regionalPolygons;

  // ✅ retrocompat (se ainda quiser usar um manager externo)
  final GeoJsonManager? geoManager;

  // Seleção e callbacks
  final List<String>? selectedRegionNames;
  final Function(String? region)? onRegionTap;
  final Map<String, Color>? regionColors;

  // Data fetch/dialog
  final Future<List<dynamic>> Function(String, dynamic)? getFirebaseData;
  final void Function(BuildContext context, String region, List<dynamic> dados)? onShowDialog;

  const MapaInterativoPage({
    super.key,
    this.initialZoom = 7.6,
    this.maxZoom = 19.4,
    this.minZoom = 8,
    this.activeMap = true,
    this.allowMultiSelect = false,
    this.showLegend = false,

    // preferível agora:
    this.regionalPolygons,

    // retrocompat:
    this.geoManager,

    this.selectedRegionNames,
    this.onRegionTap,
    this.regionColors,
    this.getFirebaseData,
    this.onShowDialog,
  });

  @override
  State<MapaInterativoPage> createState() => _MapaInterativoPageState();
}

class _MapaInterativoPageState extends State<MapaInterativoPage> with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  final List<String> _selectedRegion = [];
  bool _isDialogLoading = false;
  final int _indexSelectedMap = 0;

  late MapBloc _mapBloc;
  late AnimationController _pulseController;

  // 🔁 Polígonos agora vêm preferencialmente por parâmetro;
  // cai para geoManager (se existir) e, por fim, vazio.
  List<RegionalPolygon> get _polygons {
    if (widget.regionalPolygons != null) return widget.regionalPolygons!;
    if (widget.geoManager != null) return widget.geoManager!.regionalPolygons;
    return const <RegionalPolygon>[];
  }

  @override
  void initState() {
    super.initState();
    _mapBloc = MapBloc();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // inicializa seleção vinda de fora
    if (widget.selectedRegionNames != null) {
      _selectedRegion
        ..clear()
        ..addAll(widget.selectedRegionNames!.map((e) => e.toUpperCase()));
    }
  }

  @override
  void didUpdateWidget(covariant MapaInterativoPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Atualiza seleção quando a prop muda
    if (widget.selectedRegionNames != null &&
        widget.selectedRegionNames != oldWidget.selectedRegionNames) {
      setState(() {
        _selectedRegion
          ..clear()
          ..addAll(widget.selectedRegionNames!.map((e) => e.toUpperCase()));
      });
    }
  }

  Future<void> _handleTapOnMap(TapPosition _, LatLng point) async {
    bool regionTap = false;

    for (final reg in _polygons) {
      if (_mapBloc.pointInPolygon(point, reg.polygon.points)) {
        final newSelection = _mapBloc.toggleRegionSelection(
          currentSelection: _selectedRegion,
          region: reg.regionName.toUpperCase(),
          allowMultiSelect: widget.allowMultiSelect,
        );

        setState(() => _selectedRegion
          ..clear()
          ..addAll(newSelection));

        // Callback externo com o nome "original" da região
        widget.onRegionTap?.call(_selectedRegion.isEmpty ? null : reg.regionName);

        if (widget.onShowDialog != null &&
            widget.getFirebaseData != null &&
            !_isDialogLoading &&
            _selectedRegion.isNotEmpty) {
          _isDialogLoading = true;
          try {
            final dados = await widget.getFirebaseData!(reg.regionName, null);
            if (mounted) widget.onShowDialog!(context, reg.regionName, dados);
          } catch (e) {
            debugPrint('Erro ao carregar dados: $e');
          } finally {
            _isDialogLoading = false;
          }
        }

        regionTap = true;
        break;
      }
    }

    if (!regionTap) {
      setState(() => _selectedRegion.clear());
      widget.onRegionTap?.call(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final polygons = _polygons;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    backgroundColor: Colors.white,
                    interactionOptions: InteractionOptions(
                      enableMultiFingerGestureRace: true,
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate & ~InteractiveFlag.drag & ~InteractiveFlag.scrollWheelZoom,
                    ),
                    initialCenter: const LatLng(-9.65, -36.7),
                    initialZoom: widget.initialZoom!,
                    minZoom: widget.minZoom ?? widget.initialZoom,
                    maxZoom: widget.maxZoom ?? widget.initialZoom,
                    onTap: _handleTapOnMap,
                  ),
                  children: [
                    if (widget.activeMap && MapData.mapBase[_indexSelectedMap].url.isNotEmpty)
                      TileLayer(
                        key: ValueKey(_indexSelectedMap),
                        urlTemplate: MapData.mapBase[_indexSelectedMap].url,
                        subdomains: const ['a', 'b', 'c'],
                        userAgentPackageName: 'com.example.app',
                      ),

                    // ⚠️ se não há polígonos, não desenhe a camada
                    if (polygons.isNotEmpty)
                      PolygonLayer(
                        polygons: polygons.map((entry) {
                          final nome = entry.regionName.toUpperCase();
                          final selecionado = _selectedRegion.contains(nome);
                          final corPorCidade = widget.regionColors?[nome] ?? widget.regionColors?[entry.regionName];
                          final baseColor = corPorCidade ?? Colors.white70;
                          final cor = baseColor.withOpacity(selecionado ? 0.85 : 0.3);
                          return Polygon(
                            points: entry.polygon.points,
                            color: cor,
                            borderColor: Colors.black,
                            borderStrokeWidth: 0.3,
                            isFilled: true,
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
              if (widget.showLegend) const MapLegendLayer(),
            ],
          ),

          if (polygons.isEmpty)
            Positioned.fill(
              child: IgnorePointer(
                ignoring: true,
                child: Center(
                  child: Text(
                    'Carregando limites municipais…',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }
}
