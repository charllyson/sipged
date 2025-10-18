import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:diacritic/diacritic.dart';
import 'package:provider/provider.dart';
import 'package:siged/_services/geocoding/geocoding_service.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:siged/_widgets/map/polygon/polygon_changed.dart';
import 'package:siged/_widgets/map/markers/tagged_marker.dart';
import 'package:siged/_widgets/map/polylines/tappable_changed_polyline.dart';
import 'package:siged/_widgets/map/polylines/tappable_changed_polyline_layer.dart';
import 'package:siged/_widgets/map/base/map_base_layer.dart';
import 'package:siged/_blocs/system/info/system_bloc.dart';

// 🔎 UI de busca
import '../search/search_widget.dart';
import '../suggestions/suggestion_models.dart';
import 'legend/map_legend_widget.dart';
import 'package:siged/_widgets/search/search_overlay.dart';

// 🔔 Notificações
import 'package:siged/_widgets/notification/app_notification.dart';
import 'package:siged/_widgets/notification/notification_center.dart';

// ✅ PIN custom
import 'package:siged/_widgets/map/pin/pin_changed.dart';

class MapInteractivePage<T> extends StatefulWidget {
  // ===== Mapa
  final double? initialZoom;
  final double? maxZoom;
  final double? minZoom;
  final bool activeMap;
  final bool showLegend;

  /// Controla se um **toque no mapa** deve inserir/atualizar o pin de busca.
  /// Default: false (não insere pin ao tocar).
  final bool dropPinOnTap;

  /// Ao tocar fora de marcadores/polígonos, limpa a seleção de marcador?
  /// Default: false (não limpa).
  final bool clearMarkerSelectionOnMapTap;

  /// Base custom (ex.: Mapbox/WMS) — retorne um LayerWidget (TileLayer/WMSLayer).
  final Widget Function()? baseTileLayerBuilder;

  /// Overlay de UI (ex.: editor) — fica fora do FlutterMap.
  final Widget Function(MapController mapController, GlobalKey captureKey)? overlayBuilder;

  // ===== Polylines
  final List<TappableChangedPolyline>? tappablePolylines;
  final Future<void> Function()? onClearPolylineSelection;
  final Future<void> Function(TappableChangedPolyline)? onSelectPolyline;

  /// Tooltip de polylines
  final void Function({
  required BuildContext context,
  required Offset position,
  required Object? tag,
  required MapController mapController,
  LatLng? tapLatLng,
  Offset Function(Offset local)? toGlobal,
  })? onShowPolylineTooltip;

  // ===== Markers/Clusters
  final List<TaggedChangedMarker<T>>? taggedMarkers;

  /// Constrói o layer de cluster/markers (ex.: ClusterAnimatedMarkerLayer)
  final Widget Function(
      List<TaggedChangedMarker<T>> taggedMarkers,
      LatLng? selectedMarkerPosition,
      ValueChanged<TaggedChangedMarker<T>> onMarkerSelected,
      )? clusterWidgetBuilder;

  /// Marcadores extras (badges, labels, etc.)
  final List<Marker>? extraMarkers;

  // ===== Polígonos (genéricos)
  final List<Polygon>? polygon;

  // ===== Polígonos regionais
  final List<PolygonChanged>? polygonsChanged;
  final Map<String, Color>? polygonChangeColors;

  // ===== Seleção de regiões
  final bool allowMultiSelect;
  final List<String>? selectedRegionNames;
  final Function(String? region)? onRegionTap;

  // ===== Busca
  final bool showSearch;
  final Widget Function(void Function(String) onSearch)? searchActionBuilder;
  final double searchTargetZoom;
  final bool showSearchMarker;

  // ===== Camera/Zoom callbacks
  final ValueChanged<double>? onZoomChanged;
  final void Function(double zoom, LatLng center)? onCameraChanged;

  // ===== Sincronização externa
  /// Toque/busca/minha localização → reverse geocode no BLoC (mapa → formulário).
  final void Function(double lat, double lon)? onMapTap;

  /// Controller pronto
  final void Function(MapController controller)? onControllerReady;

