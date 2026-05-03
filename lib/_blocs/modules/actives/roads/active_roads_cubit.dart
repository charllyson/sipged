import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:sipged/_blocs/modules/actives/roads/active_roads_data.dart';
import 'package:sipged/_blocs/modules/actives/roads/active_roads_repository.dart';
import 'package:sipged/_blocs/modules/actives/roads/active_roads_state.dart';

import 'package:sipged/_blocs/system/tenant/tenant_data.dart';

import 'package:sipged/_utils/geometry/sipged_tile_math.dart';

class ActiveRoadsCubit extends Cubit<ActiveRoadsState> {
  final ActiveRoadsRepository _repo;

  ActiveRoadsCubit({ActiveRoadsRepository? repository})
      : _repo = repository ?? ActiveRoadsRepository(),
        super(const ActiveRoadsState());

  static const double clusterUntilZoom = 12.0;

  bool shouldUseCluster(double zoom) => zoom < clusterUntilZoom;

  List<_RoadRowSegments>? _rawCache;
  final Map<int, List<ActiveRoadMapGeom>> _geomCacheByBucket = {};

  int _requestSeq = 0;

  Timer? _debounce;
  static const Duration _debounceDuration = Duration(milliseconds: 180);

  Timer? _cameraDebounce;
  static const Duration _cameraDebounceDuration = Duration(milliseconds: 220);

  int? _activeBucket;

  LatLngBounds? _lastBounds;
  double? _lastZoom;

  Future<void> warmup({int bucket = 4}) async {
    if (_lastBounds != null) {
      await loadViewport(bucket: bucket, bounds: _lastBounds!);
      return;
    }

    await _loadAllFallback(setInitialized: true, bucket: bucket);
  }

  Future<void> refresh({int bucket = 4}) async {
    if (_lastBounds != null) {
      await loadViewport(
        bucket: bucket,
        bounds: _lastBounds!,
        forceRefresh: true,
      );
      return;
    }

    await _loadAllFallback(
      setInitialized: false,
      bucket: bucket,
      forceRefresh: true,
    );
  }

  void onCameraChanged({
    required double zoom,
    required LatLngBounds bounds,
  }) {
    _lastBounds = bounds;
    _lastZoom = zoom;

    _cameraDebounce?.cancel();
    _cameraDebounce = Timer(_cameraDebounceDuration, () async {
      final boundsSnapshot = _lastBounds;
      final zoomSnapshot = _lastZoom;

      if (boundsSnapshot == null || zoomSnapshot == null) return;

      final bucket = bucketForZoom(zoomSnapshot);

      await loadViewport(
        bucket: bucket,
        bounds: boundsSnapshot,
      );
    });

    onZoomChanged(zoom: zoom);
  }

