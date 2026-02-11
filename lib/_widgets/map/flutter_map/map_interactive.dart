// lib/_widgets/map/flutter_map/map_interactive.dart
import 'dart:async';
import 'dart:ui';

import 'package:diacritic/diacritic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:siged/_services/map/map_box/service/nominatim_bloc.dart';
import 'package:siged/_services/map/map_box/service/nominatim_service.dart';
import 'package:siged/_widgets/buttons/mini_circle_button.dart';

// 🔎 UI de busca
import '../../search/search_widget.dart';
import '../suggestions/suggestion_models.dart';
import '../legend/map_legend_widget.dart';
import 'package:siged/_widgets/search/search_overlay.dart';

// 🔔 Notificações
import 'package:siged/_widgets/notification/app_notification.dart';
import 'package:siged/_widgets/notification/notification_center.dart';

// ✅ PIN custom
import 'package:siged/_widgets/map/pin/pin_changed.dart';

// ===== Map base / geometry layers
import 'package:siged/_widgets/map/base/map_base_layer.dart';
import 'package:siged/_widgets/map/markers/tagged_marker.dart';
import 'package:siged/_widgets/map/polygon/polygon_changed.dart';
import 'package:siged/_widgets/map/polylines/tappable_changed_polyline.dart';
import 'package:siged/_widgets/map/polylines/tappable_changed_polyline_layer.dart';

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

  // ===== Polígonos (genéricos)
  final List<Polygon>? polygon;

  // ===== Polígonos regionais
  final List<PolygonChanged>? polygonsChanged;

  /// Mapa opcional de cores para legenda (não altera o estilo dos polígonos).
  final Map<String, Color>? polygonChangeColors;

  /// Lista de chaves (títulos) de polígonos com preenchimento mais forte
  /// (ex.: municípios com contratos). Hoje está aqui só por compatibilidade:
  /// o “forte ou fraco” deve ser definido no próprio PolygonChanged.
  final List<String>? strongPolygonNames;

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
    this.polygon,
    this.polygonsChanged,
    this.polygonChangeColors,
    this.strongPolygonNames,
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

class _BBox {
  final double minLat;
  final double maxLat;
  final double minLng;
  final double maxLng;

  const _BBox({
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
  });

  bool contains(LatLng p) =>
      p.latitude >= minLat &&
          p.latitude <= maxLat &&
          p.longitude >= minLng &&
          p.longitude <= maxLng;

  static _BBox fromPoints(List<LatLng> pts) {
    double minLat = pts.first.latitude;
    double maxLat = pts.first.latitude;
    double minLng = pts.first.longitude;
    double maxLng = pts.first.longitude;

    for (final p in pts) {
      final lat = p.latitude;
      final lng = p.longitude;
      if (lat < minLat) minLat = lat;
      if (lat > maxLat) maxLat = lat;
      if (lng < minLng) minLng = lng;
      if (lng > maxLng) maxLng = lng;
    }

    return _BBox(minLat: minLat, maxLat: maxLat, minLng: minLng, maxLng: maxLng);
  }
}