  /// Permite ao pai definir o pin ativo externamente.
  /// O estado expõe (via bind) um setter: `void setActivePoint(LatLng p)`.
  final void Function(void Function(LatLng p) setActivePoint)? onBindSetActivePoint;

  const MapInteractivePage({
    super.key,
    this.initialZoom = 9.0,
    this.maxZoom = 22,
    this.minZoom = 2.0,
    this.activeMap = true,
    this.showLegend = true,
    this.dropPinOnTap = false,
    this.clearMarkerSelectionOnMapTap = true,
    this.baseTileLayerBuilder,
    this.overlayBuilder,
    this.tappablePolylines,
    this.onClearPolylineSelection,
    this.onSelectPolyline,
    this.onShowPolylineTooltip,
    this.taggedMarkers,
    this.clusterWidgetBuilder,
    this.extraMarkers,
    this.polygon,
    this.polygonsChanged,
    this.polygonChangeColors,
    this.allowMultiSelect = false,
    this.selectedRegionNames,
    this.onRegionTap,
    this.showSearch = false,
    this.searchActionBuilder,
    this.searchTargetZoom = 16,
    this.showSearchMarker = true,
    this.onZoomChanged,
    this.onCameraChanged,
    this.onMapTap,
    this.onControllerReady,
    this.onBindSetActivePoint,
  });

  @override
  State<MapInteractivePage<T>> createState() => _MapInteractivePageState<T>();
}

