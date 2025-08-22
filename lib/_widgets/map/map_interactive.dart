// lib/_widgets/map/map_interactive.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:diacritic/diacritic.dart';
import 'package:provider/provider.dart';

import 'package:sisged/_datas/widgets/regional_geo_json_class.dart';
import 'package:sisged/_widgets/map/markers/tagged_marker.dart';
import 'package:sisged/_widgets/map/polylines/tappable_changed_polyline.dart';
import 'package:sisged/_widgets/map/polylines/tappable_changed_polyline_layer.dart';
import 'package:sisged/_datas/widgets/mapa/map_layer.dart';
import 'package:sisged/_blocs/system/system_bloc.dart';
import '../paint/paint_overlay.dart';
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
  /// IMPORTANTE: retorne um **LayerWidget** do flutter_map (ex.: TileLayer/WMSLayer).
  final Widget Function()? baseTileLayerBuilder;

  /// Overlay de UI (ex.: editor de pintura) — fica **fora** do FlutterMap.
  final Widget Function(MapController mapController, GlobalKey captureKey)? overlayBuilder;

  // Polylines
  final List<TappableChangedPolyline>? tappablePolylines;
  final Future<void> Function()? onClearPolylineSelection;
  final Future<void> Function(TappableChangedPolyline)? onSelectPolyline;
  final void Function({
  required BuildContext context,
  required Offset position,
  required Object? tag,
  })? onShowPolylineTooltip;

  // Markers/Cluster — a função deve retornar um **LayerWidget** (ex.: MarkerLayer/MarkerClusterLayer)
  final List<TaggedChangedMarker<T>>? taggedMarkers;
  final Widget Function(
      List<TaggedChangedMarker<T>> taggedMarkers,
      LatLng? selectedMarkerPosition,
      ValueChanged<TaggedChangedMarker<T>> onMarkerSelected,
      )? clusterWidgetBuilder;

  // Polígonos (retrocompat)
  final List<Polygon>? polygon;

  // Polígonos regionais (preferível)
  final List<PolygonChanged>? regionalPolygons;

  // Cores por região (usa a chave normalizada)
  final Map<String, Color>? regionColors;

  // Seleção de regiões
  final bool allowMultiSelect;
  final List<String>? selectedRegionNames;
  final Function(String? region)? onRegionTap;

  const MapInteractivePage({
    super.key,
    this.initialZoom = 9.0,
    this.maxZoom = 18.4,
    this.minZoom = 5.0,
    this.activeMap = true,
    this.showLegend = true,
    this.baseTileLayerBuilder,
    this.overlayBuilder,
    this.tappablePolylines,
    this.onClearPolylineSelection,
    this.onSelectPolyline,
    this.onShowPolylineTooltip,
    this.taggedMarkers,
    this.clusterWidgetBuilder,
    this.polygon,
    this.regionalPolygons,
    this.regionColors,
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
  final GlobalKey _captureKey = GlobalKey();

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  late SystemBloc _systemBloc;

  LatLng? _selectedMarkerPosition;
  LatLng? _userLocation;

  // seleção interna (chave normalizada)
  final List<String> _selectedRegions = [];

  String _norm(String s) =>
      removeDiacritics(s).replaceAll(RegExp(r'\s+'), ' ').trim().toUpperCase();

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );

    if (widget.selectedRegionNames != null) {
      _selectedRegions
        ..clear()
        ..addAll(widget.selectedRegionNames!.map(_norm));
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _kickstartTiles());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _systemBloc = context.read<SystemBloc>();
  }

  @override
  void reassemble() {
    super.reassemble();
    _kickstartTiles();
  }

  @override
  void didUpdateWidget(covariant MapInteractivePage<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedRegionNames != null &&
        widget.selectedRegionNames != oldWidget.selectedRegionNames) {
      setState(() {
        _selectedRegions
          ..clear()
          ..addAll(widget.selectedRegionNames!.map(_norm));
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

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
      _indexSelectedMap = (_indexSelectedMap + 1) % MapLayer.mapBase.length;
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

  List<PolygonChanged> get _regionalPolys =>
      widget.regionalPolygons ?? const <PolygonChanged>[];

  void _toggleRegion(String regionKey) {
    final already = _selectedRegions.contains(regionKey);
    if (widget.allowMultiSelect) {
      setState(() {
        if (already) {
          _selectedRegions.remove(regionKey);
        } else {
          _selectedRegions.add(regionKey);
        }
      });
    } else {
      setState(() {
        _selectedRegions
          ..clear()
          ..add(regionKey);
      });
    }
  }

  Future<void> _onTapMap(TapPosition _, LatLng point) async {
    final regs = _regionalPolys;
    bool hit = false;

    for (final reg in regs) {
      if (_pointInPolygon(point, reg.polygon.points)) {
        final regionKey = _norm(reg.regionName);
        _toggleRegion(regionKey);
        widget.onRegionTap?.call(reg.regionName);
        hit = true;
        break;
      }
    }

    if (!hit) {
      setState(() => _selectedRegions.clear());
      widget.onRegionTap?.call(null);
    }
  }

  // ---------- LAYERS DO FLUTTER_MAP (apenas LayerWidgets) ----------
  List<Widget> _buildMapLayers() {
    final List<Widget> layers = [];

    if (widget.activeMap) {
      if (widget.baseTileLayerBuilder != null) {
        // deve retornar um LayerWidget (ex.: TileLayer)
        layers.add(widget.baseTileLayerBuilder!());
      } else if (MapLayer.mapBase[_indexSelectedMap].url.isNotEmpty) {
        layers.add(
          TileLayer(
            key: ValueKey(_indexSelectedMap),
            tileProvider: CancellableNetworkTileProvider(),
            urlTemplate: MapLayer.mapBase[_indexSelectedMap].url,
            subdomains: const ['a', 'b', 'c'],
            userAgentPackageName: 'com.example.sisgeo',
            keepBuffer: 3,
          ),
        );
      }
    }

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

    final markers = widget.taggedMarkers;
    if (markers != null &&
        markers.isNotEmpty &&
        widget.clusterWidgetBuilder != null) {
      // IMPORTANTE: clusterWidgetBuilder deve devolver um **LayerWidget**
      layers.add(
        widget.clusterWidgetBuilder!(
          markers,
          _selectedMarkerPosition,
              (marker) => setState(() => _selectedMarkerPosition = marker.point),
        ),
      );
    }

    final regional = _regionalPolys;
    if (regional.isNotEmpty) {
      layers.add(
        PolygonLayer(
          polygons: regional.map((entry) {
            final key = _norm(entry.regionName);
            final isSelected = _selectedRegions.contains(key);

            final base = widget.regionColors?[key] ??
                widget.regionColors?[entry.regionName] ??
                widget.regionColors?[entry.regionName.toUpperCase()] ??
                widget.regionColors?[entry.regionName.toLowerCase()];

            final baseColor = base ?? Colors.white70;
            final fill = baseColor.withOpacity(isSelected ? 1 : 0.30);

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
      final polys = widget.polygon;
      if (polys != null && polys.isNotEmpty) {
        layers.add(PolygonLayer(polygons: polys));
      }
    }

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

    // 👇️ NÃO adicione `Align/Positioned/Widgets comuns` aqui.
    return layers;
  }

  @override
  Widget build(BuildContext context) {
    final hasLegend = widget.showLegend && (widget.regionColors?.isNotEmpty ?? false);

    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: RepaintBoundary(
                key: _captureKey,
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        backgroundColor: Colors.white,
                        initialCenter: const LatLng(-9.65, -36.7),
                        initialZoom: widget.initialZoom ?? 9,
                        maxZoom: widget.maxZoom ?? 18,
                        minZoom: widget.minZoom ?? 5,
                        onMapReady: _kickstartTiles,
                        onTap: _onTapMap,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.pinchZoom |
                          InteractiveFlag.drag |
                          InteractiveFlag.flingAnimation |
                          InteractiveFlag.doubleTapZoom |
                          InteractiveFlag.scrollWheelZoom,
                        ),
                      ),
                      children: _buildMapLayers(),
                    ),

                    // Overlay opcional (ex.: pintura) — fica FORA do FlutterMap
                    if (widget.overlayBuilder != null)
                      Positioned.fill(
                        child: widget.overlayBuilder!(_mapController, _captureKey),
                      ),

                    // 👇️ Legenda — também FORA do FlutterMap
                    if (hasLegend)
                      Positioned(
                        left: 8,
                        bottom: 8,
                        child: MapLegendLayer(regionColors: widget.regionColors!),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),

        // Botões de camada / localização — fora do mapa
        LayerButtons(
          onMyLocationTap: _handleMyLocationTap,
          onMapSwitchTap: _handleMapSwitchTap,
          mapaAtual: MapLayer.mapBase[_indexSelectedMap].nome,
        ),
      ],
    );
  }
}
