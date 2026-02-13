// lib/_blocs/modules/actives/roads/active_roads_cubit.dart
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sipged/_utils/geometry/sipged_tile_math.dart';

import 'active_roads_data.dart';
import 'active_roads_repository.dart';
import 'active_roads_state.dart';
import 'package:sipged/_blocs/system/setup/setup_data.dart';

class ActiveRoadsCubit extends Cubit<ActiveRoadsState> {
  final ActiveRoadsRepository _repo;

  ActiveRoadsCubit({ActiveRoadsRepository? repository})
      : _repo = repository ?? ActiveRoadsRepository(),
        super(const ActiveRoadsState());

  // ---------------------------------------------------------------------------
  // Configs globais
  // ---------------------------------------------------------------------------
  static const double clusterUntilZoom = 12.0;
  bool shouldUseCluster(double zoom) => zoom < clusterUntilZoom;

  // ---------------------------------------------------------------------------
  // Cache raw + cache por bucket
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // API pública
  // ---------------------------------------------------------------------------

  /// Warmup: se não tiver bounds ainda, tenta manter comportamento antigo (fetchAll),
  /// mas você vai ganhar performance real usando onCameraChangedEx (viewport).
  Future<void> warmup({int bucket = 4}) async {
    if (_lastBounds != null) {
      await loadViewport(bucket: bucket, bounds: _lastBounds!);
      return;
    }

    // fallback (primeira carga, sem viewport ainda)
    await _loadAllFallback(setInitialized: true, bucket: bucket);
  }

  Future<void> refresh({int bucket = 4}) async {
    if (_lastBounds != null) {
      await loadViewport(bucket: bucket, bounds: _lastBounds!, forceRefresh: true);
      return;
    }
    await _loadAllFallback(setInitialized: false, bucket: bucket, forceRefresh: true);
  }

  /// ✅ NOVO: câmera mudou (zoom + bounds). Aqui é onde fica “Google/OSM-like”.
  void onCameraChanged({
    required double zoom,
    required LatLngBounds bounds,
  }) {
    _lastBounds = bounds;
    _lastZoom = zoom;

    final _ = bucketForZoom(zoom);

    _cameraDebounce?.cancel();
    _cameraDebounce = Timer(_cameraDebounceDuration, () async {
      final b = _lastBounds;
      final z = _lastZoom;
      if (b == null || z == null) return;

      final bk = bucketForZoom(z);
      await loadViewport(bucket: bk, bounds: b);
    });

    // mantém cache de geometria por bucket (debounce “curto”)
    onZoomChanged(zoom: zoom);
  }