  void onZoomChanged({required double zoom}) {
    final bucket = bucketForZoom(zoom);

    if (_activeBucket == bucket) return;

    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, () {
      if (_rawCache == null) return;

      _applyBucketFromCache(bucket);
    });
  }

  void setColorMode(ActiveRoadColorMode mode) {
    if (state.colorMode == mode) return;

    emit(
      state.copyWith(
        colorMode: mode,
      ),
    );
  }

  void clearCache() {
    _rawCache = null;
    _geomCacheByBucket.clear();
    _activeBucket = null;
  }

  void clearAllFilters() {
    emit(
      state.copyWith(
        selectedRegionFilter: null,
        selectedSurfaceFilter: null,
        selectedPieIndexFilter: null,
        selectedVsaFilter: null,
        selectedPolylineId: null,
      ),
    );
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    _cameraDebounce?.cancel();

    return super.close();
  }

  Future<void> loadViewport({
    required int bucket,
    required LatLngBounds bounds,
    bool forceRefresh = false,
  }) async {
    final reqId = ++_requestSeq;

    final hasData = state.all.isNotEmpty && state.mapGeoms.isNotEmpty;

    emit(
      state.copyWith(
        loadStatus: hasData ? state.loadStatus : ActiveRoadsLoadStatus.loading,
        error: null,
      ),
    );

    try {
      final tileZoom = _tileZoomForBucket(bucket);

      final quadKeys = SipGedTileMath.quadKeysForBounds(
        bounds: bounds,
        z: tileZoom,
        maxTiles: 80,
      );

      final list = await _repo.fetchByTiles(
        bucket: bucket,
        quadKeys: quadKeys,
      );

      if (reqId != _requestSeq) return;

      final sorted = _sortRoads(list);
      final regionLabels = _buildRegionLabelsFromData(sorted);

      if (forceRefresh) {
        clearCache();
      } else {
        _geomCacheByBucket.clear();
      }

      _rawCache = _buildRawSegmentsFromRoads(sorted);
      _applyBucketFromCache(bucket);

      if (reqId != _requestSeq) return;

      emit(
        state.copyWith(
          initialized: true,
          all: sorted,
          regionLabels: regionLabels,
          loadStatus: ActiveRoadsLoadStatus.success,
          error: null,
        ),
      );
    } catch (e, s) {
      _perf('ActiveRoads.loadViewport error: $e');
      _perf('$s');

      emit(
        state.copyWith(
          loadStatus: ActiveRoadsLoadStatus.failure,
          error: e.toString(),
        ),
      );
    }
  }

  int _tileZoomForBucket(int bucket) {
    switch (bucket) {
      case 1:
        return 7;
      case 2:
        return 8;
      case 3:
        return 9;
      case 4:
        return 10;
      case 5:
      default:
        return 11;
    }
  }

  Future<void> _loadAllFallback({
    required bool setInitialized,
    required int bucket,
    bool forceRefresh = false,
  }) async {
    final reqId = ++_requestSeq;

    emit(
      state.copyWith(
        loadStatus: ActiveRoadsLoadStatus.loading,
        error: null,
      ),
    );

    try {
      final sw = Stopwatch()..start();

      _perf('[PERF] ActiveRoads.loadAllFallback(bucket=$bucket) :: start=0ms');

      final list = _sortRoads(await _repo.fetchAll());

      if (reqId != _requestSeq) return;

      final regionLabels = _buildRegionLabelsFromData(list);

      if (forceRefresh || _rawCache == null) {
        final tParse = Stopwatch()..start();

        _rawCache = _buildRawSegmentsFromRoads(list);

        tParse.stop();

        final rawPointsTotal = _rawCache!.fold<int>(
          0,
              (acc, row) => acc + row.rawPointsTotal,
        );

        _perf(
          '[PERF] ActiveRoads.loadAllFallback(bucket=$bucket) :: parse rows=${_rawCache!.length} rawPointsTotal=$rawPointsTotal = ${tParse.elapsedMilliseconds}ms',
        );
      }

      _applyBucketFromCache(bucket);

      if (reqId != _requestSeq) return;

      emit(
        state.copyWith(
          initialized: setInitialized ? true : state.initialized,
          all: list,
          regionLabels: regionLabels,
          loadStatus: ActiveRoadsLoadStatus.success,
          error: null,
        ),
      );

      sw.stop();

      _perf(
        '[PERF] ActiveRoads.loadAllFallback(bucket=$bucket) :: END=${sw.elapsedMilliseconds}ms',
      );
    } catch (e, s) {
      _perf('ActiveRoads.loadAllFallback error: $e');
      _perf('$s');

      emit(
        state.copyWith(
          loadStatus: ActiveRoadsLoadStatus.failure,
          error: e.toString(),
        ),
      );
    }
  }

  void _applyBucketFromCache(int bucket) {
    final raw = _rawCache;

    if (raw == null || raw.isEmpty) {
      emit(
        state.copyWith(
          activeBucket: bucket,
          mapGeoms: const [],
          geomVersion: state.geomVersion + 1,
        ),
      );

      _activeBucket = bucket;
      return;
    }

    final cached = _geomCacheByBucket[bucket];

    if (cached != null) {
      _activeBucket = bucket;

      emit(
        state.copyWith(
          activeBucket: bucket,
          mapGeoms: cached,
          geomVersion: state.geomVersion + 1,
        ),
      );

      return;
    }

    final tolerance = _toleranceMetersForBucket(bucket);
    final stride = _strideForBucket(bucket);

    final sw = Stopwatch()..start();

    _perf('[PERF] ActiveRoads.applyBucket(bucket=$bucket) :: start=0ms');

    final geoms = _buildGeomsForBucket(
      rows: raw,
      toleranceMeters: tolerance,
      stride: stride,
    );

    _geomCacheByBucket[bucket] = geoms;
    _activeBucket = bucket;

    emit(
      state.copyWith(
        activeBucket: bucket,
        mapGeoms: geoms,
        geomVersion: state.geomVersion + 1,
      ),
    );

    sw.stop();

    final simpPointsTotal = geoms.fold<int>(
      0,
          (acc, geom) {
        final segmentPoints = geom.segments.fold<int>(
          0,
              (sum, segment) => sum + segment.length,
        );

        return acc + segmentPoints;
      },
    );

    _perf(
      '[PERF] ActiveRoads.applyBucket(bucket=$bucket) :: END=${sw.elapsedMilliseconds}ms simpPointsTotal=$simpPointsTotal tol=${tolerance.toStringAsFixed(0)}m stride=$stride',
    );
  }

  List<ActiveRoadMapGeom> _buildGeomsForBucket({
    required List<_RoadRowSegments> rows,
    required double toleranceMeters,
    required int stride,
  }) {
    final out = <ActiveRoadMapGeom>[];

    for (final row in rows) {
      final segmentsOut = <List<LatLng>>[];

      for (final segment in row.segments) {
        if (segment.length < 2) continue;

        var points = segment;

        if (stride > 1) {
          points = _decimate(points, stride);

          if (points.length < 2) continue;
        }

        points = _simplifyRdpMeters(points, toleranceMeters);

        if (points.length < 2) continue;

        segmentsOut.add(points);
      }

      if (segmentsOut.isEmpty) continue;

      out.add(
        ActiveRoadMapGeom(
          id: row.id,
          road: row.road,
          segments: segmentsOut,
        ),
      );
    }

    return out;
  }

  List<String> _buildRegionLabelsFromData(List<ActiveRoadsData> list) {
    final labels = list
        .map((road) => road.displayRegion.trim())
        .where((label) => label.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toUpperCase().compareTo(b.toUpperCase()));

    return labels;
  }

  List<ActiveRoadsData> _sortRoads(List<ActiveRoadsData> list) {
    final out = List<ActiveRoadsData>.from(list);

    out.sort((a, b) {
      final aAcronym = a.acronym ?? '';
      final bAcronym = b.acronym ?? '';

      final acronymCompare = aAcronym.compareTo(bAcronym);

      if (acronymCompare != 0) return acronymCompare;

      final aKm = a.initialKm ?? 0;
      final bKm = b.initialKm ?? 0;

      return aKm.compareTo(bKm);
    });

    return out;
  }

  List<_RoadRowSegments> _buildRawSegmentsFromRoads(
      List<ActiveRoadsData> list,
      ) {
    final out = <_RoadRowSegments>[];

    for (final road in list) {
      final id = road.id;
      final points = road.points;

      if (id == null || id.trim().isEmpty) continue;
      if (points == null || points.length < 2) continue;

      final segments = _splitByGapMeters(
        points,
        maxGapMeters: 2500,
      );

      final cleanSegments = <List<LatLng>>[];
      var rawPointsTotal = 0;

      for (final segment in segments) {
        if (segment.length < 2) continue;

        rawPointsTotal += segment.length;
        cleanSegments.add(segment);
      }

      if (cleanSegments.isEmpty) continue;

      out.add(
        _RoadRowSegments(
          id: id,
          road: road,
          segments: cleanSegments,
          rawPointsTotal: rawPointsTotal,
        ),
      );
    }

    return out;
  }

  List<List<LatLng>> _splitByGapMeters(
      List<LatLng> points, {
        required double maxGapMeters,
      }) {
    if (points.length < 2) {
      return <List<LatLng>>[points];
    }

    final distance = const Distance();
    final out = <List<LatLng>>[];

    var current = <LatLng>[points.first];

    for (int i = 1; i < points.length; i++) {
      final previous = points[i - 1];
      final currentPoint = points[i];

      final gap = distance.as(
        LengthUnit.Meter,
        previous,
        currentPoint,
      );

      if (gap > maxGapMeters && current.length >= 2) {
        out.add(current);
        current = <LatLng>[currentPoint];
      } else {
        current.add(currentPoint);
      }
    }

    if (current.length >= 2) {
      out.add(current);
    }

    if (out.isEmpty) {
      out.add(points);
    }

    return out;
  }

  ActiveRoadsData? findById(String id) {
    final cleanId = id.trim();

    if (cleanId.isEmpty) return null;

    for (final road in state.all) {
      if (road.id == cleanId) return road;
    }

    return null;
  }

  ActiveRoadsData? findByPolylineTag(Object? tag) {
    final id = tag?.toString().trim();

    if (id == null || id.isEmpty) return null;

    return findById(id);
  }

  String tooltipTitle(ActiveRoadsData road) {
    final acronym = road.acronym ?? '--';
    final code = road.roadCode ?? '--';

    return 'Rodovia: AL-$acronym ($code)';
  }

  String tooltipSubtitle(ActiveRoadsData road) {
    final initialSegment = road.initialSegment ?? '--';
    final finalSegment = road.finalSegment ?? '--';
    final extension = road.extension?.toStringAsFixed(2) ?? '--';

    return 'Trecho: $initialSegment / $finalSegment, $extension km de extensão';
  }

  void syncRegionsFromTenantItems(List<TenantItemData> tenantRegions) {
    final labels = tenantRegions
        .map((region) {
      final regionName = region.extra['regionName']?.toString().trim();

      if (regionName != null && regionName.isNotEmpty) {
        return regionName;
      }

      return region.label.trim();
    })
        .where((label) => label.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toUpperCase().compareTo(b.toUpperCase()));

    emit(
      state.copyWith(
        regionLabels: labels,
      ),
    );
  }

  /// Alias temporário para telas antigas que ainda chamarem `syncRegionsFromSetup`.
  void syncRegionsFromSetup(List<TenantItemData> tenantRegions) {
    syncRegionsFromTenantItems(tenantRegions);
  }

  void selectPolyline(String? id) {
    emit(
      state.copyWith(
        selectedPolylineId: id,
      ),
    );
  }

  void clearPolylineSelection() {
    emit(
      state.copyWith(
        selectedPolylineId: null,
      ),
    );
  }

  void setRegionFilter(String? region) {
    emit(
      state.copyWith(
        selectedRegionFilter: region,
      ),
    );
  }

  void setSurfaceFilter(String? surfaceCode) {
    emit(
      state.copyWith(
        selectedSurfaceFilter: surfaceCode,
      ),
    );
  }

  void setPieFilter(int? pieIndex) {
    emit(
      state.copyWith(
        selectedPieIndexFilter: pieIndex,
      ),
    );
  }

  void setVsaFilter(int? vsa) {
    emit(
      state.copyWith(
        selectedVsaFilter: vsa,
      ),
    );
  }

  Future<void> upsert(ActiveRoadsData data) async {
    emit(
      state.copyWith(
        savingOrImporting: true,
        error: null,
      ),
    );

    try {
      final saved = await _repo.upsert(data);

      final list = List<ActiveRoadsData>.from(state.all);
      final index = list.indexWhere((road) => road.id == saved.id);

      if (index == -1) {
        list.add(saved);
      } else {
        list[index] = saved;
      }

      final sorted = _sortRoads(list);
      final regionLabels = _buildRegionLabelsFromData(sorted);

      clearCache();

      _rawCache = _buildRawSegmentsFromRoads(sorted);

      final bucket = _activeBucket ?? 4;

      _applyBucketFromCache(bucket);

      emit(
        state.copyWith(
          all: sorted,
          regionLabels: regionLabels,
          savingOrImporting: false,
          error: null,
        ),
      );
    } catch (e, s) {
      _perf('ActiveRoads.upsert error: $e');
      _perf('$s');

      emit(
        state.copyWith(
          savingOrImporting: false,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> deleteById(String id) async {
    emit(
      state.copyWith(
        savingOrImporting: true,
        error: null,
      ),
    );

    try {
      await _repo.deleteById(id);

      final filtered = List<ActiveRoadsData>.from(state.all)
        ..removeWhere((road) => road.id == id);

      final sorted = _sortRoads(filtered);
      final regionLabels = _buildRegionLabelsFromData(sorted);

      clearCache();

      _rawCache = _buildRawSegmentsFromRoads(sorted);

      final bucket = _activeBucket ?? 4;

      _applyBucketFromCache(bucket);

      emit(
        state.copyWith(
          all: sorted,
          regionLabels: regionLabels,
          savingOrImporting: false,
          error: null,
        ),
      );
    } catch (e, s) {
      _perf('ActiveRoads.deleteById error: $e');
      _perf('$s');

      emit(
        state.copyWith(
          savingOrImporting: false,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> importBatch({
    required List<Map<String, dynamic>> linhasPrincipais,
    required List<Map<String, dynamic>> subcolecoes,
  }) async {
    emit(
      state.copyWith(
        savingOrImporting: true,
        error: null,
      ),
    );

    try {
      await _repo.importarRodoviasComCoordenadas(
        linhasPrincipais: linhasPrincipais,
        subcolecoes: subcolecoes,
      );

      final bounds = _lastBounds;
      final zoom = _lastZoom;

      emit(
        state.copyWith(
          savingOrImporting: false,
          error: null,
        ),
      );

      if (bounds != null && zoom != null) {
        await loadViewport(
          bucket: bucketForZoom(zoom),
          bounds: bounds,
          forceRefresh: true,
        );
      } else {
        await refresh(
          bucket: _activeBucket ?? 4,
        );
      }
    } catch (e, s) {
      _perf('ActiveRoads.importBatch error: $e');
      _perf('$s');

      emit(
        state.copyWith(
          savingOrImporting: false,
          error: e.toString(),
        ),
      );
    }
  }

  static int bucketForZoom(double zoom) {
    if (zoom < 6.2) return 1;
    if (zoom < 7.5) return 2;
    if (zoom < 9.2) return 3;
    if (zoom < 11.2) return 4;

    return 5;
  }

  double _toleranceMetersForBucket(int bucket) {
    switch (bucket) {
      case 1:
        return 1800;
      case 2:
        return 900;
      case 3:
        return 300;
      case 4:
        return 80;
      case 5:
      default:
        return 20;
    }
  }

  int _strideForBucket(int bucket) {
    switch (bucket) {
      case 1:
        return 18;
      case 2:
        return 12;
      case 3:
        return 8;
      case 4:
        return 4;
      case 5:
      default:
        return 1;
    }
  }

  List<LatLng> _decimate(List<LatLng> points, int step) {
    if (points.length <= 2 || step <= 1) return points;

    final out = <LatLng>[points.first];

    for (int i = step; i < points.length - 1; i += step) {
      out.add(points[i]);
    }

    out.add(points.last);

    return out;
  }

  List<LatLng> _simplifyRdpMeters(
      List<LatLng> points,
      double toleranceMeters,
      ) {
    if (points.length <= 2 || toleranceMeters <= 0) return points;

    final toleranceSquared = toleranceMeters * toleranceMeters;

    final keep = List<bool>.filled(points.length, false);

    keep[0] = true;
    keep[points.length - 1] = true;

    final stack = <_IdxPair>[
      _IdxPair(0, points.length - 1),
    ];

    while (stack.isNotEmpty) {
      final segment = stack.removeLast();

      final start = segment.a;
      final end = segment.b;

      if (end <= start + 1) continue;

      int index = -1;
      double maxDistanceSquared = -1;

      final a = points[start];
      final b = points[end];

      for (int i = start + 1; i < end; i++) {
        final distanceSquared = _distPointToSegmentMeters2(
          points[i],
          a,
          b,
        );

        if (distanceSquared > maxDistanceSquared) {
          maxDistanceSquared = distanceSquared;
          index = i;
        }
      }

      if (index != -1 && maxDistanceSquared > toleranceSquared) {
        keep[index] = true;

        stack.add(_IdxPair(start, index));
        stack.add(_IdxPair(index, end));
      }
    }

    final out = <LatLng>[];

    for (int i = 0; i < points.length; i++) {
      if (keep[i]) {
        out.add(points[i]);
      }
    }

    return out.length >= 2 ? out : <LatLng>[points.first, points.last];
  }

  double _distPointToSegmentMeters2(
      LatLng p,
      LatLng a,
      LatLng b,
      ) {
    final lat0 = (a.latitude + b.latitude) * 0.5 * math.pi / 180.0;
    final cosLat = math.cos(lat0);

    const metersPerDegLat = 111320.0;

    double toY(double latDeg) => latDeg * metersPerDegLat;
    double toX(double lonDeg) => lonDeg * metersPerDegLat * cosLat;

    final ax = toX(a.longitude);
    final ay = toY(a.latitude);

    final bx = toX(b.longitude);
    final by = toY(b.latitude);

    final px = toX(p.longitude);
    final py = toY(p.latitude);

    final dx = bx - ax;
    final dy = by - ay;

    if (dx == 0 && dy == 0) {
      final ux = px - ax;
      final uy = py - ay;

      return ux * ux + uy * uy;
    }

    final t = ((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy);
    final tt = t.clamp(0.0, 1.0);

    final cx = ax + tt * dx;
    final cy = ay + tt * dy;

    final ex = px - cx;
    final ey = py - cy;

    return ex * ex + ey * ey;
  }

  void _perf(String message) {
    if (kDebugMode) {
      print(message);
    }
  }
}

class _IdxPair {
  final int a;
  final int b;

  const _IdxPair(this.a, this.b);
}

class _RoadRowSegments {
  final String id;
  final ActiveRoadsData road;
  final List<List<LatLng>> segments;
  final int rawPointsTotal;

  const _RoadRowSegments({
    required this.id,
    required this.road,
    required this.segments,
    required this.rawPointsTotal,
  });
}