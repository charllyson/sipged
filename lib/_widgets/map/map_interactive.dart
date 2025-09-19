// lib/_widgets/map/map_interactive.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:diacritic/diacritic.dart';
import 'package:provider/provider.dart';
import 'package:siged/_services/geocoding/geocoding_service.dart';
import 'package:siged/_widgets/search/SearchPin.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:siged/_widgets/map/polygon/polygon_changed.dart';
import 'package:siged/_widgets/map/markers/tagged_marker.dart';
import 'package:siged/_widgets/map/polylines/tappable_changed_polyline.dart';
import 'package:siged/_widgets/map/polylines/tappable_changed_polyline_layer.dart';
import 'package:siged/_widgets/map/base/map_base_layer.dart';
import 'package:siged/_blocs/system/info/system_bloc.dart';

import '../search/search_widget.dart';
import '../suggestions/suggestion_models.dart';
import 'buttons/layer_buttons.dart';
import 'legend/map_legend_widget.dart';

// NEW: usa seu overlay reutilizável
import 'package:siged/_widgets/search/search_overlay.dart'; // SearchOverlay + SearchAction

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
  final List<PolygonChanged>? polygonsChanged;
  final Map<String, Color>? polygonChangeColors;

  // Seleção de regiões
  final bool allowMultiSelect;
  final List<String>? selectedRegionNames;
  final Function(String? region)? onRegionTap;

  // =================== NEW: BUSCA ===================
  /// Mostra o botão/flutuante de busca (reutilizável). Default: false.
  final bool showSearch;

  /// Builder do botão/ação de busca. Recebe um callback `onSearch(text)`.
  /// Se não fornecer, usa `SearchAction(onSearch: ...)`.
  final Widget Function(void Function(String) onSearch)? searchActionBuilder;

  /// Zoom alvo quando localizar um resultado (coordenadas ou geocoder).
  final double searchTargetZoom;

  /// Mostra um marcador na posição localizada (default: true).
  final bool showSearchMarker;

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
    this.polygonsChanged,
    this.polygonChangeColors,
    this.allowMultiSelect = false,
    this.selectedRegionNames,
    this.onRegionTap,

    // NEW
    this.showSearch = false,
    this.searchActionBuilder,
    this.searchTargetZoom = 16,
    this.showSearchMarker = true,
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

  late final GeocodingService _geocoder;

  // controla quando podemos montar o TileLayer
  bool _mapReady = false;

  // NEW: marcador de resultado da busca
  LatLng? _searchHit;

  String _norm(String s) =>
      removeDiacritics(s).replaceAll(RegExp(r'\s+'), ' ').trim().toUpperCase();

  bool get _isOsmPublic {
    final url = MapBaseLayer.mapBase[_indexSelectedMap].url;
    return url.contains('tile.openstreetmap.org');
  }

  @override
  void initState() {
    super.initState();
    _geocoder = GeocodingService.nominatim(
      userAgent: 'siged-app/1.0 (seu-email@org.gov.br)', // obrig.
      acceptLanguage: 'pt-BR',
      countryCodes: 'br', // opcional: restringe ao Brasil
      limit: 1,
    );

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
      _indexSelectedMap = (_indexSelectedMap + 1) % MapBaseLayer.mapBase.length;
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
      widget.polygonsChanged ?? const <PolygonChanged>[];

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
        final regionKey = _norm(reg.title);
        _toggleRegion(regionKey);
        widget.onRegionTap?.call(reg.title);
        hit = true;
        break;
      }
    }

    if (!hit) {
      setState(() {
        _selectedRegions.clear();
        _selectedMarkerPosition = null; // 👈 limpa o marker selecionado
      });
      widget.onRegionTap?.call(null);
    }

  }

  // ======== AUTOCOMPLETE (endereços) ========
  Future<List<SearchSuggestion>> _fetchAddressSuggestions(String q) async {
    if (q.trim().length < 3) return const []; // evita bater na API a cada tecla
    final results = await _geocoder.search(q, limit: 8);
    return results.map((r) {
      return SearchSuggestion.address(
        id: r.id,
        title: r.title,
        subtitle: r.city ?? r.state ?? r.country,
        point: r.point,
      );
    }).toList();
  }

  void _onSuggestionTap(SearchSuggestion s, void Function(String) onSearch) {
    // para padronizar, transformamos em texto e reaproveitamos _onSearch
    final data = s.data;
    if (data is LatLng) {
      onSearch('${data.latitude},${data.longitude}');
    } else {
      onSearch(s.title);
    }
  }

  // =================== BUSCA (enter / sugestão) ===================
  Future<void> _onSearch(String text) async {
    final q = text.trim();
    if (q.isEmpty) return;

    // 1) tenta coordenadas no próprio texto
    final parsed = _parseLatLng(q);
    if (parsed != null) {
      _goTo(parsed);
      return;
    }

    // 2) geocoder interno (Nominatim por padrão)
    try {
      final hit = await _geocoder.geocode(q);
      if (hit != null) {
        _goTo(hit);
        return;
      }
    } catch (_) {}

    // 3) feedback simples
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não achei. Tente “lat, lng” ou refine a busca.')),
      );
    }
  }

  void _goTo(LatLng p) {
    setState(() => _searchHit = p);
    _mapController.move(p, widget.searchTargetZoom);
  }

  // Suporta: "-9.65, -36.7"  |  "S9.65 W36.7"  |  "lat:-9.65 lon:-36.7"
  LatLng? _parseLatLng(String s) {
    // A) decimal com vírgula ou espaço
    final reA = RegExp(r'(-?\d{1,3}(?:\.\d+)?)\s*[,;\s]\s*(-?\d{1,3}(?:\.\d+)?)');
    final mA = reA.firstMatch(s);
    if (mA != null) {
      final lat = double.tryParse(mA.group(1)!);
      final lng = double.tryParse(mA.group(2)!);
      if (lat != null && lng != null && _isValidLatLng(lat, lng)) {
        return LatLng(lat, lng);
      }
    }

    // B) com N/S/E/W
    final reB = RegExp(
      r'(?:(N|S)\s*)?(\d{1,3}(?:\.\d+)?)\D+(?:(E|W|L|O)\s*)?(\d{1,3}(?:\.\d+)?)',
      caseSensitive: false,
    );
    final mB = reB.firstMatch(s);
    if (mB != null) {
      final ns = (mB.group(1) ?? '').toUpperCase();
      final ew = (mB.group(3) ?? '').toUpperCase();
      final latVal = double.tryParse(mB.group(2)!);
      final lngVal = double.tryParse(mB.group(4)!);
      if (latVal != null && lngVal != null) {
        var lat = latVal;
        var lng = lngVal;
        if (ns == 'S') lat = -lat.abs();
        if (ew == 'W' || ew == 'O' || ew == 'L') lng = -lng.abs(); // O/L = Oeste
        if (_isValidLatLng(lat, lng)) return LatLng(lat, lng);
      }
    }

    // C) "lat: x lon: y"
    final reC = RegExp(
      r'lat[:=]\s*(-?\d+(?:\.\d+)?)\D+lon[g]?[:=]\s*(-?\d+(?:\.\d+)?)',
      caseSensitive: false,
    );
    final mC = reC.firstMatch(s);
    if (mC != null) {
      final lat = double.tryParse(mC.group(1)!);
      final lng = double.tryParse(mC.group(2)!);
      if (lat != null && lng != null && _isValidLatLng(lat, lng)) {
        return LatLng(lat, lng);
      }
    }

    return null;
  }

  bool _isValidLatLng(double lat, double lng) =>
      lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;

  // ---------- LAYERS DO FLUTTER_MAP (apenas LayerWidgets) ----------
  List<Widget> _buildMapLayers() {
    final List<Widget> layers = [];

    if (widget.activeMap && _mapReady) {
      if (widget.baseTileLayerBuilder != null) {
        layers.add(widget.baseTileLayerBuilder!()); // deve ser LayerWidget
      } else if (MapBaseLayer.mapBase[_indexSelectedMap].url.isNotEmpty) {
        final tileProvider = NetworkTileProvider(); // web: não-cancelável
        layers.add(
          TileLayer(
            key: ValueKey(_indexSelectedMap),
            tileProvider: tileProvider,
            urlTemplate: MapBaseLayer.mapBase[_indexSelectedMap].url,
            subdomains: const ['a', 'b', 'c'],
            userAgentPackageName: 'br.gov.al.siged', // <- IMPORTANTE
            keepBuffer: 3,
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
            final key = _norm(entry.title);
            final isSelected = _selectedRegions.contains(key);

            final base = widget.polygonChangeColors?[key] ??
                widget.polygonChangeColors?[entry.title] ??
                widget.polygonChangeColors?[entry.title.toUpperCase()] ??
                widget.polygonChangeColors?[entry.title.toLowerCase()];

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
              (marker) => setState(() {
            const tol = 1e-6; // ~0.1 m em lat/lon (bom p/ float)
            final p = marker.point;
            final s = _selectedMarkerPosition;

            final same = s != null &&
                (s.latitude  - p.latitude ).abs() < tol &&
                (s.longitude - p.longitude).abs() < tol;

            _selectedMarkerPosition = same ? null : p;
          }),
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

    // NEW: marcador do resultado da busca
    if (widget.showSearchMarker && _searchHit != null) {
      layers.add(
        MarkerLayer(
          markers: [
            Marker(
              point: _searchHit!,
              width: 38,
              height: 38,
              alignment: Alignment.bottomCenter,
              child: SearchPin(), // pin simples
            ),
          ],
        ),
      );
    }

    // Atribuição do OSM (apenas se usando tile público)
    if (_isOsmPublic) {
      layers.add(
        RichAttributionWidget(
          attributions: [
            TextSourceAttribution(
              '© OpenStreetMap contributors',
              onTap: () => launchUrl(
                Uri.parse('https://www.openstreetmap.org/copyright'),
                mode: LaunchMode.externalApplication,
              ),
            ),
          ],
        ),
      );
    }

    return layers; // somente layers (LayerWidget) + AttributionWidget
  }

  @override
  Widget build(BuildContext context) {
    final hasLegend =
        widget.showLegend && (widget.polygonChangeColors?.isNotEmpty ?? false);

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
                        child: widget.overlayBuilder!(_mapController, _captureKey),
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
            child: MapLegendLayer(regionColors: widget.polygonChangeColors!),
          ),

        // NEW: ação de busca flutuante (superior esquerda) + outros botões
        if (widget.showSearch)
          Positioned(
            top: 10,
            left: 10,
            child: Row(
              children: [
                _buildSearchActionButton(),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _handleMyLocationTap,
                  child: Tooltip(
                    message: 'Minha localização',
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(90),
                      ),
                      child: const Icon(Icons.pin_drop, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _handleMapSwitchTap,
                  child: Tooltip(
                    message: 'Mapa: ${MapBaseLayer.mapBase[_indexSelectedMap].nome}',
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(90),
                      ),
                      child: const Icon(Icons.map, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // NEW: constrói o botão/ação de busca reutilizável
  Widget _buildSearchActionButton() {
    final builder = widget.searchActionBuilder;
    if (builder != null) {
      return builder(_onSearch);
    }
    // fallback: usa seu SearchAction (de search_widget.dart) com autocomplete
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(90),
      ),
      child: SearchAction(
        onSearch: _onSearch,
        fetchSuggestions: _fetchAddressSuggestions,
        onSuggestionTap: (s) => _onSuggestionTap(s, _onSearch),
        hintText: 'Buscar endereço ou "lat, lng"...',
        expandSide: SearchExpandSide.right,
        maxWidth: 320,
        height: 42,
      ),
    );
  }
}
