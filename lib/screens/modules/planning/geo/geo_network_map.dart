import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:sipged/_blocs/modules/planning/geo/feature/geo_feature_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data.dart';
import 'package:sipged/screens/modules/planning/geo/geo_network_map_cache.dart';
import 'package:sipged/screens/modules/planning/geo/geo_network_map_hit_test.dart';
import 'package:sipged/screens/modules/planning/geo/geo_network_map_layers.dart';

class GeoNetworkMap extends StatefulWidget {
  const GeoNetworkMap({
    super.key,
    required this.features,
    required this.layersById,
    required this.orderedActiveLayerIds,
    required this.onFeatureTap,
    required this.onControllerReady,
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

  final List<GeoFeatureData> features;
  final Map<String, GeoLayersData> layersById;
  final List<String> orderedActiveLayerIds;
  final void Function(GeoFeatureData? feature) onFeatureTap;
  final void Function(MapController controller) onControllerReady;
  final void Function(LatLng center, double zoom)? onCameraChanged;
  final String? selectedFeatureKey;
  final bool loading;

  final bool Function(LatLng latLng)? onBackgroundTap;
  final Map<String, List<LatLng>> temporaryPointLayers;
  final Map<String, List<LatLng>> temporaryLineLayers;
  final Map<String, List<LatLng>> temporaryPolygonLayers;
  final List<LatLng> distanceMeasurementPoints;
  final MouseCursor cursor;

  @override
  State<GeoNetworkMap> createState() => _GeoNetworkMapState();
}

class _GeoNetworkMapState extends State<GeoNetworkMap> {
  late final MapController _controller;

  static const String _tileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  bool _mapReady = false;
  double _lastKnownZoom = 7.0;
  LatLng _lastKnownCenter = const LatLng(-9.6658, -35.7353);

  int _lastStaticVisualSignature = 0;
  int _lastMarkerVisualSignature = 0;
  double _lastMarkerZoomBucket = -999.0;
  double _lastStaticZoomBucket = -999.0;

  Map<String, List<GeoFeatureData>> _featuresByLayer = const {};
  List<Polygon> _cachedPolygons = const [];
  List<Polyline> _cachedPolylines = const [];
  List<Marker> _cachedMarkers = const [];
  List<Marker> _cachedLabelMarkers = const [];
  List<FeatureHitEntry> _cachedHitEntries = const [];

  @override
  void initState() {
    super.initState();
    _controller = MapController();
  }

  @override
  void didUpdateWidget(covariant GeoNetworkMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    final nextBucket = GeoNetworkMapCache.zoomBucket(_effectiveZoom);

    if ((nextBucket != _lastMarkerZoomBucket ||
        nextBucket != _lastStaticZoomBucket) &&
        mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _ensureStaticCache();
          _ensureMarkerCache();
        });
      });
    }
  }

  void _handleMapReady() {
    if (!mounted) return;

    _mapReady = true;
    widget.onControllerReady(_controller);
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

  void _ensureStaticCache() {
    final bucket = GeoNetworkMapCache.zoomBucket(_effectiveZoom);

    final signature = GeoNetworkMapCache.computeStaticVisualSignature(
      zoomBucket: bucket,
      selectedFeatureKey: widget.selectedFeatureKey,
      features: widget.features,
      layersById: widget.layersById,
      orderedActiveLayerIds: widget.orderedActiveLayerIds,
      temporaryLineLayers: widget.temporaryLineLayers,
      temporaryPolygonLayers: widget.temporaryPolygonLayers,
      distanceMeasurementPoints: widget.distanceMeasurementPoints,
    );

    if (signature == _lastStaticVisualSignature &&
        bucket == _lastStaticZoomBucket) {
      return;
    }

    _lastStaticZoomBucket = bucket;
    _lastStaticVisualSignature = signature;
    _featuresByLayer = GeoNetworkMapCache.groupFeaturesByLayer(widget.features);

    _cachedPolygons = GeoNetworkMapLayers.buildPolygons(
      zoom: bucket,
      featuresByLayer: _featuresByLayer,
      orderedActiveLayerIds: widget.orderedActiveLayerIds,
      layersById: widget.layersById,
      selectedFeatureKey: widget.selectedFeatureKey,
      temporaryPolygonLayers: widget.temporaryPolygonLayers,
    );

    _cachedPolylines = GeoNetworkMapLayers.buildPolylines(
      zoom: bucket,
      featuresByLayer: _featuresByLayer,
      orderedActiveLayerIds: widget.orderedActiveLayerIds,
      layersById: widget.layersById,
      selectedFeatureKey: widget.selectedFeatureKey,
      temporaryLineLayers: widget.temporaryLineLayers,
      temporaryPolygonLayers: widget.temporaryPolygonLayers,
      distanceMeasurementPoints: widget.distanceMeasurementPoints,
    );

    _cachedHitEntries = GeoNetworkMapHitTest.buildHitEntries(
      orderedActiveLayerIds: widget.orderedActiveLayerIds,
      featuresByLayer: _featuresByLayer,
    );
  }

  void _ensureMarkerCache() {
    final bucket = GeoNetworkMapCache.zoomBucket(_effectiveZoom);

    final signature = GeoNetworkMapCache.computeMarkerVisualSignature(
      zoomBucket: bucket,
      selectedFeatureKey: widget.selectedFeatureKey,
      features: widget.features,
      layersById: widget.layersById,
      orderedActiveLayerIds: widget.orderedActiveLayerIds,
      temporaryPointLayers: widget.temporaryPointLayers,
      temporaryPolygonLayers: widget.temporaryPolygonLayers,
      distanceMeasurementPoints: widget.distanceMeasurementPoints,
    );

    if (signature == _lastMarkerVisualSignature &&
        bucket == _lastMarkerZoomBucket) {
      return;
    }

    _lastMarkerZoomBucket = bucket;
    _lastMarkerVisualSignature = signature;

    _cachedMarkers = GeoNetworkMapLayers.buildMarkers(
      zoom: bucket,
      featuresByLayer: _featuresByLayer,
      orderedActiveLayerIds: widget.orderedActiveLayerIds,
      layersById: widget.layersById,
      selectedFeatureKey: widget.selectedFeatureKey,
      temporaryPointLayers: widget.temporaryPointLayers,
      temporaryPolygonLayers: widget.temporaryPolygonLayers,
      distanceMeasurementPoints: widget.distanceMeasurementPoints,
      onFeatureTap: widget.onFeatureTap,
    );

    _cachedLabelMarkers = GeoNetworkMapLayers.buildLabelMarkers(
      zoom: bucket,
      featuresByLayer: _featuresByLayer,
      orderedActiveLayerIds: widget.orderedActiveLayerIds,
      layersById: widget.layersById,
      selectedFeatureKey: widget.selectedFeatureKey,
    );
  }

  GeoFeatureData? _findFeatureAt(LatLng tap, double zoom) {
    return GeoNetworkMapHitTest.findFeatureAt(
      tap: tap,
      zoom: zoom,
      entries: _cachedHitEntries,
    );
  }

  @override
  Widget build(BuildContext context) {
    _ensureStaticCache();
    _ensureMarkerCache();

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

                  if (hit != null) {
                    widget.onFeatureTap(hit);
                    return;
                  }

                  widget.onFeatureTap(null);
                },
                onPositionChanged: (camera, hasGesture) {
                  _lastKnownCenter = camera.center;
                  _lastKnownZoom = camera.zoom;
                  widget.onCameraChanged?.call(camera.center, camera.zoom);

                  final nextBucket = GeoNetworkMapCache.zoomBucket(camera.zoom);
                  if ((nextBucket != _lastMarkerZoomBucket ||
                      nextBucket != _lastStaticZoomBucket) &&
                      mounted) {
                    setState(() {
                      _ensureStaticCache();
                      _ensureMarkerCache();
                    });
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: _tileUrl,
                  userAgentPackageName: 'com.openai.sipged',
                  panBuffer: 1,
                ),
                if (_cachedPolygons.isNotEmpty)
                  PolygonLayer(polygons: _cachedPolygons),
                if (_cachedPolylines.isNotEmpty)
                  PolylineLayer(polylines: _cachedPolylines),
                if (_cachedMarkers.isNotEmpty)
                  MarkerLayer(markers: _cachedMarkers),
                if (_cachedLabelMarkers.isNotEmpty)
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
                        : () {
                      final center = _effectiveCenter;
                      final zoom = _effectiveZoom;
                      _controller.move(center, zoom + 1);
                    },
                    child: const Icon(Icons.add),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: 'geo_zoom_out',
                    onPressed: !_mapReady
                        ? null
                        : () {
                      final center = _effectiveCenter;
                      final zoom = _effectiveZoom;
                      _controller.move(center, zoom - 1);
                    },
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