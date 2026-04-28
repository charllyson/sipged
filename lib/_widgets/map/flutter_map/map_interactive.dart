import 'dart:async';

import 'package:diacritic/diacritic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sipged/_widgets/map/polylines/polyline_changed.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:sipged/_widgets/map/base/map_layer.dart';
import 'package:sipged/_widgets/map/base/map_types.dart';
import 'package:sipged/_widgets/map/buttons/map_type.dart';
import 'package:sipged/_widgets/map/buttons/my_location.dart';
import 'package:sipged/_widgets/map/buttons/search_map.dart';
import 'package:sipged/_widgets/map/flutter_map/map_interactive_helpers.dart';
import 'package:sipged/_widgets/map/legend/legend_change.dart';
import 'package:sipged/_widgets/map/pin/pin_user_location.dart';
import 'package:sipged/_widgets/map/markers/marker_data.dart';
import 'package:sipged/_widgets/map/markers/marker_layer.dart';
import 'package:sipged/_widgets/map/pin/pin_search.dart';
import 'package:sipged/_widgets/map/polygon/polygon_changed.dart';
import 'package:sipged/_widgets/map/polygon/polygon_data.dart';
import 'package:sipged/_widgets/map/polylines/polyline_data.dart';

class MapInteractivePage<T> extends StatefulWidget {
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

  final List<PolylineData>? tappablePolylines;
  final Future<void> Function()? onClearPolylineSelection;
  final Future<void> Function(PolylineData)? onSelectPolyline;

  final void Function({
  required BuildContext context,
  required Offset position,
  required Object? tag,
  required MapController mapController,
  LatLng? tapLatLng,
  Offset Function(Offset local)? toGlobal,
  })? onShowPolylineTooltip;

  final List<MarkerData<T>>? taggedMarkers;

  final Widget Function(
      List<MarkerData<T>> taggedMarkers,
      LatLng? selectedMarkerPosition,
      ValueChanged<MarkerData<T>> onMarkerSelected,
      )? clusterWidgetBuilder;

  final List<Marker>? extraMarkers;

  final List<PolygonData>? polygonsChanged;
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

  final void Function(void Function(LatLng point) setActivePoint)?
  onBindSetActivePoint;

  final List<LatLng>? initialGeometryPoints;
  final int? selectedBaseIndex;

  @override
  State<MapInteractivePage<T>> createState() => _MapInteractivePageState<T>();
}

