import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:sipged/_blocs/modules/planning/geo/feature/feature_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data.dart';
import 'package:sipged/_widgets/buttons/slider_control.dart';

import 'package:sipged/_widgets/map/base/map_type_button.dart';
import 'package:sipged/_widgets/map/base/map_types.dart';

import 'package:sipged/_widgets/map/map/map_cache.dart';
import 'package:sipged/_widgets/map/map/map_hit_test.dart';
import 'package:sipged/_widgets/map/map/map_layers.dart';

import 'package:sipged/_widgets/map/my_location/my_location.dart';
import 'package:sipged/_widgets/map/my_location/pin_user_location.dart';
import 'package:sipged/_widgets/map/pin/pin_changed.dart';
import 'package:sipged/_widgets/map/search/search_map.dart';

typedef MapExternalPolylineTooltipCallback = FutureOr<void> Function({
required BuildContext context,
required Offset position,
required Object? tag,
required MapController mapController,
LatLng? tapLatLng,
Offset Function(Offset p)? toGlobal,
});

class MapChange extends StatefulWidget {
  const MapChange({
    super.key,
    required this.features,
    required this.layersById,
    required this.orderedActiveLayerIds,
    required this.onFeatureTap,
    required this.onControllerReady,
    required this.visualDataSignature,
    this.onCameraChanged,
    this.selectedFeatureKey,
    this.loading = false,
    this.onBackgroundTap,
    this.temporaryPointLayers = const {},
    this.temporaryLineLayers = const {},
    this.temporaryPolygonLayers = const {},
    this.distanceMeasurementPoints = const [],
    this.cursor = SystemMouseCursors.basic,
    this.initialCenter = const LatLng(-9.5713, -36.7820),
    this.initialZoom = 9.0,
    this.minZoom,
    this.maxZoom,
    this.showSearch = true,
    this.showControls = true,
    this.showZoomSlider = true,
    this.showMapTypeButton = true,
    this.showRotationButton = true,
    this.zoomSliderLeading,
    this.zoomSliderLeadingSpacing = 12,
    this.zoomSliderLeadingMaxWidth = 520,
    this.enableZoom = true,
    this.enablePan = true,
    this.enableRotation = true,
    this.initialGeometryPoints = const <LatLng>[],
    this.fitInitialGeometryOnce = false,
    this.externalPolygons = const <Polygon<Map<String, dynamic>>>[],
    this.onExternalPolygonTap,
    this.externalPolylines = const <Polyline<Object>>[],
    this.onExternalPolylineTap,
    this.onClearExternalPolylineSelection,
    this.onShowExternalPolylineTooltip,
    this.externalMarkers = const <Marker>[],
  });

  final List<FeatureData> features;
  final Map<String, LayerData> layersById;
  final List<String> orderedActiveLayerIds;

  final void Function(FeatureData? feature) onFeatureTap;
  final void Function(MapController controller) onControllerReady;
  final void Function(LatLng center, double zoom)? onCameraChanged;

  final String? selectedFeatureKey;
  final bool loading;
  final Object visualDataSignature;

  /// Retorne true para consumir o toque e impedir hit test nas camadas.
  final bool Function(LatLng latLng)? onBackgroundTap;

  final Map<String, List<LatLng>> temporaryPointLayers;
  final Map<String, List<LatLng>> temporaryLineLayers;
  final Map<String, List<LatLng>> temporaryPolygonLayers;

  final List<LatLng> distanceMeasurementPoints;
  final MouseCursor cursor;

  final LatLng initialCenter;
  final double initialZoom;
  final double? minZoom;
  final double? maxZoom;

  final bool showSearch;
  final bool showControls;

  /// Exibe ou oculta o SliderButton lateral de zoom.
  final bool showZoomSlider;

  /// Exibe ou oculta o botão de troca do tipo de mapa.
  final bool showMapTypeButton;

  /// Reservado para controle de rotação, caso você use em outra versão.
  final bool showRotationButton;

  /// Widget posicionado visualmente à direita do SliderButton lateral.
  ///
  /// Mantive o nome [zoomSliderLeading] para não quebrar chamadas existentes.
  /// Útil para injetar controles específicos da página, como menu de serviços,
  /// botão de recentralizar, seleção múltipla etc.
  final Widget? zoomSliderLeading;

  /// Espaçamento horizontal entre o SliderButton e [zoomSliderLeading].
  final double zoomSliderLeadingSpacing;

  /// Largura máxima permitida para o widget ao lado direito do slider.
  final double zoomSliderLeadingMaxWidth;

  /// Permite ou bloqueia zoom por gesto, scroll, duplo toque e controles.
  final bool enableZoom;

  /// Permite ou bloqueia arrastar/mover o mapa.
  final bool enablePan;

  /// Permite ou bloqueia rotação por gesto.
  final bool enableRotation;

  final List<LatLng> initialGeometryPoints;
  final bool fitInitialGeometryOnce;

  /// Polígonos externos independentes de FeatureData/LayerData.
  final List<Polygon<Map<String, dynamic>>> externalPolygons;
  final void Function(Polygon<Map<String, dynamic>>? polygon)?
  onExternalPolygonTap;