class _MapInteractivePageState<T> extends State<MapInteractivePage<T>>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final GlobalKey _captureKey = GlobalKey();

  // Base atual
  int _indexSelectedMap = 0;

  // Animação do “meu local”
  late final AnimationController _pulseController =
  AnimationController(vsync: this, duration: const Duration(seconds: 2))
    ..repeat(reverse: true);
  late final Animation<double> _pulseAnimation =
  CurvedAnimation(parent: _pulseController, curve: Curves.easeOut)
      .drive(Tween(begin: 0.6, end: 1.3));

  late SystemBloc _systemBloc;
  late final GeocodingService _geocoder = GeocodingService.nominatim(
    userAgent: 'siged-app/1.0 (org.gov.br)',
    acceptLanguage: 'pt-BR',
    countryCodes: 'br',
    limit: 1,
  );

  // Reaproveitar provider evita piscar
  late final NetworkTileProvider _tileProvider = NetworkTileProvider();

  // ===== estado leve
  LatLng? _selectedMarkerPosition;

  // ValueNotifiers
  final ValueNotifier<LatLng?> _userLocationVN = ValueNotifier<LatLng?>(null);
  final ValueNotifier<LatLng?> _searchHitVN = ValueNotifier<LatLng?>(null);
  final ValueNotifier<Set<String>> _selectedRegionsVN =
  ValueNotifier<Set<String>>({});

  // Inicial
  late final double _initZoom;
  late final LatLng _initCenter;

  // Persistência de câmera
  LatLng _lastCenter = const LatLng(-9.65, -36.7);
  double _lastZoom = 9.0;
  bool _mapReadyOnce = false;
  bool _hasUserMovedCamera = false;

  String _norm(String s) =>
      removeDiacritics(s).replaceAll(RegExp(r'\s+'), ' ').trim().toUpperCase();

  Set<String> _toNormSet(List<String>? lst) =>
      lst == null ? <String>{} : lst.map(_norm).toSet();

  bool _sameSet(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);

  bool get _isOsmPublic =>
      MapBaseLayer.mapBase[_indexSelectedMap].url.contains('tile.openstreetmap.org');

  @override
  void initState() {
    super.initState();
    _initZoom = widget.initialZoom ?? 9.0;
    _initCenter = const LatLng(-9.65, -36.7);

    _lastCenter = _initCenter;
    _lastZoom = _initZoom;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _systemBloc = context.read<SystemBloc>();
    // aplica seleção inicial (primeira montagem)
    if (widget.selectedRegionNames != null) {
      _selectedRegionsVN.value = _toNormSet(widget.selectedRegionNames);
    }
  }

  @override
  void didUpdateWidget(covariant MapInteractivePage<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 🔄 SINCRONIZAÇÃO: se o pai mudou selectedRegionNames, reflita aqui
    final next = _toNormSet(widget.selectedRegionNames);
    final prev = _toNormSet(oldWidget.selectedRegionNames);

    // Quando mudou (inclui limpar), atualiza o ValueNotifier
    if (!_sameSet(next, prev) && !_sameSet(next, _selectedRegionsVN.value)) {
      _selectedRegionsVN.value = next;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _userLocationVN.dispose();
    _searchHitVN.dispose();
    _selectedRegionsVN.dispose();
    super.dispose();
  }

  Future<void> _handleMyLocationTap() async {
    final loc = await _systemBloc.getUserCurrentLocation();
    if (!mounted) return;
    if (loc != null) {
      _userLocationVN.value = loc;
      _searchHitVN.value = loc; // também vira pin ativo
      _mapController.move(loc, 16);
      _lastCenter = loc;
      _lastZoom = 16;
      _hasUserMovedCamera = true;

      widget.onMapTap?.call(loc.latitude, loc.longitude);

      NotificationCenter.instance.show(
        AppNotification(
          title: Text('Minha localização centralizada'),
          type: AppNotificationType.success,
        ),
      );
    } else {
      NotificationCenter.instance.show(
        AppNotification(
          title: Text('Não foi possível obter sua localização'),
          type: AppNotificationType.error,
        ),
      );
    }
  }

  void _handleMapSwitchTap() {
    setState(() => _indexSelectedMap = (_indexSelectedMap + 1) % MapBaseLayer.mapBase.length);
    Future.microtask(() {
      try {
        final c = _mapController.camera.center;
        final z = _mapController.camera.zoom;
        _mapController.move(c, z);
      } catch (_) {}
    });
    NotificationCenter.instance.show(
      AppNotification(
        title: Text('Mapa: ${MapBaseLayer.mapBase[_indexSelectedMap].nome}'),
        type: AppNotificationType.info,
      ),
    );
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
      Offset Function(Offset local)? toGlobal;
      final rb = _captureKey.currentContext?.findRenderObject() as RenderBox?;
      if (rb != null) toGlobal = rb.localToGlobal;

      final LatLng tapLatLng =
      _mapController.camera.screenOffsetToLatLng(details.localPosition);

      onShow(
        context: context,
        position: details.globalPosition,
        tag: tappedPolyline.tag,
        mapController: _mapController,
        tapLatLng: tapLatLng,
        toGlobal: toGlobal,
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
      widget.polygonsChanged ?? const <PolygonChanged>[];

  void _toggleRegion(String regionKey) {
    final next = Set<String>.from(_selectedRegionsVN.value);
    if (widget.allowMultiSelect) {
      if (next.contains(regionKey)) {
        next.remove(regionKey);
      } else {
        next.add(regionKey);
      }
    } else {
      next
        ..clear()
        ..add(regionKey);
    }
    _selectedRegionsVN.value = next;
  }

  Future<void> _onTapMap(TapPosition _, LatLng point) async {
    // Só insere/atualiza o pin se a tela permitir
    if (widget.dropPinOnTap) {
      _searchHitVN.value = point;
    }

    widget.onMapTap?.call(point.latitude, point.longitude);

    // Hit-test de regiões
    final regs = _regionalPolys;
    bool hit = false;
    for (final reg in regs) {
      if (_pointInPolygon(point, reg.polygon.points)) {
        _toggleRegion(_norm(reg.title));
        widget.onRegionTap?.call(reg.title);
        hit = true;
        break;
      }
    }
    if (!hit) {
      _selectedRegionsVN.value = {};
      if (widget.clearMarkerSelectionOnMapTap) {
        _selectedMarkerPosition = null;
        setState(() {});
      }
      widget.onRegionTap?.call(null);
    }
  }

  // ======== AUTOCOMPLETE ========
  Future<List<SearchSuggestion>> _fetchAddressSuggestions(String q) async {
    if (q.trim().length < 3) return const [];
    final results = await _geocoder.search(q, limit: 8);
    return results
        .map((r) => SearchSuggestion.address(
      id: r.id,
      title: r.title,
      subtitle: r.city ?? r.state ?? r.country,
      point: r.point,
    ))
        .toList();
  }

  void _onSuggestionTap(SearchSuggestion s, void Function(String) onSearch) {
    final data = s.data;
    if (data is LatLng) {
      onSearch('${data.latitude},${data.longitude}');
    } else {
      onSearch(s.title);
    }
  }

  Future<void> _onSearch(String text) async {
    final q = text.trim();
    if (q.isEmpty) return;

    final parsed = _parseLatLng(q);
    if (parsed != null) {
      _goTo(parsed);
      widget.onMapTap?.call(parsed.latitude, parsed.longitude);
      return;
    }

    try {
      final hit = await _geocoder.geocode(q);
      if (hit != null) {
        _goTo(hit);
        widget.onMapTap?.call(hit.latitude, hit.longitude);
        return;
      }
    } catch (_) {}

    NotificationCenter.instance.show(
      AppNotification(
        title: Text('Não encontrado'),
        subtitle: Text('Tente “lat, lng” ou refine a busca.'),
        type: AppNotificationType.warning,
      ),
    );
  }

  void _goTo(LatLng p) {
    _searchHitVN.value = p; // pin
    _mapController.move(p, widget.searchTargetZoom);
    _lastCenter = p;
    _lastZoom = widget.searchTargetZoom;
    _hasUserMovedCamera = true;
  }

  LatLng? _parseLatLng(String s) {
    final reA =
    RegExp(r'(-?\d{1,3}(?:\.\d+)?)\s*[,;\s]\s*(-?\d{1,3}(?:\.\d+)?)');
    final mA = reA.firstMatch(s);
    if (mA != null) {
      final lat = double.tryParse(mA.group(1)!);
      final lng = double.tryParse(mA.group(2)!);
      if (lat != null && lng != null && _isValidLatLng(lat, lng)) {
        return LatLng(lat, lng);
      }
    }

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
        if (ew == 'W' || ew == 'O' || ew == 'L') lng = -lng.abs();
        if (_isValidLatLng(lat, lng)) return LatLng(lat, lng);
      }
    }

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

  // ---------- LAYERS DO FLUTTER_MAP ----------
  List<Widget> _buildMapLayers() {
    final layers = <Widget>[];

    // Base
    if (widget.activeMap) {
      if (widget.baseTileLayerBuilder != null) {
        layers.add(widget.baseTileLayerBuilder!());
      } else if (MapBaseLayer.mapBase[_indexSelectedMap].url.isNotEmpty) {
        layers.add(
          TileLayer(
            tileProvider: _tileProvider,
            urlTemplate: MapBaseLayer.mapBase[_indexSelectedMap].url,
            subdomains: const ['a', 'b', 'c'],
            userAgentPackageName: 'br.gov.al.siged',
            keepBuffer: 3,
            maxNativeZoom: 19,
            minNativeZoom: 0,
          ),
        );
      }
    }

    // Polígonos regionais (coloridos por seleção)
    final regional = _regionalPolys;
    if (regional.isNotEmpty) {
      layers.add(
        ValueListenableBuilder<Set<String>>(
          valueListenable: _selectedRegionsVN,
          builder: (_, selected, __) {
            return PolygonLayer(
              polygons: regional.map((entry) {
                final key = _norm(entry.title);
                final isSelected = selected.contains(key);

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
            );
          },
        ),
      );
    } else {
      final polys = widget.polygon;
      if (polys != null && polys.isNotEmpty) {
        layers.add(PolygonLayer(polygons: polys));
      }
    }

    // Polylines
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

    // ===== Clusters / Tagged Markers (OAEs etc.)
    final tagged = widget.taggedMarkers;
    final clusterBuilder = widget.clusterWidgetBuilder;
    if (tagged != null && tagged.isNotEmpty && clusterBuilder != null) {
      layers.add(
        clusterBuilder(
          tagged,
          _selectedMarkerPosition,
              (m) {
            _selectedMarkerPosition = m.point;
            setState(() {}); // reflete destaque do marker no builder
          },
        ),
      );
    }

    // Marcadores extras (labels/símbolos) renderizados por cima das linhas
    final extras = widget.extraMarkers;
    if (extras != null && extras.isNotEmpty) {
      // 👇 NÃO dexe essa camada participar do hit-test
      layers.add(
        IgnorePointer(
          ignoring: true, // ← permite que o toque “atravesse” até as polylines
          child: MarkerLayer(markers: extras),
        ),
      );
    }

    // Minha localização (pulsante)
    layers.add(
      ValueListenableBuilder<LatLng?>(
        valueListenable: _userLocationVN,
        builder: (_, pos, __) {
          if (pos == null) return const SizedBox.shrink();
          return MarkerLayer(
            markers: [
              Marker(
                point: pos,
                width: 58,
                height: 58,
                alignment: Alignment.center,
                child: SizedBox(
                  width: 58,
                  height: 58,
                  child: ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue.withOpacity(0.25),
                        border: Border.all(color: Colors.blueAccent, width: 2),
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 10,
                          height: 10,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blueAccent,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    // Pin do ponto ativo (busca/toque)
    if (widget.showSearchMarker) {
      layers.add(
        ValueListenableBuilder<LatLng?>(
          valueListenable: _searchHitVN,
          builder: (_, pos, __) {
            if (pos == null) return const SizedBox.shrink();
            const double pinH = 56.0;
            const double pinW = 44.0;
            return MarkerLayer(
              markers: [
                Marker(
                  point: pos,
                  width: pinW,
                  height: pinH,
                  alignment: Alignment.topCenter,
                  child: const PinChanged(
                    size: pinH,
                    color: Color(0xFFE53935),
                    halo: true,
                    haloOpacity: 0.18,
                    haloScale: 1.8,
                    anchor: PinAnchor.tip,
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    // Attribution OSM
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

    return layers;
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
                      key: const PageStorageKey('siged_flutter_map_camera'),
                      mapController: _mapController,
                      options: MapOptions(
                        backgroundColor: Colors.white,
                        initialCenter: _initCenter,
                        initialZoom: _initZoom,
                        maxZoom: widget.maxZoom ?? 18.4,
                        minZoom: widget.minZoom ?? 5.0,
                        onMapReady: () {
                          widget.onControllerReady?.call(_mapController);

                          // expõe setter do pin para o pai
                          widget.onBindSetActivePoint?.call((LatLng p) {
                            _searchHitVN.value = p;
                          });

                          // restaura última câmera conhecida
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            try {
                              _mapController.move(_lastCenter, _lastZoom);
                              _mapReadyOnce = true;
                            } catch (_) {}
                          });
                        },
                        onTap: _onTapMap,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.pinchZoom |
                          InteractiveFlag.drag |
                          InteractiveFlag.flingAnimation |
                          InteractiveFlag.doubleTapZoom |
                          InteractiveFlag.scrollWheelZoom,
                        ),
                        onMapEvent: (event) {
                          _lastCenter = _mapController.camera.center;
                          _lastZoom = _mapController.camera.zoom;
                          _hasUserMovedCamera = true;

                          widget.onZoomChanged?.call(_lastZoom);
                          widget.onCameraChanged?.call(_lastZoom, _lastCenter);
                        },
                      ),
                      children: _buildMapLayers(),
                    ),

                    if (widget.overlayBuilder != null)
                      Positioned.fill(
                        child: widget.overlayBuilder!(_mapController, _captureKey),
                      ),

                    if (hasLegend) const SizedBox.shrink(),
                  ],
                ),
              ),
            ),
          ],
        ),

        if (hasLegend)
          Positioned(
            left: 8,
            bottom: 8,
            child: MapLegendLayer(regionColors: widget.polygonChangeColors!),
          ),

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
                  child: const Tooltip(
                    message: 'Minha localização',
                    child: _CircleBtn(icon: Icons.pin_drop),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _handleMapSwitchTap,
                  child: Tooltip(
                    message: 'Mapa: ${MapBaseLayer.mapBase[_indexSelectedMap].nome}',
                    child: const _CircleBtn(icon: Icons.map),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSearchActionButton() {
    final builder = widget.searchActionBuilder;
    if (builder != null) return builder(_onSearch);
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

class _CircleBtn extends StatelessWidget {
  const _CircleBtn({required this.icon});
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42,
      height: 42,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black38,
          borderRadius: BorderRadius.circular(90),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}
