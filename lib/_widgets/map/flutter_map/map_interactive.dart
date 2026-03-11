// lib/_widgets/map/flutter_map/map_interactive.dart
import 'dart:async';
import 'dart:ui';

import 'package:diacritic/diacritic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:sipged/_widgets/map/base/map_base_tile_layer.dart';
import 'package:sipged/_widgets/map/flutter_map/map_controls_row.dart';
import 'package:sipged/_widgets/map/flutter_map/map_interactive_helpers.dart';
import 'package:sipged/_widgets/map/flutter_map/map_user_location_layer.dart';
import 'package:sipged/_widgets/map/markers/map_markers_layer.dart';
import 'package:sipged/_widgets/map/pin/map_search_pin_layer.dart';
import 'package:sipged/_widgets/map/polygon/map_polygons_layer.dart';
import 'package:sipged/_widgets/map/polylines/map_polylines_layer.dart';
import 'package:sipged/_widgets/search/search_overlay.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:sipged/_services/map/map_box/service/nominatim_bloc.dart';
import 'package:sipged/_services/map/map_box/service/nominatim_service.dart';

// 🔎 UI de busca
import '../../search/search_widget.dart';
import '../suggestions/suggestion_models.dart';
import '../legend/map_legend_widget.dart';

// 🔔 Notificações
import 'package:sipged/_widgets/notification/app_notification.dart';
import 'package:sipged/_widgets/notification/notification_center.dart';

// ===== Map base / geometry layer
import 'package:sipged/_widgets/map/base/map_base_layer.dart';
import 'package:sipged/_widgets/map/markers/tagged_marker.dart';
import 'package:sipged/_widgets/map/polygon/polygon_changed.dart';
import 'package:sipged/_widgets/map/polylines/tappable_changed_polyline.dart';

class MapInteractivePage<T> extends StatefulWidget {
  // ===== Mapa
  final double? initialZoom;
  final double? maxZoom;
  final double? minZoom;
  final bool activeMap;
  final bool showLegend;

  final bool dropPinOnTap;
  final bool clearMarkerSelectionOnMapTap;

  final Widget Function()? baseTileLayerBuilder;
  final Widget Function(MapController mapController, GlobalKey captureKey)? overlayBuilder;

  // ===== Polylines
  final List<TappableChangedPolyline>? tappablePolylines;
  final Future<void> Function()? onClearPolylineSelection;
  final Future<void> Function(TappableChangedPolyline)? onSelectPolyline;
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
  final Widget Function(
      List<TaggedChangedMarker<T>> taggedMarkers,
      LatLng? selectedMarkerPosition,
      ValueChanged<TaggedChangedMarker<T>> onMarkerSelected,
      )? clusterWidgetBuilder;

  final List<Marker>? extraMarkers;

  // ===== Polígonos (ÚNICO MODELO)
  final List<PolygonChanged>? polygonsChanged;

  /// ✅ Mapa opcional de cores (agora também pinta os polígonos)
  /// Chaves esperadas: title normalizado/UPPER/original.
  final Map<String, Color>? polygonChangeColors;

  // ===== Seleção de regiões
  final bool allowMultiSelect;
  final List<String>? selectedRegionNames;
  final Function(String? region)? onRegionTap;

  // ===== Busca
  final bool showSearch;
  final bool showChangeMapType;
  final bool showMyLocation;
  final Widget Function(void Function(String) onSearch)? searchActionBuilder;
  final double searchTargetZoom;
  final bool showSearchMarker;

  // ===== Camera/Zoom callbacks
  final ValueChanged<double>? onZoomChanged;
  final void Function(double zoom, LatLng center)? onCameraChanged;

  // ===== Sincronização externa
  final void Function(double lat, double lon)? onMapTap;
  final void Function(MapController controller)? onControllerReady;
  final void Function(void Function(LatLng p) setActivePoint)? onBindSetActivePoint;

  /// Lista opcional de pontos usada **apenas** para calcular o centro inicial.
  final List<LatLng>? initialGeometryPoints;

  /// Índice externo do mapa base em [MapBaseLayer.mapBase].
  final int? selectedBaseIndex;

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
    this.polygonsChanged,
    this.polygonChangeColors,
    this.allowMultiSelect = false,
    this.selectedRegionNames,
    this.onRegionTap,
    this.showSearch = false,
    this.showChangeMapType = false,
    this.showMyLocation = false,
    this.searchActionBuilder,
    this.searchTargetZoom = 16,
    this.showSearchMarker = true,
    this.onZoomChanged,
    this.onCameraChanged,
    this.onMapTap,
    this.onControllerReady,
    this.onBindSetActivePoint,
    this.initialGeometryPoints,
    this.selectedBaseIndex,
  });

  @override
  State<MapInteractivePage<T>> createState() => _MapInteractivePageState<T>();
}

