// lib/_widgets/map/map_interactive.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:diacritic/diacritic.dart';
import 'package:provider/provider.dart';

import 'package:sisged/_blocs/widgets/map/regional_geo_json_class.dart';
import 'package:sisged/_widgets/map/markers/tagged_marker.dart';
import 'package:sisged/_widgets/map/polylines/tappable_changed_polyline.dart';
import 'package:sisged/_widgets/map/polylines/tappable_changed_polyline_layer.dart';
import 'package:sisged/_blocs/widgets/map/map_layer.dart';
import 'package:sisged/_blocs/system/info/system_bloc.dart';

import 'buttons/layer_buttons.dart';
import 'legend/map_legend_widget.dart';

class MapInteractivePage<T> extends StatefulWidget {
  // Map
  final double? initialZoom;
  final double? maxZoom;
  final double? minZoom;
  final bool activeMap;
  final bool showLegend;

  /// Base custom (ex.: Mapbox, WMS) — retorne um **LayerWidget** (TileLayer/WMSLayer).
  final Widget Function()? baseTileLayerBuilder;

  /// Overlay de UI (ex.: editor) — fica **fora** do FlutterMap.
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

  // Markers/Cluster — deve retornar **LayerWidget**
  final List<TaggedChangedMarker<T>>? taggedMarkers;
  final Widget Function(
      List<TaggedChangedMarker<T>> taggedMarkers,
      LatLng? selectedMarkerPosition,
      ValueChanged<TaggedChangedMarker<T>> onMarkerSelected,
      )? clusterWidgetBuilder;

  // Polígonos (retro)
  final List<Polygon>? polygon;

  // Polígonos regionais (preferível)
  final List<PolygonChanged>? regionalPolygons;

  // Cores por região
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

  // controla quando podemos montar o TileLayer
  bool _mapReady = false;

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

    // Não chamamos mais kickstarts aqui; só após onMapReady/hot-reload
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _systemBloc = context.read<SystemBloc>();
  }

  @override
  void reassemble() {
    super.reassemble();
    // Hot reload no web: um move simples para “acordar” o mapa
    Future.delayed(const Duration(milliseconds: 50), () {
      if (!mounted) return;
      try {
        final c = _mapController.camera.center;
        final z = _mapController.camera.zoom;
        _mapController.move(c, z);
      } catch (_) {}
    });
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
    // opcional: um move simples para forçar redraw em alguns navegadores
    Future.microtask(() {
      try {
        final c = _mapController.camera.center;
        final z = _mapController.camera.zoom;
        _mapController.move(c, z);
      } catch (_) {}
    });
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
          (p.latitude < (xj - xi) * (p.longitude - yi) / (yj - yi + 0.0) + xi);
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

    if (widget.activeMap && _mapReady) {
      if (widget.baseTileLayerBuilder != null) {
        layers.add(widget.baseTileLayerBuilder!()); // deve ser LayerWidget
      } else if (MapLayer.mapBase[_indexSelectedMap].url.isNotEmpty) {
        final tileProvider = NetworkTileProvider();        // web: não-cancelável
        layers.add(
          TileLayer(
            key: ValueKey(_indexSelectedMap),
            tileProvider: tileProvider,
            urlTemplate: MapLayer.mapBase[_indexSelectedMap].url,
            subdomains: const ['a', 'b', 'c'],
            userAgentPackageName: 'com.example.sisgeo',
            keepBuffer: 3,
            // ajustes que ajudam a estabilidade
            maxNativeZoom: 19,
            minNativeZoom: 0,
          ),
        );
      }
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
      layers.add(
        widget.clusterWidgetBuilder!(
          markers,
          _selectedMarkerPosition,
              (marker) => setState(() => _selectedMarkerPosition = marker.point),
        ),
      );
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

    return layers; // somente layers (LayerWidget)
  }

  @override
  Widget build(BuildContext context) {
    final hasLegend =
        widget.showLegend && (widget.regionColors?.isNotEmpty ?? false);

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
                        maxZoom: widget.maxZoom ?? 18.4,
                        minZoom: widget.minZoom ?? 5.0,
                        onMapReady: () {
                          if (mounted) setState(() => _mapReady = true);
                        },
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

                    // Overlay opcional (ex.: pintura) — FORA do FlutterMap
                    if (widget.overlayBuilder != null)
                      Positioned.fill(
                        child:
                        widget.overlayBuilder!(_mapController, _captureKey),
                      ),

                    // Placeholder; a legenda vai em outro Positioned
                    if (hasLegend) const SizedBox.shrink(),
                  ],
                ),
              ),
            ),
          ],
        ),

        // Legenda ancorada (fora do mapa para evitar constraints infinitas)
        if (hasLegend)
          Positioned(
            left: 8,
            bottom: 8,
            child: MapLegendLayer(regionColors: widget.regionColors!),
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
