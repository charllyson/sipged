import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';

import 'package:sisged/_widgets/map/markers/tagged_marker.dart';
import 'package:sisged/_widgets/map/polylines/tappable_changed_polyline.dart';
import 'package:sisged/_widgets/map/polylines/tappable_changed_polyline_layer.dart';
import 'package:sisged/_datas/widgets/map_data.dart';

import '../../_blocs/system/system_bloc.dart';
import '../../_services/regional_geo_json_class.dart';
import 'buttons/layer_buttons.dart';
import 'legend/map_legend_widget.dart';

class MapInteractivePage<T> extends StatefulWidget {
  // Map
  final double? initialZoom;
  final double? maxZoom;
  final double? minZoom;
  final bool activeMap;
  final bool showLegend;

  /// Base custom (ex.: Mapbox, WMS)
  final Widget Function()? baseTileLayerBuilder;

  // Polylines
  final List<TappableChangedPolyline>? tappablePolylines;
  final Future<void> Function()? onClearPolylineSelection;
  final Future<void> Function(TappableChangedPolyline)? onSelectPolyline;
  final void Function({
  required BuildContext context,
  required Offset position,
  required Object? tag,
  })? onShowPolylineTooltip;

  // Markers/Cluster
  final List<TaggedChangedMarker<T>>? taggedMarkers;
  final Widget Function(
      List<TaggedChangedMarker<T>> taggedMarkers,
      LatLng? selectedMarkerPosition,
      ValueChanged<TaggedChangedMarker<T>> onMarkerSelected,
      )? clusterWidgetBuilder;

  // 🧭 Polígonos (retrocompat) - simples, sem nome
  final List<Polygon>? polygon;

  // 🗺️ Polígonos regionais (preferível, com nome da região)
  final List<RegionalPolygon>? regionalPolygons;

  // 🎨 Cores por região (usa a chave "NOME" em upper/lower)
  final Map<String, Color>? regionColors;

  // 🔁 Seleção de regiões
  final bool allowMultiSelect;
  final List<String>? selectedRegionNames; // nomes vindos de fora
  final Function(String? region)? onRegionTap; // callback externo

  const MapInteractivePage({
    super.key,
    this.initialZoom = 9.0,
    this.maxZoom = 18.0,
    this.minZoom = 5.0,
    this.activeMap = true,
    this.showLegend = true,
    this.baseTileLayerBuilder,

    // polylines
    this.tappablePolylines,
    this.onClearPolylineSelection,
    this.onSelectPolyline,
    this.onShowPolylineTooltip,

    // markers
    this.taggedMarkers,
    this.clusterWidgetBuilder,

    // polígonos (retrocompat)
    this.polygon,

    // polígonos regionais (preferível)
    this.regionalPolygons,
    // this.geoManager,

    // cores/seleção
    this.regionColors,

    // seleção de regiões
    this.allowMultiSelect = false,
    this.selectedRegionNames,
    this.onRegionTap,
  });

  @override
  State<MapInteractivePage<T>> createState() => _MapInteractivePageState<T>();
}

