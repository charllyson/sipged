import 'dart:async';

import 'package:diacritic/diacritic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:sipged/_widgets/map/polylines/polyline_changed_layer.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:sipged/_services/map/map_box/service/nominatim_bloc.dart';
import 'package:sipged/_services/map/map_box/service/nominatim_service.dart';

import 'package:sipged/_widgets/map/base/map_flutter_types.dart';
import 'package:sipged/_widgets/map/base/map_flutter_layer.dart';
import 'package:sipged/_widgets/map/flutter_map/map_interactive_helpers.dart';
import 'package:sipged/_widgets/map/flutter_map/map_top_buttons.dart';
import 'package:sipged/_widgets/map/flutter_map/map_user_location.dart';
import 'package:sipged/_widgets/map/legend/legend_widget.dart';
import 'package:sipged/_widgets/map/markers/marker_changed_data.dart';
import 'package:sipged/_widgets/map/markers/marker_changed_layer.dart';
import 'package:sipged/_widgets/map/pin/pin_search.dart';
import 'package:sipged/_widgets/map/polygon/polygon_changed_data.dart';
import 'package:sipged/_widgets/map/polygon/polygon_changed_layer.dart';
import 'package:sipged/_widgets/map/polylines/polyline_changed_data.dart';
import 'package:sipged/_widgets/map/suggestions/search_suggestion.dart';
import 'package:sipged/_widgets/notification/app_notification.dart';
import 'package:sipged/_widgets/notification/notification_center.dart';
import 'package:sipged/_widgets/search/search_overlay.dart';
import 'package:sipged/_widgets/search/search_widget.dart';

class MapInteractivePage<T> extends StatefulWidget {
  final double? initialZoom;
  final double? maxZoom;
  final double? minZoom;
  final bool activeMap;
  final bool showLegend;
  final bool dropPinOnTap;
  final bool clearMarkerSelectionOnMapTap;
  final Widget Function()? baseTileLayerBuilder;
  final Widget Function(
      MapController mapController,
      GlobalKey captureKey,
      )? overlayBuilder;

  final List<PolylineChangedData>? tappablePolylines;
  final Future<void> Function()? onClearPolylineSelection;
  final Future<void> Function(PolylineChangedData)? onSelectPolyline;

  final void Function({
  required BuildContext context,
  required Offset position,
  required Object? tag,
  required MapController mapController,
  LatLng? tapLatLng,
  Offset Function(Offset local)? toGlobal,
  })? onShowPolylineTooltip;

  final List<MarkerChangedData<T>>? taggedMarkers;

  final Widget Function(
      List<MarkerChangedData<T>> taggedMarkers,
      LatLng? selectedMarkerPosition,
      ValueChanged<MarkerChangedData<T>> onMarkerSelected,
      )? clusterWidgetBuilder;

  final List<Marker>? extraMarkers;

  final List<PolygonChangedData>? polygonsChanged;
  final Map<String, Color>? polygonChangeColors;

  final bool allowMultiSelect;
  final List<String>? selectedRegionNames;
  final Function(String? region)? onRegionTap;

  final bool showSearch;
  final bool showChangeMapType;
  final bool showMyLocation;
  final Widget Function(void Function(String) onSearch)? searchActionBuilder;
  final double searchTargetZoom;
  final bool showSearchMarker;

  final ValueChanged<double>? onZoomChanged;
  final void Function(double zoom, LatLng center)? onCameraChanged;

  final void Function(double lat, double lon)? onMapTap;
  final void Function(MapController controller)? onControllerReady;
  final void Function(void Function(LatLng p) setActivePoint)? onBindSetActivePoint;

  final List<LatLng>? initialGeometryPoints;
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

  Timer? _cameraDebounce;
  static const Duration _kCameraDebounce = Duration(milliseconds: 220);