class _MapInteractivePageState<T> extends State<MapInteractivePage<T>>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final GlobalKey _captureKey = GlobalKey();

  int _indexSelectedMap = 0;

  // Debounce de eventos de câmera
  Timer? _cameraDebounce;
  static const Duration _kCameraDebounce = Duration(milliseconds: 220);

  static const Duration _kPulseDuration = Duration(seconds: 2);
  late final AnimationController _pulseController =
  AnimationController(vsync: this, duration: _kPulseDuration)..repeat(reverse: true);

  late final Animation<double> _pulseAnimation =
  CurvedAnimation(parent: _pulseController, curve: Curves.easeOut)
      .drive(Tween(begin: 0.6, end: 1.3));

  late NominatimBloc _systemBloc;
  late final NominatimService _geocoder = NominatimService.nominatim(
    userAgent: 'siged-app/1.0 (org.gov.br)',
    acceptLanguage: 'pt-BR',
    countryCodes: 'br',
    limit: 1,
  );

  late final NetworkTileProvider _tileProvider = NetworkTileProvider();

  LatLng? _selectedMarkerPosition;

  // VN (mutáveis, leves)
  final ValueNotifier<LatLng?> _userLocationVN = ValueNotifier<LatLng?>(null);
  final ValueNotifier<LatLng?> _searchHitVN = ValueNotifier<LatLng?>(null);
  final ValueNotifier<Set<String>> _selectedRegionsVN = ValueNotifier<Set<String>>({});

  late double _initZoom;
  late LatLng _initCenter;

  LatLng _lastCenter = const LatLng(-9.65, -36.7);
  double _lastZoom = 9.0;

  // ===== Helpers (performance)
  late final MapInteractiveHelpers _helpers = MapInteractiveHelpers(
    norm: _norm,
  );

  String _norm(String s) =>
      removeDiacritics(s).replaceAll(RegExp(r'\s+'), ' ').trim().toUpperCase();

  bool get _isOsmPublic =>
      MapBaseLayer.mapBase[_indexSelectedMap].url.contains('tile.openstreetmap.org');

  List<PolygonChanged> get _regionalPolys => widget.polygonsChanged ?? const <PolygonChanged>[];

  // ======================================================
  // LIFECYCLE
  // ======================================================

  @override
  void initState() {
    super.initState();

    _initZoom = widget.initialZoom ?? 9.0;

    if (widget.selectedBaseIndex != null &&
        widget.selectedBaseIndex! >= 0 &&
        widget.selectedBaseIndex! < MapBaseLayer.mapBase.length) {
      _indexSelectedMap = widget.selectedBaseIndex!;
    }

    _initCenter = _helpers.computeInitialCenterFromGeometries(
      initialGeometryPoints: widget.initialGeometryPoints,
      polygons: widget.polygonsChanged,
      polylines: widget.tappablePolylines,
      taggedMarkers: widget.taggedMarkers,
      extraMarkers: widget.extraMarkers,
    ) ??
        const LatLng(-9.65, -36.7);

    _lastCenter = _initCenter;
    _lastZoom = _initZoom;

    _helpers.rebuildPolygonBBoxes(regionalPolys: _regionalPolys);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _systemBloc = context.read<NominatimBloc>();

    if (widget.selectedRegionNames != null) {
      _selectedRegionsVN.value = _helpers.toNormSet(widget.selectedRegionNames);
    }
  }

  @override
  void didUpdateWidget(covariant MapInteractivePage<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Sync seleção externa -> VN
    final next = _helpers.toNormSet(widget.selectedRegionNames);
    final prev = _helpers.toNormSet(oldWidget.selectedRegionNames);
    if (!_helpers.sameSet(next, prev) && !_helpers.sameSet(next, _selectedRegionsVN.value)) {
      _selectedRegionsVN.value = next;
    }

    // Sync índice base externo
    if (widget.selectedBaseIndex != null &&
        widget.selectedBaseIndex != oldWidget.selectedBaseIndex &&
        widget.selectedBaseIndex != _indexSelectedMap) {
      final idx = widget.selectedBaseIndex!;
      if (idx >= 0 && idx < MapBaseLayer.mapBase.length) {
        setState(() => _indexSelectedMap = idx);
      }
    }

    // Rebuild bboxes quando lista de polígonos mudar
    _helpers.rebuildPolygonBBoxesIfNeeded(
      oldPolys: oldWidget.polygonsChanged ?? const [],
      newPolys: _regionalPolys,
    );

    // Se antes não tinha geometria e agora tem, recentraliza
    final hadOld = _helpers.hasAnyGeometry(
      initialGeometryPoints: oldWidget.initialGeometryPoints,
      polygons: oldWidget.polygonsChanged,
      polylines: oldWidget.tappablePolylines,
      taggedMarkers: oldWidget.taggedMarkers,
      extraMarkers: oldWidget.extraMarkers,
    );

    final hasNow = _helpers.hasAnyGeometry(
      initialGeometryPoints: widget.initialGeometryPoints,
      polygons: widget.polygonsChanged,
      polylines: widget.tappablePolylines,
      taggedMarkers: widget.taggedMarkers,
      extraMarkers: widget.extraMarkers,
    );

    if (!hadOld && hasNow) {
      final center = _helpers.computeInitialCenterFromGeometries(
        initialGeometryPoints: widget.initialGeometryPoints,
        polygons: widget.polygonsChanged,
        polylines: widget.tappablePolylines,
        taggedMarkers: widget.taggedMarkers,
        extraMarkers: widget.extraMarkers,
      );

      if (center != null) {
        final zoom = (_lastZoom == 0) ? (widget.initialZoom ?? 9.0) : _lastZoom;
        _mapController.move(center, zoom);
        _lastCenter = center;
      }
    }
  }

  @override
  void dispose() {
    _cameraDebounce?.cancel();
    _pulseController.dispose();
    _userLocationVN.dispose();
    _searchHitVN.dispose();
    _selectedRegionsVN.dispose();
    super.dispose();
  }

  // ======================================================
  // HANDLERS
  // ======================================================

  Future<void> _handleMyLocationTap() async {
    final loc = await _systemBloc.getUserCurrentLocation();
    if (!mounted) return;

    if (loc != null) {
      _userLocationVN.value = loc;
      _searchHitVN.value = loc;
      _mapController.move(loc, 16);
      _lastCenter = loc;
      _lastZoom = 16;
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

    // força repaint mantendo camera (evita “pulo”)
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

    final tappedPolyline = tapped.firstWhere(
          (p) => p.hitTestable,
      orElse: () => tapped.first,
    );

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

  void _toggleRegion(String regionKeyNorm) {
    final next = Set<String>.from(_selectedRegionsVN.value);
    if (widget.allowMultiSelect) {
      if (next.contains(regionKeyNorm)) {
        next.remove(regionKeyNorm);
      } else {
        next.add(regionKeyNorm);
      }
    } else {
      next
        ..clear()
        ..add(regionKeyNorm);
    }
    _selectedRegionsVN.value = next;
  }

  String? _getProp(PolygonChanged reg, String keyWanted) =>
      _helpers.getProp(reg, keyWanted);

  Future<void> _onTapMap(TapPosition _, LatLng point) async {
    if (widget.dropPinOnTap) {
      _searchHitVN.value = point;
    }

    widget.onMapTap?.call(point.latitude, point.longitude);

    final regs = _regionalPolys;
    bool hit = false;

    for (final reg in regs) {
      final regionKeyNorm = _norm(reg.title);

      // bbox fast reject
      if (!_helpers.containsInBBox(regionKeyNorm, point)) continue;

      final pts = reg.polygon.points;
      if (pts.isEmpty) continue;

      if (_helpers.pointInPolygon(point, pts)) {
        final isAlreadySelectedSingle = !widget.allowMultiSelect &&
            _selectedRegionsVN.value.length == 1 &&
            _selectedRegionsVN.value.contains(regionKeyNorm);

        if (isAlreadySelectedSingle) {
          _selectedRegionsVN.value = {};

          if (widget.clearMarkerSelectionOnMapTap) {
            _selectedMarkerPosition = null;
            setState(() {});
          }

          widget.onRegionTap?.call(null);
        } else {
          _toggleRegion(regionKeyNorm);

          final regionPayload = _getProp(reg, 'processo') ?? reg.title;
          widget.onRegionTap?.call(regionPayload);
        }

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

  // ======== AUTOCOMPLETE / BUSCA ========

  Future<List<SearchSuggestion<dynamic>>> _fetchAddressSuggestions(String q) async {
    if (q.trim().length < 3) return const [];
    final results = await _geocoder.search(q, limit: 8);
    return results
        .map(
          (r) => SearchSuggestion.address(
        id: r.id,
        title: r.title,
        subtitle: r.city ?? r.state ?? r.country,
        point: r.point,
      ),
    )
        .toList(growable: false);
  }

  void _onSuggestionTap(SearchSuggestion<dynamic> s, void Function(String) onSearch) {
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

    final parsed = _helpers.parseLatLng(q);
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
    _searchHitVN.value = p;
    _mapController.move(p, widget.searchTargetZoom);
    _lastCenter = p;
    _lastZoom = widget.searchTargetZoom;
  }

  void _scheduleCameraCallbacks() {
    _cameraDebounce?.cancel();
    _cameraDebounce = Timer(_kCameraDebounce, () {
      if (!mounted) return;
      final cam = _mapController.camera;
      widget.onZoomChanged?.call(cam.zoom);
      widget.onCameraChanged?.call(cam.zoom, cam.center);
    });
  }

  // ======================================================
  // BUILD
  // ======================================================

  List<Widget> _buildMapChildren() {
    final children = <Widget>[];

    // Base
    if (widget.activeMap) {
      if (widget.baseTileLayerBuilder != null) {
        children.add(widget.baseTileLayerBuilder!());
      } else {
        children.add(
          MapBaseTileLayer(
            tileProvider: _tileProvider,
            urlTemplate: MapBaseLayer.mapBase[_indexSelectedMap].url,
          ),
        );
      }
    }

    // Polígonos
    if (_regionalPolys.isNotEmpty) {
      children.add(
        MapPolygonsLayer(
          mapController: _mapController,
          polygons: _regionalPolys,
          selectedRegionsVN: _selectedRegionsVN,
          polygonChangeColors: widget.polygonChangeColors,
          norm: _norm,
        ),
      );
    }

    // Polylines
    final lines = widget.tappablePolylines;
    if (lines != null && lines.isNotEmpty) {
      children.add(
        MapPolylinesLayer(
          polylines: lines,
          onTap: _handlePolylineTap,
        ),
      );
    }

    // Markers / clusters / extras
    children.add(
      MapMarkersLayer<T>(
        taggedMarkers: widget.taggedMarkers,
        clusterWidgetBuilder: widget.clusterWidgetBuilder,
        selectedMarkerPosition: _selectedMarkerPosition,
        onMarkerSelected: (m) {
          _selectedMarkerPosition = m.point;
          setState(() {});
        },
        extraMarkers: widget.extraMarkers,
      ),
    );

    // Minha localização (pulsante)
    children.add(
      MapUserLocationLayer(
        userLocationVN: _userLocationVN,
        pulseAnimation: _pulseAnimation,
      ),
    );

    // Pin da busca/toque
    if (widget.showSearchMarker) {
      children.add(
        MapSearchPinLayer(
          searchHitVN: _searchHitVN,
        ),
      );
    }

    // Attribution OSM
    if (_isOsmPublic) {
      children.add(
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

    return children;
  }

  @override
  Widget build(BuildContext context) {
    final hasLegend = widget.showLegend && (widget.polygonChangeColors?.isNotEmpty ?? false);

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
                          widget.onBindSetActivePoint?.call((LatLng p) {
                            _searchHitVN.value = p;
                          });
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            try {
                              _mapController.move(_lastCenter, _lastZoom);
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
                        onMapEvent: (_) {
                          _lastCenter = _mapController.camera.center;
                          _lastZoom = _mapController.camera.zoom;
                          _scheduleCameraCallbacks();
                        },
                      ),
                      children: _buildMapChildren(),
                    ),

                    if (widget.overlayBuilder != null)
                      Positioned.fill(
                        child: widget.overlayBuilder!(
                          _mapController,
                          _captureKey,
                        ),
                      ),

                    // mantém o espaço do “if hasLegend”
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
            child: MapLegendLayer(
              regionColors: widget.polygonChangeColors!,
            ),
          ),

        // Controles topo-esquerda (busca, loc, troca mapa)
        Positioned(
          top: 10,
          left: 10,
          child: MapControlsRow(
            showSearch: widget.showSearch,
            showMyLocation: widget.showMyLocation,
            showChangeMapType: widget.showChangeMapType,
            mapName: MapBaseLayer.mapBase[_indexSelectedMap].nome,
            onMyLocationTap: _handleMyLocationTap,
            onMapSwitchTap: _handleMapSwitchTap,
            searchAction: _buildSearchActionButton(),
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