class _MapInteractivePageState<T> extends State<MapInteractivePage<T>>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final GlobalKey _captureKey = GlobalKey();

  int _indexSelectedMap = 0;

  static const Duration _kPulseDuration = Duration(seconds: 2);

  late final AnimationController _pulseController =
  AnimationController(vsync: this, duration: _kPulseDuration)..repeat(reverse: true);

  late final Animation<double> _pulseAnimation =
  CurvedAnimation(parent: _pulseController, curve: Curves.easeOut)
      .drive(Tween(begin: 0.6, end: 1.3));

  // Debounce de eventos de câmera (reduz “tempestade” de callbacks)
  Timer? _cameraDebounce;
  static const Duration _kCameraDebounce = Duration(milliseconds: 220);

  late NominatimBloc _systemBloc;
  late final NominatimService _geocoder = NominatimService.nominatim(
    userAgent: 'siged-app/1.0 (org.gov.br)',
    acceptLanguage: 'pt-BR',
    countryCodes: 'br',
    limit: 1,
  );

  late final NetworkTileProvider _tileProvider = NetworkTileProvider();

  LatLng? _selectedMarkerPosition;

  final ValueNotifier<LatLng?> _userLocationVN = ValueNotifier<LatLng?>(null);
  final ValueNotifier<LatLng?> _searchHitVN = ValueNotifier<LatLng?>(null);
  final ValueNotifier<Set<String>> _selectedRegionsVN = ValueNotifier<Set<String>>({});

  late double _initZoom;
  late LatLng _initCenter;

  LatLng _lastCenter = const LatLng(-9.65, -36.7);
  double _lastZoom = 9.0;

  String _norm(String s) =>
      removeDiacritics(s).replaceAll(RegExp(r'\s+'), ' ').trim().toUpperCase();

  Set<String> _toNormSet(List<String>? lst) =>
      lst == null ? <String>{} : lst.map(_norm).toSet();

  bool _sameSet(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);

  bool get _isOsmPublic =>
      MapBaseLayer.mapBase[_indexSelectedMap].url.contains('tile.openstreetmap.org');

  // Cache de bbox por polígono (acelera hit-test)
  final Map<String, _BBox> _bboxByRegionNorm = <String, _BBox>{};

  // ======================================================
  // HELPERS PARA CENTRALIZAR O MAPA COM BASE NAS GEOMETRIAS
  // ======================================================

  List<LatLng> _collectAllGeometryPointsFor(MapInteractivePage<T> w) {
    if (w.initialGeometryPoints != null && w.initialGeometryPoints!.isNotEmpty) {
      return List<LatLng>.from(w.initialGeometryPoints!);
    }

    final pts = <LatLng>[];

    // 1) Polígonos regionais (PolygonChanged)
    final regs = w.polygonsChanged ?? const <PolygonChanged>[];
    for (final reg in regs) {
      pts.addAll(reg.polygon.points);
    }

    // 2) Polígonos genéricos
    final polys = w.polygon;
    if (polys != null && polys.isNotEmpty) {
      for (final poly in polys) {
        pts.addAll(poly.points);
      }
    }

    // 3) Polylines
    final lines = w.tappablePolylines;
    if (lines != null && lines.isNotEmpty) {
      for (final line in lines) {
        pts.addAll(line.points);
      }
    }

    // 4) Marcadores com tag
    final tagged = w.taggedMarkers;
    if (tagged != null && tagged.isNotEmpty) {
      for (final m in tagged) {
        pts.add(m.point);
      }
    }

    // 5) Marcadores extras
    final extras = w.extraMarkers;
    if (extras != null && extras.isNotEmpty) {
      for (final m in extras) {
        pts.add(m.point);
      }
    }

    return pts;
  }

  bool _hasAnyGeometryFor(MapInteractivePage<T> w) =>
      _collectAllGeometryPointsFor(w).isNotEmpty;

  LatLng? _computeInitialCenterFromGeometriesFor(MapInteractivePage<T> w) {
    final pts = _collectAllGeometryPointsFor(w);
    if (pts.isEmpty) return null;

    double minLat = pts.first.latitude;
    double maxLat = pts.first.latitude;
    double minLng = pts.first.longitude;
    double maxLng = pts.first.longitude;

    for (final p in pts) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    return LatLng((minLat + maxLat) / 2.0, (minLng + maxLng) / 2.0);
  }

  LatLng? _computeInitialCenterFromGeometries() =>
      _computeInitialCenterFromGeometriesFor(widget);

  List<PolygonChanged> get _regionalPolys =>
      widget.polygonsChanged ?? const <PolygonChanged>[];

  void _rebuildBBoxesIfNeeded({List<PolygonChanged>? oldRegs}) {
    final regs = _regionalPolys;

    // Heurística simples: se a instância da lista mudou ou o tamanho mudou, refaz bbox.
    final shouldRebuild = oldRegs == null ||
        !identical(oldRegs, regs) ||
        (oldRegs.length != regs.length);

    if (!shouldRebuild) return;

    _bboxByRegionNorm.clear();
    for (final reg in regs) {
      final pts = reg.polygon.points;
      if (pts.isEmpty) continue;
      final keyNorm = _norm(reg.title);
      _bboxByRegionNorm[keyNorm] = _BBox.fromPoints(pts);
    }
  }

  @override
  void initState() {
    super.initState();

    _initZoom = widget.initialZoom ?? 9.0;

    if (widget.selectedBaseIndex != null &&
        widget.selectedBaseIndex! >= 0 &&
        widget.selectedBaseIndex! < MapBaseLayer.mapBase.length) {
      _indexSelectedMap = widget.selectedBaseIndex!;
    }

    final centerFromData = _computeInitialCenterFromGeometries();
    _initCenter = centerFromData ?? const LatLng(-9.65, -36.7);

    _lastCenter = _initCenter;
    _lastZoom = _initZoom;

    _rebuildBBoxesIfNeeded(oldRegs: null);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _systemBloc = context.read<NominatimBloc>();
    if (widget.selectedRegionNames != null) {
      _selectedRegionsVN.value = _toNormSet(widget.selectedRegionNames);
    }
  }

  @override
  void didUpdateWidget(covariant MapInteractivePage<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    final next = _toNormSet(widget.selectedRegionNames);
    final prev = _toNormSet(oldWidget.selectedRegionNames);
    if (!_sameSet(next, prev) && !_sameSet(next, _selectedRegionsVN.value)) {
      _selectedRegionsVN.value = next;
    }

    if (widget.selectedBaseIndex != null &&
        widget.selectedBaseIndex != oldWidget.selectedBaseIndex &&
        widget.selectedBaseIndex != _indexSelectedMap) {
      final idx = widget.selectedBaseIndex!;
      if (idx >= 0 && idx < MapBaseLayer.mapBase.length) {
        setState(() {
          _indexSelectedMap = idx;
        });
      }
    }

    // Rebuild bbox se mudou a lista de polígonos regionais
    _rebuildBBoxesIfNeeded(oldRegs: oldWidget.polygonsChanged ?? const []);

    final hadOld = _hasAnyGeometryFor(oldWidget);
    final hasNow = _hasAnyGeometryFor(widget);

    if (!hadOld && hasNow) {
      final center = _computeInitialCenterFromGeometries();
      if (center != null) {
        final zoom = _lastZoom == 0 ? (widget.initialZoom ?? 9.0) : _lastZoom;
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
  // HANDLERS / FUNÇÕES
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
    setState(
          () => _indexSelectedMap = (_indexSelectedMap + 1) % MapBaseLayer.mapBase.length,
    );
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

    // Segurança extra: se alguma entrou por engano
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

  bool _pointInPolygon(LatLng p, List<LatLng> pts) {
    // ray casting (latitude como x, longitude como y)
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

  String? _getProp(PolygonChanged reg, String keyWanted) {
    final wanted = _norm(keyWanted);
    final props = reg.properties;
    if (props is! List<Map<String, dynamic>>) return null;
    for (final m in props) {
      for (final e in m.entries) {
        if (_norm(e.key) == wanted) {
          final v = e.value;
          if (v is String && v.trim().isNotEmpty) return v.trim();
        }
      }
    }
    return null;
  }

  Future<void> _onTapMap(TapPosition _, LatLng point) async {
    if (widget.dropPinOnTap) {
      _searchHitVN.value = point;
    }

    // callback externo de clique no mapa (sempre)
    widget.onMapTap?.call(point.latitude, point.longitude);

    // Hit-test de regiões (com bbox antes do point-in-polygon)
    final regs = _regionalPolys;
    bool hit = false;

    for (final reg in regs) {
      final regionKeyNorm = _norm(reg.title);

      final bbox = _bboxByRegionNorm[regionKeyNorm];
      if (bbox != null && !bbox.contains(point)) {
        continue; // corta 90% do custo
      }

      final pts = reg.polygon.points;
      if (pts.isEmpty) continue;

      if (_pointInPolygon(point, pts)) {
        // 👉 Se NÃO for multi-select e esse já for o único selecionado,
        //    então o clique atual serve para DESSELECIONAR.
        final isAlreadySelectedSingle = !widget.allowMultiSelect &&
            _selectedRegionsVN.value.length == 1 &&
            _selectedRegionsVN.value.contains(regionKeyNorm);

        if (isAlreadySelectedSingle) {
          // 2º clique no mesmo polígono → limpa seleção
          _selectedRegionsVN.value = {};

          if (widget.clearMarkerSelectionOnMapTap) {
            _selectedMarkerPosition = null;
            setState(() {});
          }

          widget.onRegionTap?.call(null);
        } else {
          _toggleRegion(regionKeyNorm);

          final processo = _getProp(reg, 'processo') ?? reg.title;
          widget.onRegionTap?.call(processo);
        }

        hit = true;
        break;
      }
    }

    // Clique em área sem polígono → limpa seleção
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

  Future<List<SearchSuggestion>> _fetchAddressSuggestions(String q) async {
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
    _searchHitVN.value = p;
    _mapController.move(p, widget.searchTargetZoom);
    _lastCenter = p;
    _lastZoom = widget.searchTargetZoom;
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

  void _scheduleCameraCallbacks() {
    _cameraDebounce?.cancel();
    _cameraDebounce = Timer(_kCameraDebounce, () {
      if (!mounted) return;
      final cam = _mapController.camera;
      widget.onZoomChanged?.call(cam.zoom);
      widget.onCameraChanged?.call(cam.zoom, cam.center);
    });
  }

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
            keepBuffer: 2, // ↓ leve redução (antes 3)
            maxNativeZoom: 19,
            minNativeZoom: 0,
          ),
        );
      }
    }

    // ===== Polígonos regionais (PolygonChanged) =====
    final regional = _regionalPolys;
    if (regional.isNotEmpty) {
      layers.add(
        ValueListenableBuilder<Set<String>>(
          valueListenable: _selectedRegionsVN,
          builder: (_, selected, _) {
            return PolygonLayer(
              polygons: regional.map((entry) {
                final poly = entry.polygon;
                final titleNorm = _norm(entry.title);
                final isSelected = selected.contains(titleNorm);

                return Polygon(
                  points: poly.points,
                  color: isSelected ? entry.selectedFillColor : entry.normalFillColor,
                  borderColor:
                  isSelected ? entry.selectedBorderColor : entry.normalBorderColor,
                  borderStrokeWidth:
                  isSelected ? entry.selectedBorderWidth : entry.normalBorderWidth,
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

    // Polylines (tappable + não tappable)
    final lines = widget.tappablePolylines;
    if (lines != null && lines.isNotEmpty) {
      final tappable = lines.where((p) => p.hitTestable).toList(growable: false);
      final nonTappable = lines.where((p) => !p.hitTestable).toList(growable: false);

      // Renderiza linhas não-clicáveis de forma leve
      if (nonTappable.isNotEmpty) {
        layers.add(
          PolylineLayer(
            polylines: nonTappable
                .map(
                  (p) => Polyline(
                points: p.points,
                color: p.color,
                strokeWidth: p.strokeWidth,
              ),
            )
                .toList(),
          ),
        );
      }

      // Layer clicável (com culling ligado!)
      if (tappable.isNotEmpty) {
        layers.add(
          MapTappablePolylineLayer(
            polylines: tappable,
            onTap: _handlePolylineTap,
            polylineCulling: true, // ✅ MUITO importante para performance
          ),
        );
      }
    }

    // Clusters / Tagged Markers
    final tagged = widget.taggedMarkers;
    final clusterBuilder = widget.clusterWidgetBuilder;
    if (tagged != null && tagged.isNotEmpty && clusterBuilder != null) {
      layers.add(
        clusterBuilder(
          tagged,
          _selectedMarkerPosition,
              (m) {
            _selectedMarkerPosition = m.point;
            setState(() {});
          },
        ),
      );
    }

    // Marcadores extras
    final extras = widget.extraMarkers;
    if (extras != null && extras.isNotEmpty) {
      layers.add(
        IgnorePointer(
          ignoring: true,
          child: MarkerLayer(markers: extras),
        ),
      );
    }

    // Minha localização (pulsante)
    layers.add(
      ValueListenableBuilder<LatLng?>(
        valueListenable: _userLocationVN,
        builder: (_, pos, _) {
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

    // Pin da busca/toque
    if (widget.showSearchMarker) {
      layers.add(
        ValueListenableBuilder<LatLng?>(
          valueListenable: _searchHitVN,
          builder: (_, pos, _) {
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
                        onMapEvent: (event) {
                          // Atualiza sempre o “último estado” local
                          _lastCenter = _mapController.camera.center;
                          _lastZoom = _mapController.camera.zoom;

                          // ✅ Debounce para não martelar callbacks / cubits
                          _scheduleCameraCallbacks();
                        },
                      ),
                      children: _buildMapLayers(),
                    ),

                    if (widget.overlayBuilder != null)
                      Positioned.fill(
                        child: widget.overlayBuilder!(
                          _mapController,
                          _captureKey,
                        ),
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
            child: MapLegendLayer(
              regionColors: widget.polygonChangeColors!,
            ),
          ),

        Positioned(
          top: 10,
          left: 10,
          child: Row(
            children: () {
              final children = <Widget>[];

              if (widget.showSearch) {
                children.add(_buildSearchActionButton());
              }

              if (widget.showMyLocation) {
                if (children.isNotEmpty) {
                  children.add(const SizedBox(width: 8));
                }
                children.add(
                  InkWell(
                    onTap: _handleMyLocationTap,
                    child: const Tooltip(
                      message: 'Minha localização',
                      child: MiniCircleButton(icon: Icons.pin_drop),
                    ),
                  ),
                );
              }

              if (widget.showChangeMapType) {
                if (children.isNotEmpty) {
                  children.add(const SizedBox(width: 8));
                }
                children.add(
                  InkWell(
                    onTap: _handleMapSwitchTap,
                    child: Tooltip(
                      message: 'Mapa: ${MapBaseLayer.mapBase[_indexSelectedMap].nome}',
                      child: const MiniCircleButton(icon: Icons.map),
                    ),
                  ),
                );
              }

              return children;
            }(),
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