  static const Duration _kPulseDuration = Duration(seconds: 2);
  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: _kPulseDuration,
  )..repeat(reverse: true);

  late final Animation<double> _pulseAnimation =
  CurvedAnimation(parent: _pulseController, curve: Curves.easeOut).drive(
    Tween(begin: 0.6, end: 1.3),
  );

  late NominatimBloc _systemBloc;

  late final NominatimService _geocoder = NominatimService.nominatim(
    userAgent: 'siged-app/1.0 (org.gov.br)',
    acceptLanguage: 'pt-BR',
    countryCodes: 'br',
    limit: 1,
  );

  late final NetworkTileProvider _tileProvider = NetworkTileProvider();

  final ValueNotifier<LatLng?> _userLocationVN = ValueNotifier<LatLng?>(null);
  final ValueNotifier<LatLng?> _searchHitVN = ValueNotifier<LatLng?>(null);
  final ValueNotifier<Set<String>> _selectedRegionsVN =
  ValueNotifier<Set<String>>({});
  final ValueNotifier<LatLng?> _selectedMarkerPositionVN =
  ValueNotifier<LatLng?>(null);

  late double _initZoom;
  late LatLng _initCenter;

  LatLng _lastCenter = const LatLng(-9.65, -36.7);
  double _lastZoom = 9.0;

  late final MapInteractiveHelpers _helpers =
  MapInteractiveHelpers(norm: _norm);

  String _norm(String s) =>
      removeDiacritics(s).replaceAll(RegExp(r'\s+'), ' ').trim().toUpperCase();

  bool get _isOsmPublic => MapFlutterTypes.mapBase[_indexSelectedMap]
      .url
      .contains('tile.openstreetmap.org');

  List<PolygonChangedData> get _regionalPolys =>
      widget.polygonsChanged ?? const <PolygonChangedData>[];

  @override
  void initState() {
    super.initState();

    _initZoom = widget.initialZoom ?? 9.0;

    if (widget.selectedBaseIndex != null &&
        widget.selectedBaseIndex! >= 0 &&
        widget.selectedBaseIndex! < MapFlutterTypes.mapBase.length) {
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

    final next = _helpers.toNormSet(widget.selectedRegionNames);
    final prev = _helpers.toNormSet(oldWidget.selectedRegionNames);

    if (!_helpers.sameSet(next, prev) &&
        !_helpers.sameSet(next, _selectedRegionsVN.value)) {
      _selectedRegionsVN.value = next;
    }

    if (widget.selectedBaseIndex != null &&
        widget.selectedBaseIndex != oldWidget.selectedBaseIndex &&
        widget.selectedBaseIndex != _indexSelectedMap) {
      final idx = widget.selectedBaseIndex!;
      if (idx >= 0 && idx < MapFlutterTypes.mapBase.length) {
        setState(() => _indexSelectedMap = idx);
      }
    }

    _helpers.rebuildPolygonBBoxesIfNeeded(
      oldPolys: oldWidget.polygonsChanged ?? const [],
      newPolys: _regionalPolys,
    );

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
    _selectedMarkerPositionVN.dispose();
    super.dispose();
  }

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
          title: const Text('Minha localização centralizada'),
          type: AppNotificationType.success,
        ),
      );
      return;
    }

    NotificationCenter.instance.show(
      AppNotification(
        title: const Text('Não foi possível obter sua localização'),
        type: AppNotificationType.error,
      ),
    );
  }

  void _handleMapSwitchTap() {
    setState(() {
      _indexSelectedMap =
          (_indexSelectedMap + 1) % MapFlutterTypes.mapBase.length;
    });

    Future.microtask(() {
      try {
        final c = _mapController.camera.center;
        final z = _mapController.camera.zoom;
        _mapController.move(c, z);
      } catch (_) {}
    });

    NotificationCenter.instance.show(
      AppNotification(
        title: Text('Mapa: ${MapFlutterTypes.mapBase[_indexSelectedMap].nome}'),
        type: AppNotificationType.info,
      ),
    );
  }

  Future<void> _handlePolylineTap(
      List<PolylineChangedData> tapped,
      TapUpDetails details,
      ) async {
    if (tapped.isEmpty) return;

    final tappedPolyline = tapped.firstWhere(
          (p) => p.hitTestable,
      orElse: () => tapped.first,
    );

    await widget.onSelectPolyline?.call(tappedPolyline);

    final onShow = widget.onShowPolylineTooltip;
    if (onShow == null) return;

    Offset Function(Offset local)? toGlobal;
    final rb = _captureKey.currentContext?.findRenderObject() as RenderBox?;
    if (rb != null) {
      toGlobal = rb.localToGlobal;
    }

    final tapLatLng =
    _mapController.camera.screenOffsetToLatLng(details.localPosition);

    if (!mounted) return;

    onShow(
      context: context,
      position: details.globalPosition,
      tag: tappedPolyline.tag,
      mapController: _mapController,
      tapLatLng: tapLatLng,
      toGlobal: toGlobal,
    );
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

  String? _getProp(PolygonChangedData reg, String keyWanted) {
    return _helpers.getProp(reg, keyWanted);
  }

  Future<void> _onTapMap(TapPosition _, LatLng point) async {
    if (widget.dropPinOnTap) {
      _searchHitVN.value = point;
    }

    widget.onMapTap?.call(point.latitude, point.longitude);

    bool hit = false;
    final regs = _regionalPolys;

    for (final reg in regs) {
      final regionKeyNorm = _norm(reg.title);

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
            _selectedMarkerPositionVN.value = null;
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
        _selectedMarkerPositionVN.value = null;
      }

      widget.onRegionTap?.call(null);
    }
  }

  Future<List<SearchSuggestion<dynamic>>> _fetchAddressSuggestions(
      String q,
      ) async {
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

  void _onSuggestionTap(
      SearchSuggestion<dynamic> s,
      void Function(String) onSearch,
      ) {
    final data = s.data;
    if (data is LatLng) {
      onSearch('${data.latitude},${data.longitude}');
      return;
    }
    onSearch(s.title);
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
        title: const Text('Não encontrado'),
        subtitle: const Text('Tente “lat, lng” ou refine a busca.'),
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

  List<Widget> _buildMapChildren() {
    final children = <Widget>[];

    if (widget.activeMap) {
      if (widget.baseTileLayerBuilder != null) {
        children.add(widget.baseTileLayerBuilder!());
      } else {
        children.add(
          MapFlutterLayer(
            tileProvider: _tileProvider,
            urlTemplate: MapFlutterTypes.mapBase[_indexSelectedMap].url,
          ),
        );
      }
    }

    if (_regionalPolys.isNotEmpty) {
      children.add(
        PolygonChangedLayer(
          mapController: _mapController,
          polygons: _regionalPolys,
          selectedRegionsVN: _selectedRegionsVN,
          polygonChangeColors: widget.polygonChangeColors,
          norm: _norm,
        ),
      );
    }

    final lines = widget.tappablePolylines;
    if (lines != null && lines.isNotEmpty) {
      children.add(
        PolylineChangedLayer(
          polylines: lines,
          culling: true,
          pointerDistanceTolerance: 15,
          onTap: _handlePolylineTap,
          onMiss: (_) async {
            await widget.onClearPolylineSelection?.call();
          },
        ),
      );
    }

    children.add(
      MarkerChangedLayer<T>(
        taggedMarkers: widget.taggedMarkers,
        clusterWidgetBuilder: widget.clusterWidgetBuilder,
        selectedMarkerPositionVN: _selectedMarkerPositionVN,
        onMarkerSelected: (m) {
          _selectedMarkerPositionVN.value = m.point;
        },
        extraMarkers: widget.extraMarkers,
      ),
    );

    children.add(
      MapUserLocation(
        userLocationVN: _userLocationVN,
        pulseAnimation: _pulseAnimation,
      ),
    );

    if (widget.showSearchMarker) {
      children.add(
        PinSearch(searchHitVN: _searchHitVN),
      );
    }

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

  @override
  Widget build(BuildContext context) {
    final hasLegend =
        widget.showLegend && (widget.polygonChangeColors?.isNotEmpty ?? false);

    return Stack(
      children: [
        RepaintBoundary(
          key: _captureKey,
          child: FlutterMap(
            key: const PageStorageKey('siged_flutter_map_camera'),
            mapController: _mapController,
            options: MapOptions(
              backgroundColor: Colors.white,
              initialCenter: _initCenter,
              initialZoom: _initZoom,
              maxZoom: widget.maxZoom ?? 18.4,
              minZoom: widget.minZoom ?? 5.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.pinchZoom |
                InteractiveFlag.drag |
                InteractiveFlag.flingAnimation |
                InteractiveFlag.doubleTapZoom |
                InteractiveFlag.scrollWheelZoom,
              ),
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
              onMapEvent: (_) {
                _lastCenter = _mapController.camera.center;
                _lastZoom = _mapController.camera.zoom;
                _scheduleCameraCallbacks();
              },
            ),
            children: _buildMapChildren(),
          ),
        ),
        if (widget.overlayBuilder != null)
          Positioned.fill(
            child: widget.overlayBuilder!(
              _mapController,
              _captureKey,
            ),
          ),
        if (hasLegend)
          Positioned(
            left: 8,
            bottom: 8,
            child: LegendWidged(
              regionColors: widget.polygonChangeColors!,
            ),
          ),
        Positioned(
          top: 10,
          left: 10,
          child: MapTopButtons(
            showSearch: widget.showSearch,
            showMyLocation: widget.showMyLocation,
            showChangeMapType: widget.showChangeMapType,
            mapName: MapFlutterTypes.mapBase[_indexSelectedMap].nome,
            onMyLocationTap: _handleMyLocationTap,
            onMapSwitchTap: _handleMapSwitchTap,
            searchAction: _buildSearchActionButton(),
          ),
        ),
      ],
    );
  }
}