  /// Linhas externas independentes de FeatureData/LayerData.
  final List<Polyline<Object>> externalPolylines;
  final FutureOr<void> Function(Polyline<Object> polyline)?
  onExternalPolylineTap;
  final FutureOr<void> Function()? onClearExternalPolylineSelection;
  final MapExternalPolylineTooltipCallback? onShowExternalPolylineTooltip;

  /// Marcadores externos independentes de FeatureData/LayerData.
  final List<Marker> externalMarkers;

  @override
  State<MapChange> createState() => _MapChangeState();
}

class _MapChangeState extends State<MapChange>
    with SingleTickerProviderStateMixin {
  late final MapController _controller;

  final GlobalKey _mapStackKey = GlobalKey();

  final ValueNotifier<LatLng?> _userLocationVN = ValueNotifier<LatLng?>(null);
  final ValueNotifier<LatLng?> _searchHitVN = ValueNotifier<LatLng?>(null);
  final ValueNotifier<double> _zoomVN = ValueNotifier<double>(7.0);

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  static const String _fallbackTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  static const double _viewportPaddingFactor = 0.20;
  static const double _minViewportPadDegrees = 0.0025;

  bool _mapReady = false;
  bool _cacheReady = false;
  bool _hasFitInitialGeometryOnce = false;

  int _selectedMapIndex = 0;
  bool _mapTypeExpanded = false;

  late double _lastKnownZoom;
  late LatLng _lastKnownCenter;

  int _lastStaticVisualSignature = 0;
  int _lastMarkerVisualSignature = 0;
  int _lastHitEntriesSignature = 0;

  double _lastMarkerZoomBucket = -999.0;
  double _lastStaticZoomBucket = -999.0;
  int _lastVisibleViewportSignature = -1;

  Map<String, List<FeatureData>> _allFeaturesByLayer = const {};
  Map<String, List<FeatureData>> _featuresByLayer = const {};
  List<FeatureData> _visibleFeatures = const [];

  List<Polygon> _cachedPolygons = const [];
  List<Polyline> _cachedPolylines = const [];
  List<Marker> _cachedMarkers = const [];
  List<Marker> _cachedLabelMarkers = const [];
  List<FeatureHitEntry> _cachedHitEntries = const [];

  final Map<String, _FeatureBoundsCacheEntry> _featureBoundsCache =
  <String, _FeatureBoundsCacheEntry>{};

  List<FeatureData>? _lastVisibleFeaturesSourceRef;
  List<FeatureData>? _lastFeaturesByLayerVisibleRef;
  List<FeatureData>? _lastAllFeaturesSourceRef;

  Timer? _cameraDebounce;

  @override
  void initState() {
    super.initState();

    _lastKnownCenter = widget.initialCenter;
    _lastKnownZoom = widget.initialZoom;
    _zoomVN.value = widget.initialZoom;

    _controller = MapController();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 0.75,
      end: 1.35,
    ).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _refreshAllCaches(immediateSetState: true);
      _fitInitialGeometryIfNeeded();
    });
  }

  @override
  void dispose() {
    _cameraDebounce?.cancel();
    _pulseController.dispose();
    _userLocationVN.dispose();
    _searchHitVN.dispose();
    _zoomVN.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MapChange oldWidget) {
    super.didUpdateWidget(oldWidget);

    final visualSignatureChanged =
        oldWidget.visualDataSignature != widget.visualDataSignature;

    final featuresRefChanged = !identical(oldWidget.features, widget.features);

    final externalPolygonChanged =
        !identical(oldWidget.externalPolygons, widget.externalPolygons) ||
            oldWidget.externalPolygons.length != widget.externalPolygons.length;

    final externalPolylineChanged =
        !identical(oldWidget.externalPolylines, widget.externalPolylines) ||
            oldWidget.externalPolylines.length !=
                widget.externalPolylines.length;

    final externalMarkersChanged =
        !identical(oldWidget.externalMarkers, widget.externalMarkers) ||
            oldWidget.externalMarkers.length != widget.externalMarkers.length;

    final initialGeometryChanged = !listEquals(
      oldWidget.initialGeometryPoints,
      widget.initialGeometryPoints,
    );

    if (featuresRefChanged || visualSignatureChanged) {
      _resetFeatureCaches();
    }

    if (externalPolygonChanged ||
        externalPolylineChanged ||
        externalMarkersChanged ||
        initialGeometryChanged) {
      if (externalPolygonChanged || initialGeometryChanged) {
        _hasFitInitialGeometryOnce = false;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        _fitInitialGeometryIfNeeded();

        if (externalPolygonChanged ||
            externalPolylineChanged ||
            externalMarkersChanged) {
          setState(() {});
        }
      });
    }

    final shouldRefreshStatic = visualSignatureChanged ||
        featuresRefChanged ||
        !mapEquals(oldWidget.layersById, widget.layersById) ||
        !listEquals(
          oldWidget.orderedActiveLayerIds,
          widget.orderedActiveLayerIds,
        ) ||
        oldWidget.selectedFeatureKey != widget.selectedFeatureKey ||
        !mapEquals(
          oldWidget.temporaryLineLayers,
          widget.temporaryLineLayers,
        ) ||
        !mapEquals(
          oldWidget.temporaryPolygonLayers,
          widget.temporaryPolygonLayers,
        ) ||
        !listEquals(
          oldWidget.distanceMeasurementPoints,
          widget.distanceMeasurementPoints,
        );

    final shouldRefreshMarkers = shouldRefreshStatic ||
        !mapEquals(
          oldWidget.temporaryPointLayers,
          widget.temporaryPointLayers,
        );

    if (shouldRefreshStatic || shouldRefreshMarkers) {
      _scheduleCacheRefresh(immediate: true);
    }
  }

  int _interactionFlags() {
    var flags = InteractiveFlag.all;

    if (!widget.enableZoom) {
      flags = flags &
      ~InteractiveFlag.pinchZoom &
      ~InteractiveFlag.doubleTapZoom &
      ~InteractiveFlag.scrollWheelZoom;
    }

    if (!widget.enablePan) {
      flags = flags & ~InteractiveFlag.drag;
    }

    if (!widget.enableRotation) {
      flags = flags & ~InteractiveFlag.rotate;
    }

    return flags;
  }

  int get _safeMapIndex {
    if (MapTypes.mapBase.isEmpty) return 0;

    if (_selectedMapIndex >= 0 &&
        _selectedMapIndex < MapTypes.mapBase.length) {
      return _selectedMapIndex;
    }

    return 0;
  }

  String? get _currentTileUrl {
    if (MapTypes.mapBase.isEmpty) {
      return _fallbackTileUrl;
    }

    final dynamic mapBase = MapTypes.mapBase[_safeMapIndex];

    try {
      final value = mapBase.urlTemplate;
      if (value is String) {
        final trimmed = value.trim();
        return trimmed.isEmpty ? null : trimmed;
      }
    } catch (_) {}

    try {
      final value = mapBase.url;
      if (value is String) {
        final trimmed = value.trim();
        return trimmed.isEmpty ? null : trimmed;
      }
    } catch (_) {}

    try {
      final value = mapBase.tileUrl;
      if (value is String) {
        final trimmed = value.trim();
        return trimmed.isEmpty ? null : trimmed;
      }
    } catch (_) {}

    return _fallbackTileUrl;
  }

  void _onMapTypeChanged(int index) {
    if (!mounted) return;

    setState(() {
      _selectedMapIndex = index;
    });
  }

  void _resetFeatureCaches() {
    _featureBoundsCache.clear();

    _allFeaturesByLayer = const {};
    _featuresByLayer = const {};
    _visibleFeatures = const [];

    _cachedPolygons = const [];
    _cachedPolylines = const [];
    _cachedMarkers = const [];
    _cachedLabelMarkers = const [];
    _cachedHitEntries = const [];

    _lastVisibleFeaturesSourceRef = null;
    _lastFeaturesByLayerVisibleRef = null;
    _lastAllFeaturesSourceRef = null;

    _lastVisibleViewportSignature = -1;

    _lastStaticVisualSignature = 0;
    _lastMarkerVisualSignature = 0;
    _lastHitEntriesSignature = 0;

    _lastStaticZoomBucket = -999.0;
    _lastMarkerZoomBucket = -999.0;
  }

  void _handleMapReady() {
    if (!mounted) return;

    _mapReady = true;

    widget.onControllerReady(_controller);
    _scheduleCacheRefresh(immediate: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _fitInitialGeometryIfNeeded();
    });
  }

  void _fitInitialGeometryIfNeeded() {
    if (!widget.fitInitialGeometryOnce) return;
    if (_hasFitInitialGeometryOnce) return;
    if (!_mapReady) return;
    if (widget.initialGeometryPoints.isEmpty) return;

    try {
      final bounds = LatLngBounds.fromPoints(widget.initialGeometryPoints);

      _controller.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(16),
        ),
      );

      _hasFitInitialGeometryOnce = true;
    } catch (_) {
      _hasFitInitialGeometryOnce = true;
    }
  }

  double get _effectiveZoom {
    if (_mapReady) {
      try {
        return _controller.camera.zoom;
      } catch (_) {
        return _lastKnownZoom;
      }
    }

    return _lastKnownZoom;
  }

  LatLng get _effectiveCenter {
    if (_mapReady) {
      try {
        return _controller.camera.center;
      } catch (_) {
        return _lastKnownCenter;
      }
    }

    return _lastKnownCenter;
  }

  LatLngBoundsLite? get _effectiveViewportBounds {
    if (_mapReady) {
      try {
        final bounds = _controller.camera.visibleBounds;

        return LatLngBoundsLite(
          minLat: bounds.south,
          maxLat: bounds.north,
          minLng: bounds.west,
          maxLng: bounds.east,
        );
      } catch (_) {
        return null;
      }
    }

    return null;
  }

  void _moveZoom(double zoom) {
    if (!_mapReady) return;
    if (!widget.enableZoom) return;

    final minZoom = widget.minZoom ?? 3.0;
    final maxZoom = widget.maxZoom ?? 18.0;

    final safeZoom = zoom.clamp(minZoom, maxZoom).toDouble();
    final center = _effectiveCenter;

    _controller.move(center, safeZoom);

    _lastKnownCenter = center;
    _lastKnownZoom = safeZoom;
    _zoomVN.value = safeZoom;

    widget.onCameraChanged?.call(center, safeZoom);
    _scheduleCacheRefresh(immediate: true);
  }

  void _syncCameraState(LatLng center, double zoom) {
    _lastKnownCenter = center;
    _lastKnownZoom = zoom;
    _zoomVN.value = zoom;

    widget.onCameraChanged?.call(center, zoom);
  }

  void _scheduleCacheRefresh({bool immediate = false}) {
    _cameraDebounce?.cancel();

    if (immediate) {
      _refreshAllCaches(immediateSetState: true);
      return;
    }

    _cameraDebounce = Timer(const Duration(milliseconds: 90), () {
      if (!mounted) return;
      _refreshAllCaches(immediateSetState: true);
    });
  }

  void _refreshAllCaches({required bool immediateSetState}) {
    final staticChanged = _ensureStaticCache();
    final markerChanged = _ensureMarkerCache();

    final changed = staticChanged || markerChanged;

    if (changed) {
      _cacheReady = true;
    }

    if (immediateSetState && changed && mounted) {
      setState(() {});
    }
  }

  bool _ensureStaticCache() {
    final bucket = MapCache.staticZoomBucket(_effectiveZoom);
    final viewportBounds = _expandedViewportBounds();
    final viewportSignature = _viewportSignature(viewportBounds);

    final signature = Object.hash(
      widget.visualDataSignature,
      viewportSignature,
      MapCache.computeStaticVisualSignature(
        zoomBucket: bucket,
        selectedFeatureKey: widget.selectedFeatureKey,
        features: widget.features,
        layersById: widget.layersById,
        orderedActiveLayerIds: widget.orderedActiveLayerIds,
        temporaryLineLayers: widget.temporaryLineLayers,
        temporaryPolygonLayers: widget.temporaryPolygonLayers,
        distanceMeasurementPoints: widget.distanceMeasurementPoints,
      ),
    );

    if (signature == _lastStaticVisualSignature &&
        bucket == _lastStaticZoomBucket) {
      return false;
    }

    _lastStaticVisualSignature = signature;
    _lastStaticZoomBucket = bucket;

    _ensureVisibleFeatures(viewportBounds, viewportSignature);
    _ensureFeaturesByLayer();

    _cachedPolygons = MapLayers.buildPolygons(
      zoom: bucket,
      featuresByLayer: _featuresByLayer,
      orderedActiveLayerIds: widget.orderedActiveLayerIds,
      layersById: widget.layersById,
      selectedFeatureKey: widget.selectedFeatureKey,
      temporaryPolygonLayers: widget.temporaryPolygonLayers,
    );

    _cachedPolylines = MapLayers.buildPolylines(
      zoom: bucket,
      featuresByLayer: _featuresByLayer,
      orderedActiveLayerIds: widget.orderedActiveLayerIds,
      layersById: widget.layersById,
      selectedFeatureKey: widget.selectedFeatureKey,
      temporaryLineLayers: widget.temporaryLineLayers,
      temporaryPolygonLayers: widget.temporaryPolygonLayers,
      distanceMeasurementPoints: widget.distanceMeasurementPoints,
    );

    _ensureHitEntries();

    return true;
  }

  bool _ensureMarkerCache() {
    final bucket = MapCache.markerZoomBucket(_effectiveZoom);
    final viewportBounds = _expandedViewportBounds();
    final viewportSignature = _viewportSignature(viewportBounds);

    final signature = Object.hash(
      widget.visualDataSignature,
      viewportSignature,
      MapCache.computeMarkerVisualSignature(
        zoomBucket: bucket,
        selectedFeatureKey: widget.selectedFeatureKey,
        features: widget.features,
        layersById: widget.layersById,
        orderedActiveLayerIds: widget.orderedActiveLayerIds,
        temporaryPointLayers: widget.temporaryPointLayers,
        temporaryPolygonLayers: widget.temporaryPolygonLayers,
        distanceMeasurementPoints: widget.distanceMeasurementPoints,
      ),
    );

    if (signature == _lastMarkerVisualSignature &&
        bucket == _lastMarkerZoomBucket) {
      return false;
    }

    _lastMarkerVisualSignature = signature;
    _lastMarkerZoomBucket = bucket;

    _ensureVisibleFeatures(viewportBounds, viewportSignature);
    _ensureFeaturesByLayer();

    _cachedMarkers = MapLayers.buildMarkers(
      zoom: bucket,
      featuresByLayer: _featuresByLayer,
      orderedActiveLayerIds: widget.orderedActiveLayerIds,
      layersById: widget.layersById,
      selectedFeatureKey: widget.selectedFeatureKey,
      temporaryPointLayers: widget.temporaryPointLayers,
      temporaryPolygonLayers: widget.temporaryPolygonLayers,
      distanceMeasurementPoints: widget.distanceMeasurementPoints,
    );

    _cachedLabelMarkers = MapLayers.buildLabelMarkers(
      zoom: bucket,
      featuresByLayer: _featuresByLayer,
      orderedActiveLayerIds: widget.orderedActiveLayerIds,
      layersById: widget.layersById,
      selectedFeatureKey: widget.selectedFeatureKey,
    );

    return true;
  }

  void _ensureAllFeaturesByLayer() {
    if (identical(_lastAllFeaturesSourceRef, widget.features)) {
      return;
    }

    _allFeaturesByLayer = MapCache.groupFeaturesByLayer(widget.features);
    _lastAllFeaturesSourceRef = widget.features;
  }

  void _ensureVisibleFeatures(
      LatLngBoundsLite? viewport,
      int viewportSignature,
      ) {
    if (identical(_lastVisibleFeaturesSourceRef, widget.features) &&
        _lastVisibleViewportSignature == viewportSignature) {
      return;
    }

    _ensureAllFeaturesByLayer();

    _visibleFeatures = _collectVisibleFeatures(viewport);
    _lastVisibleFeaturesSourceRef = widget.features;
    _lastVisibleViewportSignature = viewportSignature;
    _lastFeaturesByLayerVisibleRef = null;
  }

  void _ensureFeaturesByLayer() {
    if (identical(_lastFeaturesByLayerVisibleRef, _visibleFeatures)) {
      return;
    }

    _featuresByLayer = MapCache.groupFeaturesByLayer(_visibleFeatures);
    _lastFeaturesByLayerVisibleRef = _visibleFeatures;
  }

  void _ensureHitEntries() {
    final hitSignature = Object.hash(
      widget.visualDataSignature,
      Object.hashAll(widget.orderedActiveLayerIds),
      identityHashCode(_featuresByLayer),
    );

    if (hitSignature == _lastHitEntriesSignature) {
      return;
    }

    _lastHitEntriesSignature = hitSignature;

    _cachedHitEntries = MapHitTest.buildHitEntries(
      orderedActiveLayerIds: widget.orderedActiveLayerIds,
      featuresByLayer: _featuresByLayer,
    );
  }

  FeatureData? _findFeatureAt(LatLng tap, double zoom) {
    return MapHitTest.findFeatureAt(
      tap: tap,
      zoom: zoom,
      entries: _cachedHitEntries,
    );
  }

  Polyline<Object>? _findExternalPolylineAt(LatLng tap, double zoom) {
    if (widget.externalPolylines.isEmpty) return null;

    final toleranceMeters = _externalPolylineToleranceMeters(
      latitude: tap.latitude,
      zoom: zoom,
    );

    for (final polyline in widget.externalPolylines.reversed) {
      final points = polyline.points;
      if (points.length < 2) continue;

      for (var i = 0; i < points.length - 1; i++) {
        final a = points[i];
        final b = points[i + 1];

        if (_distancePointToSegmentMeters(tap, a, b) <= toleranceMeters) {
          return polyline;
        }
      }
    }

    return null;
  }

  double _externalPolylineToleranceMeters({
    required double latitude,
    required double zoom,
  }) {
    final pixels = zoom < 7
        ? 18.0
        : zoom < 10
        ? 16.0
        : zoom < 13
        ? 14.0
        : 12.0;

    final metersPerPixel = _metersPerPixel(
      latitude: latitude,
      zoom: zoom,
    );

    return (metersPerPixel * pixels).clamp(25.0, 12000.0);
  }

  double _metersPerPixel({
    required double latitude,
    required double zoom,
  }) {
    final latRad = latitude * math.pi / 180.0;
    final cosLat = math.cos(latRad).abs().clamp(0.0001, 1.0);

    return (156543.03392804097 * cosLat) / math.pow(2.0, zoom);
  }

  double _distancePointToSegmentMeters(
      LatLng p,
      LatLng a,
      LatLng b,
      ) {
    const distance = Distance();

    final ap = distance.as(LengthUnit.Meter, a, p);
    final bp = distance.as(LengthUnit.Meter, b, p);
    final ab = distance.as(LengthUnit.Meter, a, b);

    if (ab <= 0) return ap;

    final s = (ap + bp + ab) / 2.0;
    final areaSquared = s * (s - ap) * (s - bp) * (s - ab);

    if (areaSquared <= 0) {
      return math.min(ap, bp);
    }

    final area = math.sqrt(areaSquared);
    final h = (2.0 * area) / ab;

    final projectionInside =
        (ap * ap + ab * ab >= bp * bp) &&
            (bp * bp + ab * ab >= ap * ap);

    if (!projectionInside) {
      return math.min(ap, bp);
    }

    return h;
  }

  Offset Function(Offset p)? _toGlobalFn() {
    final box = _mapStackKey.currentContext?.findRenderObject();

    if (box is! RenderBox) return null;

    return (Offset p) => box.localToGlobal(p);
  }

  Polygon<Map<String, dynamic>>? _findExternalPolygonAt(LatLng tap) {
    if (widget.externalPolygons.isEmpty) return null;

    for (final polygon in widget.externalPolygons.reversed) {
      if (!_pointInPolygon(tap, polygon.points)) continue;

      final holes = polygon.holePointsList ?? const <List<LatLng>>[];
      var insideHole = false;

      for (final hole in holes) {
        if (_pointInPolygon(tap, hole)) {
          insideHole = true;
          break;
        }
      }

      if (!insideHole) {
        return polygon;
      }
    }

    return null;
  }

  bool _pointInPolygon(LatLng point, List<LatLng> polygon) {
    if (polygon.length < 3) return false;

    var inside = false;
    var j = polygon.length - 1;

    for (var i = 0; i < polygon.length; i++) {
      final xi = polygon[i].longitude;
      final yi = polygon[i].latitude;
      final xj = polygon[j].longitude;
      final yj = polygon[j].latitude;

      final denominator =
      (yj - yi).abs() < 0.0000001 ? 0.0000001 : yj - yi;

      final intersect =
          ((yi > point.latitude) != (yj > point.latitude)) &&
              (point.longitude <
                  ((xj - xi) * (point.latitude - yi) / denominator) + xi);

      if (intersect) {
        inside = !inside;
      }

      j = i;
    }

    return inside;
  }

  List<FeatureData> _collectVisibleFeatures(LatLngBoundsLite? viewport) {
    final out = <FeatureData>[];

    for (final layerId in widget.orderedActiveLayerIds) {
      final layerFeatures = _allFeaturesByLayer[layerId];
      if (layerFeatures == null || layerFeatures.isEmpty) continue;

      if (viewport == null) {
        out.addAll(layerFeatures);
        continue;
      }

      for (final feature in layerFeatures) {
        final bounds = _featureBoundsFor(feature);
        if (bounds == null) continue;

        if (_boundsIntersect(bounds, viewport)) {
          out.add(feature);
        }
      }
    }

    return out;
  }

  LatLngBoundsLite? _expandedViewportBounds() {
    final raw = _effectiveViewportBounds;
    if (raw == null) return null;

    final latSpan = (raw.maxLat - raw.minLat).abs();
    final lngSpan = (raw.maxLng - raw.minLng).abs();

    final latPad =
    (latSpan * _viewportPaddingFactor).clamp(_minViewportPadDegrees, 90.0);

    final lngPad =
    (lngSpan * _viewportPaddingFactor).clamp(_minViewportPadDegrees, 180.0);

    return LatLngBoundsLite(
      minLat: raw.minLat - latPad,
      maxLat: raw.maxLat + latPad,
      minLng: raw.minLng - lngPad,
      maxLng: raw.maxLng + lngPad,
    );
  }

  int _viewportSignature(LatLngBoundsLite? bounds) {
    if (bounds == null) return 0;

    return Object.hash(
      bounds.minLat.toStringAsFixed(5),
      bounds.maxLat.toStringAsFixed(5),
      bounds.minLng.toStringAsFixed(5),
      bounds.maxLng.toStringAsFixed(5),
    );
  }

  bool _boundsIntersect(LatLngBoundsLite a, LatLngBoundsLite b) {
    if (a.maxLat < b.minLat) return false;
    if (a.minLat > b.maxLat) return false;
    if (a.maxLng < b.minLng) return false;
    if (a.minLng > b.maxLng) return false;

    return true;
  }

  LatLngBoundsLite? _featureBoundsFor(FeatureData feature) {
    final cacheKey = feature.selectionKey;
    final signature = _featureGeometrySignature(feature);

    final cached = _featureBoundsCache[cacheKey];

    if (cached != null && cached.signature == signature) {
      return cached.bounds;
    }

    LatLngBoundsLite? bounds;

    void includePoint(LatLng p) {
      if (bounds == null) {
        bounds = LatLngBoundsLite(
          minLat: p.latitude,
          maxLat: p.latitude,
          minLng: p.longitude,
          maxLng: p.longitude,
        );
      } else {
        bounds = LatLngBoundsLite(
          minLat: math.min(bounds!.minLat, p.latitude),
          maxLat: math.max(bounds!.maxLat, p.latitude),
          minLng: math.min(bounds!.minLng, p.longitude),
          maxLng: math.max(bounds!.maxLng, p.longitude),
        );
      }
    }

    for (final p in feature.markerPoints) {
      includePoint(p);
    }

    for (final part in feature.lineParts) {
      for (final p in part) {
        includePoint(p);
      }
    }

    for (final ring in feature.polygonRings) {
      for (final p in ring) {
        includePoint(p);
      }
    }

    _featureBoundsCache[cacheKey] = _FeatureBoundsCacheEntry(
      signature: signature,
      bounds: bounds,
    );

    return bounds;
  }

  int _featureGeometrySignature(FeatureData feature) {
    LatLng? firstMarker;
    LatLng? lastMarker;

    if (feature.markerPoints.isNotEmpty) {
      firstMarker = feature.markerPoints.first;
      lastMarker = feature.markerPoints.last;
    }

    LatLng? firstLinePoint;
    LatLng? lastLinePoint;

    if (feature.lineParts.isNotEmpty && feature.lineParts.first.isNotEmpty) {
      firstLinePoint = feature.lineParts.first.first;

      final lastPart = feature.lineParts.last;
      if (lastPart.isNotEmpty) {
        lastLinePoint = lastPart.last;
      }
    }

    LatLng? firstPolygonPoint;
    LatLng? lastPolygonPoint;

    if (feature.polygonRings.isNotEmpty &&
        feature.polygonRings.first.isNotEmpty) {
      firstPolygonPoint = feature.polygonRings.first.first;

      final lastRing = feature.polygonRings.last;
      if (lastRing.isNotEmpty) {
        lastPolygonPoint = lastRing.last;
      }
    }

    return Object.hashAll([
      feature.selectionKey,
      feature.geometryType,
      feature.markerPoints.length,
      feature.lineParts.length,
      feature.polygonRings.length,
      firstMarker?.latitude.toStringAsFixed(6),
      firstMarker?.longitude.toStringAsFixed(6),
      lastMarker?.latitude.toStringAsFixed(6),
      lastMarker?.longitude.toStringAsFixed(6),
      firstLinePoint?.latitude.toStringAsFixed(6),
      firstLinePoint?.longitude.toStringAsFixed(6),
      lastLinePoint?.latitude.toStringAsFixed(6),
      lastLinePoint?.longitude.toStringAsFixed(6),
      firstPolygonPoint?.latitude.toStringAsFixed(6),
      firstPolygonPoint?.longitude.toStringAsFixed(6),
      lastPolygonPoint?.latitude.toStringAsFixed(6),
      lastPolygonPoint?.longitude.toStringAsFixed(6),
    ]);
  }

  Future<void> _handleMapTap(LatLng latLng) async {
    final consumed = widget.onBackgroundTap?.call(latLng) ?? false;
    if (consumed) return;

    final externalPolyline = _findExternalPolylineAt(
      latLng,
      _effectiveZoom,
    );

    if (externalPolyline != null) {
      await widget.onExternalPolylineTap?.call(externalPolyline);

      if (!mounted) return;

      final local = _controller.camera.latLngToScreenOffset(latLng);
      final toGlobal = _toGlobalFn();
      final global = toGlobal?.call(local) ?? local;

      await widget.onShowExternalPolylineTooltip?.call(
        context: context,
        position: global,
        tag: externalPolyline.hitValue,
        mapController: _controller,
        tapLatLng: latLng,
        toGlobal: toGlobal,
      );

      return;
    }

    if (widget.externalPolylines.isNotEmpty) {
      await widget.onClearExternalPolylineSelection?.call();

      if (!mounted) return;
    }

    final externalHit = _findExternalPolygonAt(latLng);

    if (externalHit != null) {
      widget.onExternalPolygonTap?.call(externalHit);
      return;
    }

    if (widget.externalPolygons.isNotEmpty &&
        widget.onExternalPolygonTap != null) {
      widget.onExternalPolygonTap?.call(null);
    }

    final hit = _findFeatureAt(latLng, _effectiveZoom);
    widget.onFeatureTap(hit);
  }

  Widget _buildSearchPinLayer() {
    return ValueListenableBuilder<LatLng?>(
      valueListenable: _searchHitVN,
      builder: (context, point, _) {
        if (point == null) {
          return const SizedBox.shrink();
        }

        return MarkerLayer(
          markers: [
            Marker(
              point: point,
              width: 46,
              height: 46,
              alignment: Alignment.bottomCenter,
              child: const PinChanged(
                size: 42,
                color: Color(0xFFD32F2F),
                borderColor: Colors.white,
                showShadow: true,
                innerDot: true,
                label: 'BUS',
                maxLabelChars: 3,
                anchor: PinAnchor.tip,
                halo: true,
                haloOpacity: 0.16,
                haloScale: 1.45,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMapTypeControl() {
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);

    final width = size.width;
    final isCompact = width < 600;

    final left = isCompact ? 12.0 : 16.0;
    final bottom = isCompact ? 16.0 : 16.0;

    final sliderRight = isCompact ? 12.0 : 16.0;

    const sliderWidth = 33.0;
    const gapToSlider = 12.0;

    final maxMapTypeWidth = math.max(
      86.0,
      width -
          padding.left -
          padding.right -
          left -
          sliderRight -
          sliderWidth -
          gapToSlider,
    );

    return Positioned.fill(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (_mapTypeExpanded)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  if (!mounted) return;

                  setState(() {
                    _mapTypeExpanded = false;
                  });
                },
                child: const SizedBox.expand(),
              ),
            ),
          Positioned(
            left: left,
            bottom: bottom,
            child: SafeArea(
              top: false,
              left: true,
              right: false,
              bottom: true,
              minimum: EdgeInsets.only(
                bottom: isCompact ? 8 : 0,
              ),
              child: RepaintBoundary(
                child: MapTypeButton(
                  mapController: _controller,
                  selectedMapIndex: _safeMapIndex,
                  expanded: _mapTypeExpanded,
                  maxExpandedWidth: maxMapTypeWidth,
                  onExpandedChanged: (value) {
                    if (!mounted) return;

                    setState(() {
                      _mapTypeExpanded = value;
                    });
                  },
                  onChanged: (index) {
                    _onMapTypeChanged(index);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapControls() {
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);

    final width = size.width;
    final isCompact = width < 600;

    final right = isCompact ? 12.0 : 16.0;
    final bottom = isCompact ? 16.0 : 16.0;

    const sliderWidth = 33.0;

    final hasSideWidget = widget.zoomSliderLeading != null;

    final gap = hasSideWidget && widget.showZoomSlider
        ? widget.zoomSliderLeadingSpacing
        : 0.0;

    final maxSideWidgetWidth = math.max(
      0.0,
      width -
          padding.left -
          padding.right -
          right -
          12.0 -
          (widget.showZoomSlider ? sliderWidth : 0.0) -
          gap,
    );

    final sideWidgetWidth = math.min(
      widget.zoomSliderLeadingMaxWidth,
      maxSideWidgetWidth,
    );

    return Positioned(
      right: right,
      bottom: bottom,
      child: SafeArea(
        top: false,
        left: false,
        right: true,
        bottom: true,
        minimum: EdgeInsets.only(
          bottom: isCompact ? 8 : 0,
        ),
        child: RepaintBoundary(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (widget.showZoomSlider)
                SliderButton(
                  zoomListenable: _zoomVN,
                  minZoom: widget.minZoom ?? 3.0,
                  maxZoom: widget.maxZoom ?? 18.0,
                  onZoomChanged: _moveZoom,
                ),
              if (widget.showZoomSlider && widget.zoomSliderLeading != null)
                SizedBox(width: widget.zoomSliderLeadingSpacing),
              if (widget.zoomSliderLeading != null)
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: sideWidgetWidth,
                  ),
                  child: widget.zoomSliderLeading!,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchControl() {
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 600;

    return Positioned(
      left: isCompact ? 12 : 16,
      top: isCompact ? 12 : 16,
      child: SafeArea(
        minimum: EdgeInsets.zero,
        child: RepaintBoundary(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MyLocation(
                mapController: _controller,
                userLocationVN: _userLocationVN,
                searchHitVN: _searchHitVN,
                onMapTap: (lat, lon) {},
                onMoved: (center, zoom) {
                  _syncCameraState(center, zoom);
                  _scheduleCacheRefresh(immediate: true);
                },
              ),
              const SizedBox(width: 8),
              SearchMapButton(
                mapController: _controller,
                searchHitVN: _searchHitVN,
                searchTargetZoom: 16,
                onMapTap: (lat, lon) {},
                onMoved: (center, zoom) {
                  _syncCameraState(center, zoom);
                  _scheduleCacheRefresh(immediate: true);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    if (!widget.loading) return const SizedBox.shrink();

    return Positioned.fill(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
          ),
          child: const Center(
            child: SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentTileUrl = _currentTileUrl;

    return Stack(
      key: _mapStackKey,
      clipBehavior: Clip.hardEdge,
      children: [
        RepaintBoundary(
          child: MouseRegion(
            cursor: widget.cursor,
            child: FlutterMap(
              mapController: _controller,
              options: MapOptions(
                initialCenter: _lastKnownCenter,
                initialZoom: _lastKnownZoom,
                minZoom: widget.minZoom,
                maxZoom: widget.maxZoom,
                interactionOptions: InteractionOptions(
                  flags: _interactionFlags(),
                ),
                onMapReady: _handleMapReady,
                onTap: (_, latLng) {
                  unawaited(_handleMapTap(latLng));
                },
                onPositionChanged: (camera, hasGesture) {
                  _syncCameraState(camera.center, camera.zoom);

                  if (hasGesture) {
                    _scheduleCacheRefresh(immediate: false);
                  } else {
                    _scheduleCacheRefresh(immediate: true);
                  }
                },
              ),
              children: [
                if (currentTileUrl != null)
                  TileLayer(
                    key: ValueKey('tile_layer_$_safeMapIndex'),
                    urlTemplate: currentTileUrl,
                    userAgentPackageName: 'com.openai.sisgeo',
                    panBuffer: 1,
                  ),
                if (widget.externalPolygons.isNotEmpty)
                  PolygonLayer<Map<String, dynamic>>(
                    polygons: widget.externalPolygons,
                  ),
                if (_cacheReady && _cachedPolygons.isNotEmpty)
                  PolygonLayer(
                    polygons: _cachedPolygons,
                  ),
                if (widget.externalPolylines.isNotEmpty)
                  PolylineLayer(
                    polylines: widget.externalPolylines,
                  ),
                if (_cacheReady && _cachedPolylines.isNotEmpty)
                  PolylineLayer(
                    polylines: _cachedPolylines,
                  ),
                if (_cacheReady && _cachedMarkers.isNotEmpty)
                  MarkerLayer(
                    markers: _cachedMarkers,
                  ),
                if (_cacheReady && _cachedLabelMarkers.isNotEmpty)
                  MarkerLayer(
                    markers: _cachedLabelMarkers,
                  ),
                if (widget.externalMarkers.isNotEmpty)
                  MarkerLayer(
                    markers: widget.externalMarkers,
                  ),
                _buildSearchPinLayer(),
                PinUserLocation(
                  userLocationVN: _userLocationVN,
                  pulseAnimation: _pulseAnimation,
                ),
              ],
            ),
          ),
        ),
        if (widget.showSearch) _buildSearchControl(),
        if (widget.showControls && widget.showMapTypeButton)
          _buildMapTypeControl(),
        if (widget.showControls &&
            (widget.showZoomSlider || widget.zoomSliderLeading != null))
          _buildMapControls(),
        _buildLoadingOverlay(),
      ],
    );
  }
}

class _FeatureBoundsCacheEntry {
  final int signature;
  final LatLngBoundsLite? bounds;

  const _FeatureBoundsCacheEntry({
    required this.signature,
    required this.bounds,
  });
}