class _MapInteractivePageState<T> extends State<MapInteractivePage<T>>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final GlobalKey _captureKey = GlobalKey();

  late final NetworkTileProvider _tileProvider = NetworkTileProvider();

  final ValueNotifier<LatLng?> _userLocationVN = ValueNotifier<LatLng?>(null);
  final ValueNotifier<LatLng?> _searchHitVN = ValueNotifier<LatLng?>(null);

  final ValueNotifier<Set<String>> _selectedRegionsVN =
  ValueNotifier<Set<String>>({});

  final ValueNotifier<LatLng?> _selectedMarkerPositionVN =
  ValueNotifier<LatLng?>(null);

  int _indexSelectedMap = 0;

  Timer? _cameraDebounce;

  static const Duration _kCameraDebounce = Duration(milliseconds: 220);
  static const Duration _kPulseDuration = Duration(seconds: 2);

  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: _kPulseDuration,
  )..repeat(reverse: true);

  late final Animation<double> _pulseAnimation =
  CurvedAnimation(
    parent: _pulseController,
    curve: Curves.easeOut,
  ).drive(
    Tween<double>(
      begin: 0.6,
      end: 1.3,
    ),
  );

  late double _initZoom;
  late LatLng _initCenter;

  LatLng _lastCenter = const LatLng(-9.65, -36.7);
  double _lastZoom = 9.0;

  late final MapInteractiveHelpers _helpers = MapInteractiveHelpers(
    norm: _norm,
  );

  String _norm(String value) {
    return removeDiacritics(value)
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .toUpperCase();
  }

  bool get _isOsmPublic {
    if (MapTypes.mapBase.isEmpty) return false;

    return MapTypes.mapBase[_indexSelectedMap].url.contains(
      'tile.openstreetmap.org',
    );
  }

  List<PolygonData> get _regionalPolys {
    return widget.polygonsChanged ?? const <PolygonData>[];
  }

  @override
  void initState() {
    super.initState();

    _initZoom = widget.initialZoom ?? 9.0;

    if (widget.selectedBaseIndex != null &&
        widget.selectedBaseIndex! >= 0 &&
        widget.selectedBaseIndex! < MapTypes.mapBase.length) {
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

    _helpers.rebuildPolygonBBoxes(
      regionalPolys: _regionalPolys,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (widget.selectedRegionNames != null) {
      _selectedRegionsVN.value = _helpers.toNormSet(
        widget.selectedRegionNames,
      );
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

      if (idx >= 0 && idx < MapTypes.mapBase.length) {
        setState(() {
          _indexSelectedMap = idx;
        });
      }
    }

    _helpers.rebuildPolygonBBoxesIfNeeded(
      oldPolys: oldWidget.polygonsChanged ?? const <PolygonData>[],
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
        final zoom = _lastZoom == 0 ? widget.initialZoom ?? 9.0 : _lastZoom;

        _mapController.move(center, zoom);

        _lastCenter = center;
        _lastZoom = zoom;
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

  void _setLastCamera(LatLng center, double zoom) {
    _lastCenter = center;
    _lastZoom = zoom;

    widget.onZoomChanged?.call(zoom);
    widget.onCameraChanged?.call(zoom, center);
  }

  Future<void> _handlePolylineTap(
      List<PolylineData> tapped,
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

    final tapLatLng = _mapController.camera.screenOffsetToLatLng(
      details.localPosition,
    );

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

  String? _getProp(PolygonData reg, String keyWanted) {
    return _helpers.getProp(reg, keyWanted);
  }

  Future<void> _onTapMap(TapPosition _, LatLng point) async {
    if (widget.dropPinOnTap) {
      _searchHitVN.value = point;
    }

    widget.onMapTap?.call(
      point.latitude,
      point.longitude,
    );

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
          MapLayer(
            tileProvider: _tileProvider,
            urlTemplate: MapTypes.mapBase[_indexSelectedMap].url,
          ),
        );
      }
    }

    if (_regionalPolys.isNotEmpty) {
      children.add(
        PolygonChanged(
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
        PolylineChanged(
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
      MarkerChanged<T>(
        taggedMarkers: widget.taggedMarkers,
        clusterWidgetBuilder: widget.clusterWidgetBuilder,
        selectedMarkerPositionVN: _selectedMarkerPositionVN,
        onMarkerSelected: (marker) {
          _selectedMarkerPositionVN.value = marker.point;
        },
        extraMarkers: widget.extraMarkers,
      ),
    );

    children.add(
      PinUserLocation(
        userLocationVN: _userLocationVN,
        pulseAnimation: _pulseAnimation,
      ),
    );

    if (widget.showSearchMarker) {
      children.add(
        PinSearch(
          searchHitVN: _searchHitVN,
        ),
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

  List<Widget> _buildFloatingMapButtons() {
    final buttons = <Widget>[];

    if (widget.showSearch) {
      buttons.add(
        SearchMap(
          mapController: _mapController,
          searchHitVN: _searchHitVN,
          searchActionBuilder: widget.searchActionBuilder,
          searchTargetZoom: widget.searchTargetZoom,
          onMapTap: widget.onMapTap,
          onMoved: _setLastCamera,
        ),
      );
    }

    if (widget.showMyLocation) {
      if (buttons.isNotEmpty) {
        buttons.add(const SizedBox(width: 8));
      }

      buttons.add(
        MyLocation(
          mapController: _mapController,
          userLocationVN: _userLocationVN,
          searchHitVN: _searchHitVN,
          onMapTap: widget.onMapTap,
          onMoved: _setLastCamera,
        ),
      );
    }

    if (widget.showChangeMapType) {
      if (buttons.isNotEmpty) {
        buttons.add(const SizedBox(width: 8));
      }

      buttons.add(
        MapType(
          mapController: _mapController,
          selectedMapIndex: _indexSelectedMap,
          onChanged: (index) {
            if (!mounted) return;

            setState(() {
              _indexSelectedMap = index;
            });
          },
        ),
      );
    }

    return buttons;
  }

  @override
  Widget build(BuildContext context) {
    final hasLegend =
        widget.showLegend && (widget.polygonChangeColors?.isNotEmpty ?? false);

    final floatingButtons = _buildFloatingMapButtons();

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

                widget.onBindSetActivePoint?.call((LatLng point) {
                  _searchHitVN.value = point;
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
            child: LegendChange(
              regionColors: widget.polygonChangeColors!,
            ),
          ),
        if (floatingButtons.isNotEmpty)
          Positioned(
            top: 10,
            left: 10,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: floatingButtons,
            ),
          ),
      ],
    );
  }
}