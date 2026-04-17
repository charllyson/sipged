import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:sipged/_blocs/modules/planning/geo/feature/feature_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data.dart';
import 'package:sipged/screens/modules/planning/geo/map/map_cache.dart';
import 'package:sipged/screens/modules/planning/geo/map/map_hit_test.dart';
import 'package:sipged/screens/modules/planning/geo/map/map_layers.dart';

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

  final bool Function(LatLng latLng)? onBackgroundTap;
  final Map<String, List<LatLng>> temporaryPointLayers;
  final Map<String, List<LatLng>> temporaryLineLayers;
  final Map<String, List<LatLng>> temporaryPolygonLayers;
  final List<LatLng> distanceMeasurementPoints;
  final MouseCursor cursor;

  @override
  State<MapChange> createState() => _MapChangeState();
}

class _MapChangeState extends State<MapChange> {
  late final MapController _controller;

  static const String _tileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  static const double _viewportPaddingFactor = 0.20;
  static const double _minViewportPadDegrees = 0.0025;

  bool _mapReady = false;
  bool _cacheReady = false;

  double _lastKnownZoom = 7.0;
  LatLng _lastKnownCenter = const LatLng(-9.6658, -35.7353);

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
    _controller = MapController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refreshAllCaches(immediateSetState: true);
    });
  }

  @override
  void dispose() {
    _cameraDebounce?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MapChange oldWidget) {
    super.didUpdateWidget(oldWidget);

    final visualSignatureChanged =
        oldWidget.visualDataSignature != widget.visualDataSignature;

    final featuresRefChanged = !identical(oldWidget.features, widget.features);

    if (featuresRefChanged || visualSignatureChanged) {
      _resetFeatureCaches();
    }

    final shouldRefreshStatic =
        visualSignatureChanged ||
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

    final shouldRefreshMarkers =
        shouldRefreshStatic ||
            !mapEquals(
              oldWidget.temporaryPointLayers,
              widget.temporaryPointLayers,
            );

    if (shouldRefreshStatic || shouldRefreshMarkers) {
      _scheduleCacheRefresh(immediate: true);
    }
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
          minLat: _mathMin(bounds!.minLat, p.latitude),
          maxLat: _mathMax(bounds!.maxLat, p.latitude),
          minLng: _mathMin(bounds!.minLng, p.longitude),
          maxLng: _mathMax(bounds!.maxLng, p.longitude),
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

  double _mathMin(double a, double b) => a < b ? a : b;
  double _mathMax(double a, double b) => a > b ? a : b;

  @override
  Widget build(BuildContext context) {
    return Stack(
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
                onMapReady: _handleMapReady,
                onTap: (_, latLng) {
                  final consumed = widget.onBackgroundTap?.call(latLng) ?? false;
                  if (consumed) return;

                  final hit = _findFeatureAt(latLng, _effectiveZoom);
                  widget.onFeatureTap(hit);
                },
                onPositionChanged: (camera, hasGesture) {
                  _lastKnownCenter = camera.center;
                  _lastKnownZoom = camera.zoom;
                  widget.onCameraChanged?.call(camera.center, camera.zoom);

                  if (hasGesture) {
                    _scheduleCacheRefresh(immediate: false);
                  } else {
                    _scheduleCacheRefresh(immediate: true);
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: _tileUrl,
                  userAgentPackageName: 'com.openai.sipged',
                  panBuffer: 1,
                ),
                if (_cacheReady && _cachedPolygons.isNotEmpty)
                  PolygonLayer(polygons: _cachedPolygons),
                if (_cacheReady && _cachedPolylines.isNotEmpty)
                  PolylineLayer(polylines: _cachedPolylines),
                if (_cacheReady && _cachedMarkers.isNotEmpty)
                  MarkerLayer(markers: _cachedMarkers),
                if (_cacheReady && _cachedLabelMarkers.isNotEmpty)
                  MarkerLayer(markers: _cachedLabelMarkers),
              ],
            ),
          ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: SafeArea(
            minimum: EdgeInsets.zero,
            child: RepaintBoundary(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton.small(
                    heroTag: 'geo_zoom_in',
                    onPressed: !_mapReady
                        ? null
                        : () => _controller.move(
                      _effectiveCenter,
                      _effectiveZoom + 1,
                    ),
                    child: const Icon(Icons.add),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: 'geo_zoom_out',
                    onPressed: !_mapReady
                        ? null
                        : () => _controller.move(
                      _effectiveCenter,
                      _effectiveZoom - 1,
                    ),
                    child: const Icon(Icons.remove),
                  ),
                ],
              ),
            ),
          ),
        ),
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