class _MapInteractivePageState<T> extends State<MapInteractivePage<T>>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  int _indexSelectedMap = 0;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  late final SystemBloc _systemBloc;

  LatLng? _selectedMarkerPosition;
  LatLng? _userLocation;

  // 🔁 seleção interna de regiões (guarda nomes em UPPERCASE)
  final List<String> _selectedRegions = [];

  // ---------- Ciclo de vida ----------
  @override
  void initState() {
    super.initState();
    _systemBloc = SystemBloc();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );

    // Inicia seleção vinda de fora
    if (widget.selectedRegionNames != null) {
      _selectedRegions
        ..clear()
        ..addAll(widget.selectedRegionNames!
            .map((e) => e.trim().toUpperCase()));
    }

    // Fallback adicional após o primeiro frame (ajuda no Web)
    WidgetsBinding.instance.addPostFrameCallback((_) => _kickstartTiles());
  }

  @override
  void didUpdateWidget(covariant MapInteractivePage<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedRegionNames != null &&
        widget.selectedRegionNames != oldWidget.selectedRegionNames) {
      setState(() {
        _selectedRegions
          ..clear()
          ..addAll(widget.selectedRegionNames!
              .map((e) => e.trim().toUpperCase()));
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ---------- Helpers ----------
  /// Força o carregamento inicial dos tiles/navegação com um “nudge”
  Future<void> _kickstartTiles() async {
    await Future<void>.delayed(const Duration(milliseconds: 0));
    if (!mounted) return;
    try {
      final center = _mapController.camera.center;
      final zoom = _mapController.camera.zoom;
      _mapController.move(center, zoom + 0.000001);
      await Future<void>.delayed(const Duration(milliseconds: 16));
      if (!mounted) return;
      _mapController.move(center, zoom);
    } catch (_) {}
  }

  Future<void> _handleMyLocationTap() async {
    final location = await _systemBloc.getUserCurrentLocation();
    if (!mounted) return;
    if (location != null) {
      setState(() => _userLocation = location);
      _mapController.move(location, 16);
    }
  }

  void _handleMapSwitchTap() {
    setState(() {
      _indexSelectedMap = (_indexSelectedMap + 1) % MapData.mapBase.length;
    });
    _kickstartTiles();
  }

  Future<void> _handlePolylineTap(
      List<TappableChangedPolyline> tapped,
      TapUpDetails details,
      ) async {
    if (tapped.isEmpty) return;
    final tappedPolyline = tapped.first;

    await widget.onSelectPolyline?.call(tappedPolyline);

    final onShow = widget.onShowPolylineTooltip;
    if (onShow != null) {
      onShow(
        context: context,
        position: details.globalPosition,
        tag: tappedPolyline.tag,
      );
    }
  }

  // ---------- Seleção de regiões ----------
  // Algoritmo ray-casting básico (ponto dentro do polígono)
  bool _pointInPolygon(LatLng p, List<LatLng> pts) {
    bool inside = false;
    for (int i = 0, j = pts.length - 1; i < pts.length; j = i++) {
      final xi = pts[i].latitude, yi = pts[i].longitude;
      final xj = pts[j].latitude, yj = pts[j].longitude;
      final intersect = ((yi > p.longitude) != (yj > p.longitude)) &&
          (p.latitude <
              (xj - xi) * (p.longitude - yi) / (yj - yi + 0.0) + xi);
      if (intersect) inside = !inside;
    }
    return inside;
  }

  List<RegionalPolygon> get _regionalPolys {
    if (widget.regionalPolygons != null) return widget.regionalPolygons!;
    // Se quiser retrocompat com um manager:
    // if (widget.geoManager != null) return widget.geoManager!.regionalPolygons;
    return const <RegionalPolygon>[];
  }

  void _toggleRegion(String regionUpper) {
    final already = _selectedRegions.contains(regionUpper);
    if (widget.allowMultiSelect) {
      setState(() {
        if (already) {
          _selectedRegions.remove(regionUpper);
        } else {
          _selectedRegions.add(regionUpper);
        }
      });
    } else {
      setState(() {
        _selectedRegions
          ..clear()
          ..add(regionUpper);
      });
    }
  }

  Future<void> _onTapMap(TapPosition _, LatLng point) async {
    // Se houver polígonos regionais, priorize seleção por eles
    final regs = _regionalPolys;
    bool hit = false;

    for (final reg in regs) {
      if (_pointInPolygon(point, reg.polygon.points)) {
        final regionUpper = reg.regionName.trim().toUpperCase();
        _toggleRegion(regionUpper);

        // Callback com o nome original (case original)
        widget.onRegionTap?.call(reg.regionName);
        hit = true;
        break;
      }
    }

    // Se não bateu em região, limpa seleção e avisa callback
    if (!hit) {
      setState(() => _selectedRegions.clear());
      widget.onRegionTap?.call(null);
    }
  }

  // ---------- Camadas ----------
  List<Widget> _buildMapLayers() {
    final List<Widget> layers = [];

    // Base layer (custom builder tem prioridade)
    if (widget.activeMap) {
      if (widget.baseTileLayerBuilder != null) {
        layers.add(widget.baseTileLayerBuilder!());
      } else if (MapData.mapBase[_indexSelectedMap].url.isNotEmpty) {
        layers.add(
          TileLayer(
            key: ValueKey(_indexSelectedMap),
            tileProvider: CancellableNetworkTileProvider(),
            urlTemplate: MapData.mapBase[_indexSelectedMap].url,
            subdomains: const ['a', 'b', 'c'],
            userAgentPackageName: 'com.example.sisgeo',
            keepBuffer: 3,
          ),
        );
      }
    }

    // Polylines clicáveis
    final lines = widget.tappablePolylines;
    if (lines != null && lines.isNotEmpty) {
      layers.add(
        MapTappablePolylineLayer(
          polylines: lines,
          onTap: _handlePolylineTap,
          polylineCulling: false,
        ),
      );
    }

    // Markers/Clusters
    final markers = widget.taggedMarkers;
    if (markers != null &&
        markers.isNotEmpty &&
        widget.clusterWidgetBuilder != null) {
      layers.add(
        widget.clusterWidgetBuilder!(
          markers,
          _selectedMarkerPosition,
              (marker) => setState(() => _selectedMarkerPosition = marker.point),
        ),
      );
    }

    // 🗺️ Polígonos regionais (preferível)
    final regional = _regionalPolys;
    if (regional.isNotEmpty) {
      layers.add(
        PolygonLayer(
          polygons: regional.map((entry) {
            final nameUpper = entry.regionName.trim().toUpperCase();
            final isSelected = _selectedRegions.contains(nameUpper);

            // Busca cor por várias chaves comuns
            final base = widget.regionColors?[nameUpper] ??
                widget.regionColors?[entry.regionName] ??
                widget.regionColors?[
                entry.regionName.toLowerCase()] ??
                widget.regionColors?[
                entry.regionName.toUpperCase()];

            final baseColor = base ?? Colors.white70;
            final fill = baseColor.withOpacity(isSelected ? 0.85 : 0.30);

            return Polygon(
              points: entry.polygon.points,
              color: fill,
              borderColor: Colors.black,
              borderStrokeWidth: 0.3,
              isFilled: true,
            );
          }).toList(),
        ),
      );
    } else {
      // 🔙 Retrocompat: desenha se vier List<Polygon>
      final polys = widget.polygon;
      if (polys != null && polys.isNotEmpty) {
        layers.add(PolygonLayer(polygons: polys));
      }
    }

    // Minha localização (pulsante)
    if (_userLocation != null) {
      layers.add(
        MarkerLayer(
          markers: [
            Marker(
              point: _userLocation!,
              width: 60,
              height: 60,
              child: ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue.withOpacity(0.25),
                    border: Border.all(color: Colors.blueAccent, width: 2),
                  ),
                  child: Center(
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Legenda por região (se houver cores)
    if (widget.showLegend && (widget.regionColors?.isNotEmpty ?? false)) {
      layers.add(
        Align(
          alignment: Alignment.bottomLeft,
          child: MapLegendLayer(regionColors: widget.regionColors!),
        ),
      );
    }

    return layers;
  }

  // ---------- Build ----------
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: const LatLng(-9.65, -36.7),
                  initialZoom: widget.initialZoom ?? 9,
                  maxZoom: widget.maxZoom ?? 18,
                  minZoom: widget.minZoom ?? 5,

                  // Dispara o carregamento imediato dos tiles
                  onMapReady: _kickstartTiles,

                  // Toque no mapa:
                  onTap: _onTapMap,
                ),
                children: _buildMapLayers(),
              ),
            ),
          ],
        ),
        LayerButtons(
          onMyLocationTap: _handleMyLocationTap,
          onMapSwitchTap: _handleMapSwitchTap,
          mapaAtual: MapData.mapBase[_indexSelectedMap].nome,
        ),
      ],
    );
  }
}