  /// Mantém o seu bucket/cache para simplificação por zoom
  void onZoomChanged({required double zoom}) {
    final bucket = bucketForZoom(zoom);
    if (_activeBucket == bucket) return;

    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, () {
      if (_rawCache == null) return;
      _applyBucketFromCache(bucket);
    });
  }

  void clearCache() {
    _rawCache = null;
    _geomCacheByBucket.clear();
    _activeBucket = null;
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    _cameraDebounce?.cancel();
    return super.close();
  }

  // ---------------------------------------------------------------------------
  // Viewport loader (tiles + bucket)
  // ---------------------------------------------------------------------------

  Future<void> loadViewport({
    required int bucket,
    required LatLngBounds bounds,
    bool forceRefresh = false,
  }) async {
    final reqId = ++_requestSeq;

    // não piscar shimmer se já tem algo desenhado
    final bool hasData = state.all.isNotEmpty && state.mapGeoms.isNotEmpty;
    emit(state.copyWith(
      loadStatus: hasData ? state.loadStatus : ActiveRoadsLoadStatus.loading,
      error: null,
    ));

    try {
      // zTile (quanto menor, menos tiles) — ajuste fino conforme seu dataset
      final zTile = _tileZoomForBucket(bucket);

      final quadKeys = SipGedTileMath.quadKeysForBounds(
        bounds: bounds,
        z: zTile,
        maxTiles: 80,
      );

      final list = await _repo.fetchByTiles(bucket: bucket, quadKeys: quadKeys);
      if (reqId != _requestSeq) return;

      // labels podem vir do Setup; aqui vai do conjunto visível
      final regionLabels = _buildRegionLabelsFromData(list);

      // invalida caches se mudou o conjunto (ou se quiser sempre)
      if (forceRefresh) {
        clearCache();
      } else {
        _geomCacheByBucket.clear(); // mantém raw e refaz geoms se necessário
      }

      _rawCache = _buildRawSegmentsFromRoads(list);
      _applyBucketFromCache(bucket, emitLoading: false);

      if (reqId != _requestSeq) return;

      emit(state.copyWith(
        initialized: true,
        all: list,
        regionLabels: regionLabels,
        loadStatus: ActiveRoadsLoadStatus.success,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        loadStatus: ActiveRoadsLoadStatus.failure,
        error: e.toString(),
      ));
    }
  }

  int _tileZoomForBucket(int bucket) {
    // bucket maior -> tile zoom maior (mais detalhe / mais tiles)
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

  // ---------------------------------------------------------------------------
  // Fallback loader (antigo fetchAll) — mantém para não quebrar se bounds não vier
  // ---------------------------------------------------------------------------

  Future<void> _loadAllFallback({
    required bool setInitialized,
    required int bucket,
    bool forceRefresh = false,
  }) async {
    final reqId = ++_requestSeq;

    emit(state.copyWith(
      loadStatus: ActiveRoadsLoadStatus.loading,
      error: null,
    ));

    try {
      final sw = Stopwatch()..start();
      _perf('[PERF] ActiveRoads.loadAllFallback(bucket=$bucket) :: start=0ms');

      final list = await _repo.fetchAll();
      if (reqId != _requestSeq) return;

      final regionLabels = _buildRegionLabelsFromData(list);

      if (forceRefresh || _rawCache == null) {
        final tParse = Stopwatch()..start();
        _rawCache = _buildRawSegmentsFromRoads(list);
        tParse.stop();

        final rawPointsTotal =
        _rawCache!.fold<int>(0, (acc, e) => acc + e.rawPointsTotal);
        _perf(
          '[PERF] ActiveRoads.loadAllFallback(bucket=$bucket) :: parse rows=${_rawCache!.length} rawPointsTotal=$rawPointsTotal = ${tParse.elapsedMilliseconds}ms',
        );
      }

      _applyBucketFromCache(bucket, emitLoading: false);
      if (reqId != _requestSeq) return;

      emit(state.copyWith(
        initialized: setInitialized ? true : state.initialized,
        all: list,
        regionLabels: regionLabels,
        loadStatus: ActiveRoadsLoadStatus.success,
        error: null,
      ));

      sw.stop();
      _perf('[PERF] ActiveRoads.loadAllFallback(bucket=$bucket) :: END=${sw.elapsedMilliseconds}ms');
    } catch (e) {
      emit(state.copyWith(
        loadStatus: ActiveRoadsLoadStatus.failure,
        error: e.toString(),
      ));
    }
  }

  // ---------------------------------------------------------------------------
  // Bucket/cache apply
  // ---------------------------------------------------------------------------

  void _applyBucketFromCache(int bucket, {bool emitLoading = true}) {
    final raw = _rawCache;
    if (raw == null || raw.isEmpty) {
      emit(state.copyWith(
        activeBucket: bucket,
        mapGeoms: const [],
        geomVersion: state.geomVersion + 1,
      ));
      _activeBucket = bucket;
      return;
    }

    if (_geomCacheByBucket.containsKey(bucket)) {
      _activeBucket = bucket;
      emit(state.copyWith(
        activeBucket: bucket,
        mapGeoms: _geomCacheByBucket[bucket]!,
        geomVersion: state.geomVersion + 1,
      ));
      return;
    }

    final tol = _toleranceMetersForBucket(bucket);
    final stride = _strideForBucket(bucket);

    final sw = Stopwatch()..start();
    _perf('[PERF] ActiveRoads.applyBucket(bucket=$bucket) :: start=0ms');

    final geoms = _buildGeomsForBucket(
      rows: raw,
      bucket: bucket,
      toleranceMeters: tol,
      stride: stride,
    );

    _geomCacheByBucket[bucket] = geoms;
    _activeBucket = bucket;

    emit(state.copyWith(
      activeBucket: bucket,
      mapGeoms: geoms,
      geomVersion: state.geomVersion + 1,
    ));

    sw.stop();

    final simpPointsTotal = geoms.fold<int>(
      0,
          (acc, g) => acc + g.segments.fold<int>(0, (a, s) => a + s.length),
    );

    _perf(
      '[PERF] ActiveRoads.applyBucket(bucket=$bucket) :: END=${sw.elapsedMilliseconds}ms simpPointsTotal=$simpPointsTotal tol=${tol.toStringAsFixed(0)}m stride=$stride',
    );
  }

  List<ActiveRoadMapGeom> _buildGeomsForBucket({
    required List<_RoadRowSegments> rows,
    required int bucket,
    required double toleranceMeters,
    required int stride,
  }) {
    final out = <ActiveRoadMapGeom>[];

    for (final rr in rows) {
      final segsOut = <List<LatLng>>[];

      for (final seg in rr.segments) {
        if (seg.length < 2) continue;

        var pts = seg;

        if (stride > 1) {
          pts = _decimate(pts, stride);
          if (pts.length < 2) continue;
        }

        pts = _simplifyRdpMeters(pts, toleranceMeters);
        if (pts.length < 2) continue;

        segsOut.add(pts);
      }

      if (segsOut.isEmpty) continue;

      out.add(
        ActiveRoadMapGeom(
          id: rr.id,
          road: rr.road,
          segments: segsOut,
        ),
      );
    }

    return out;
  }

  // ---------------------------------------------------------------------------
  // Helpers internos
  // ---------------------------------------------------------------------------

  List<String> _buildRegionLabelsFromData(List<ActiveRoadsData> list) {
    final labels = list
        .map((r) => (r.regional ?? r.metadata?['regional'] ?? '').toString().trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toUpperCase().compareTo(b.toUpperCase()));

    return labels;
  }

  List<_RoadRowSegments> _buildRawSegmentsFromRoads(List<ActiveRoadsData> list) {
    final out = <_RoadRowSegments>[];

    for (final r in list) {
      final id = r.id;
      final pts = r.points;
      if (id == null || pts == null || pts.length < 2) continue;

      final segments = _splitByGapMeters(
        pts,
        maxGapMeters: 2500,
      );

      final cleanSegs = <List<LatLng>>[];
      var rawPointsTotal = 0;

      for (final s in segments) {
        if (s.length < 2) continue;
        rawPointsTotal += s.length;
        cleanSegs.add(s);
      }

      if (cleanSegs.isEmpty) continue;

      out.add(
        _RoadRowSegments(
          id: id,
          road: r,
          segments: cleanSegs,
          rawPointsTotal: rawPointsTotal,
        ),
      );
    }

    return out;
  }

  List<List<LatLng>> _splitByGapMeters(
      List<LatLng> pts, {
        required double maxGapMeters,
      }) {
    if (pts.length < 2) return <List<LatLng>>[pts];

    final dist = const Distance();
    final out = <List<LatLng>>[];
    var cur = <LatLng>[pts.first];

    for (int i = 1; i < pts.length; i++) {
      final a = pts[i - 1];
      final b = pts[i];
      final d = dist.as(LengthUnit.Meter, a, b);

      if (d > maxGapMeters && cur.length >= 2) {
        out.add(cur);
        cur = <LatLng>[b];
      } else {
        cur.add(b);
      }
    }

    if (cur.length >= 2) out.add(cur);
    if (out.isEmpty) out.add(pts);
    return out;
  }

  // ---------------------------------------------------------------------------
  // Lookup / Tooltips / Filtros / CRUD (mantidos)
  // ---------------------------------------------------------------------------

  ActiveRoadsData? findById(String id) {
    for (final r in state.all) {
      if (r.id == id) return r;
    }
    return null;
  }

  ActiveRoadsData? findByPolylineTag(Object? tag) {
    final id = tag?.toString();
    if (id == null) return null;
    return findById(id);
  }

  String tooltipTitle(ActiveRoadsData road) {
    final acr = road.acronym ?? '--';
    final cod = road.roadCode ?? '--';
    return 'Rodovia: AL-$acr ($cod)';
  }

  String tooltipSubtitle(ActiveRoadsData road) {
    final ini = road.initialSegment ?? '--';
    final fim = road.finalSegment ?? '--';
    final ext = road.extension?.toStringAsFixed(2) ?? '--';
    return 'Trecho: $ini / $fim, $ext km de extensão';
  }

  void syncRegionsFromSetup(List<SetupData> setupRegions) {
    final labels = setupRegions
        .map((r) => (r.regionName ?? r.label).trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toUpperCase().compareTo(b.toUpperCase()));

    emit(state.copyWith(regionLabels: labels));
  }

  void selectPolyline(String? id) => emit(state.copyWith(selectedPolylineId: id));
  void clearPolylineSelection() => emit(state.copyWith(selectedPolylineId: null));
  void setRegionFilter(String? region) => emit(state.copyWith(selectedRegionFilter: region));
  void setSurfaceFilter(String? surfaceCode) => emit(state.copyWith(selectedSurfaceFilter: surfaceCode));
  void setPieFilter(int? pieIndex) => emit(state.copyWith(selectedPieIndexFilter: pieIndex));

  Future<void> upsert(ActiveRoadsData data) async {
    emit(state.copyWith(savingOrImporting: true, error: null));
    try {
      final saved = await _repo.upsert(data);

      final list = List<ActiveRoadsData>.from(state.all);
      final idx = list.indexWhere((r) => r.id == saved.id);
      if (idx == -1) {
        list.add(saved);
      } else {
        list[idx] = saved;
      }

      list.sort((a, b) {
        final aKey = '${a.acronym ?? ''}_${a.initialKm ?? 0}';
        final bKey = '${b.acronym ?? ''}_${b.initialKm ?? 0}';
        return aKey.compareTo(bKey);
      });

      final regionLabels = _buildRegionLabelsFromData(list);

      clearCache();
      _rawCache = _buildRawSegmentsFromRoads(list);
      final bucket = _activeBucket ?? 4;
      _applyBucketFromCache(bucket);

      emit(state.copyWith(
        all: list,
        regionLabels: regionLabels,
        savingOrImporting: false,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        savingOrImporting: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> deleteById(String id) async {
    emit(state.copyWith(savingOrImporting: true, error: null));
    try {
      await _repo.deleteById(id);
      final filtered = [...state.all]..removeWhere((r) => r.id == id);

      final regionLabels = _buildRegionLabelsFromData(filtered);

      clearCache();
      _rawCache = _buildRawSegmentsFromRoads(filtered);
      final bucket = _activeBucket ?? 4;
      _applyBucketFromCache(bucket);

      emit(state.copyWith(
        all: filtered,
        regionLabels: regionLabels,
        savingOrImporting: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        savingOrImporting: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> importBatch({
    required List<Map<String, dynamic>> linhasPrincipais,
    required List<Map<String, dynamic>> subcolecoes,
  }) async {
    emit(state.copyWith(savingOrImporting: true, error: null));
    try {
      await _repo.importarRodoviasComCoordenadas(
        linhasPrincipais: linhasPrincipais,
        subcolecoes: subcolecoes,
      );

      // após importar, recarrega viewport se tiver bounds, senão fallback total
      final b = _lastBounds;
      final z = _lastZoom;
      emit(state.copyWith(savingOrImporting: false, error: null));

      if (b != null && z != null) {
        await loadViewport(bucket: bucketForZoom(z), bounds: b, forceRefresh: true);
      } else {
        await refresh(bucket: _activeBucket ?? 4);
      }
    } catch (e) {
      emit(state.copyWith(
        savingOrImporting: false,
        error: e.toString(),
      ));
    }
  }

  // ---------------------------------------------------------------------------
  // BUCKET
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // Simplificação (RDP) + decimate
  // ---------------------------------------------------------------------------

  List<LatLng> _decimate(List<LatLng> pts, int step) {
    if (pts.length <= 2) return pts;
    if (step <= 1) return pts;

    final out = <LatLng>[pts.first];
    for (int i = step; i < pts.length - 1; i += step) {
      out.add(pts[i]);
    }
    out.add(pts.last);
    return out;
  }

  List<LatLng> _simplifyRdpMeters(List<LatLng> pts, double toleranceMeters) {
    if (pts.length <= 2) return pts;
    if (toleranceMeters <= 0) return pts;

    final tol2 = toleranceMeters * toleranceMeters;
    final keep = List<bool>.filled(pts.length, false);
    keep[0] = true;
    keep[pts.length - 1] = true;

    final stack = <_IdxPair>[_IdxPair(0, pts.length - 1)];

    while (stack.isNotEmpty) {
      final seg = stack.removeLast();
      final s = seg.a;
      final e = seg.b;
      if (e <= s + 1) continue;

      int index = -1;
      double maxDist2 = -1;

      final a = pts[s];
      final b = pts[e];

      for (int i = s + 1; i < e; i++) {
        final d2 = _distPointToSegmentMeters2(pts[i], a, b);
        if (d2 > maxDist2) {
          maxDist2 = d2;
          index = i;
        }
      }

      if (index != -1 && maxDist2 > tol2) {
        keep[index] = true;
        stack.add(_IdxPair(s, index));
        stack.add(_IdxPair(index, e));
      }
    }

    final out = <LatLng>[];
    for (int i = 0; i < pts.length; i++) {
      if (keep[i]) out.add(pts[i]);
    }
    return out.length >= 2 ? out : <LatLng>[pts.first, pts.last];
  }

  double _distPointToSegmentMeters2(LatLng p, LatLng a, LatLng b) {
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

  // ---------------------------------------------------------------------------
  // LOG
  // ---------------------------------------------------------------------------

  void _perf(String msg) {
    if (kDebugMode) {
      // ignore: avoid_print
      print(msg);
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
