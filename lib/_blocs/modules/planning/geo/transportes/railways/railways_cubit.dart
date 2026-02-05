// lib/_blocs/modules/planning/geo/transportes/railways/railways_cubit.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';

import 'package:siged/_widgets/map/polylines/tappable_changed_polyline.dart';

import 'railways_repository.dart';
import 'railways_state.dart';

class RailwaysCubit extends Cubit<RailwaysState> {
  RailwaysCubit({required RailwaysRepository repository})
      : _repo = repository,
        super(const RailwaysState());

  final RailwaysRepository _repo;

  // ---------------------------------------------------------------------------
  // Cache por UF: mantém geometria "raw" em segmentos para re-simplificar rápido.
  // key: UF
  // value: lista de "rows" já com segmentos extraídos
  // ---------------------------------------------------------------------------
  final Map<String, List<_RailRowSegments>> _rawCacheByUf = {};

  // Cache do EIXO (centerline) simplificado por UF + bucket.
  // Isso é barato de reutilizar quando apenas o zoom muda (dormentes).
  // key: "$UF|$bucket"
  final Map<String, List<_RailCenterline>> _centerlineCache = {};

  // Cache FINAL (centerline + dormentes) por UF + bucket + styleKey(zoom quantizado).
  // key: "$UF|$bucket|$styleKey"
  final Map<String, List<TappableChangedPolyline>> _polyCache = {};

  // Controle de concorrência
  int _requestSeq = 0;

  // Debounce para mudança de bucket/style por zoom (evita flood em pan/zoom)
  Timer? _debounce;
  static const Duration _debounceDuration = Duration(milliseconds: 180);

  // Estado aplicado atual
  int? _activeBucket;
  double? _activeStyleZoomQ; // zoom quantizado usado para dormentes

  // ---------------------------------------------------------------------------
  // API PÚBLICA
  // ---------------------------------------------------------------------------

  /// Carrega as ferrovias da UF.
  ///
  /// - bucket controla simplificação do eixo (centerline)
  /// - zoom controla o estilo dos dormentes (densidade + tamanho) em função de pixels
  Future<void> loadByUF(
      String uf, {
        required double zoom,
        int? bucket, // se null, calcula pelo zoom
        bool forceRefresh = false,
      }) async {
    final ufNorm = uf.trim().toUpperCase();
    final reqId = ++_requestSeq;

    final useBucket = bucket ?? bucketForZoom(zoom);
    final styleZoomQ = _quantizeZoom(zoom, step: 0.25);

    try {
      emit(state.copyWith(isLoading: true, errorMessage: null));

      final sw = Stopwatch()..start();
      _perf('[PERF] Railways.loadByUF(uf=$ufNorm,bucket=$useBucket,zoom=$zoom,styleQ=$styleZoomQ) :: start');

      // 1) Fetch + parse segmentos (somente se não tiver cache ou forceRefresh)
      List<_RailRowSegments> rowsSegs;

      if (!forceRefresh && _rawCacheByUf.containsKey(ufNorm)) {
        rowsSegs = _rawCacheByUf[ufNorm]!;
      } else {
        final tFetch = Stopwatch()..start();
        final rows = await _repo.fetchByUF(ufNorm);
        tFetch.stop();

        _perf('[PERF] Railways.fetch rows=${rows.length} = ${tFetch.elapsedMilliseconds}ms');

        final tParse = Stopwatch()..start();
        rowsSegs = _buildRawSegmentsFromRows(rows, ufNorm);
        tParse.stop();

        final rawPointsTotal =
        rowsSegs.fold<int>(0, (acc, e) => acc + e.rawPointsTotal);

        _perf(
          '[PERF] Railways.parse geoms=${rowsSegs.length} rawPointsTotal=$rawPointsTotal = ${tParse.elapsedMilliseconds}ms',
        );

        _rawCacheByUf[ufNorm] = rowsSegs;

        // Se forceRefresh, invalida caches derivados desta UF
        if (forceRefresh) {
          _invalidateDerivedCachesForUf(ufNorm);
        }
      }

      // Cancelamento lógico
      if (reqId != _requestSeq) return;

      // 2) Centerlines por UF|bucket (reutilizável p/ diferentes zooms)
      final centerKey = '$ufNorm|$useBucket';
      List<_RailCenterline> centerlines;

      if (_centerlineCache.containsKey(centerKey)) {
        centerlines = _centerlineCache[centerKey]!;
      } else {
        final tCenter = Stopwatch()..start();
        centerlines = _buildCenterlinesForBucket(
          uf: ufNorm,
          rows: rowsSegs,
          bucket: useBucket,
        );
        tCenter.stop();

        _centerlineCache[centerKey] = centerlines;

        final ptsTotal = centerlines.fold<int>(0, (a, c) => a + c.points.length);
        _perf('[PERF] Railways.centerlines count=${centerlines.length} ptsTotal=$ptsTotal = ${tCenter.elapsedMilliseconds}ms');
      }

      // Cancelamento lógico
      if (reqId != _requestSeq) return;

      // 3) Polylines finais por UF|bucket|styleKey
      final styleKey = '$ufNorm|$useBucket|$styleZoomQ';
      List<TappableChangedPolyline> polylines;

      if (_polyCache.containsKey(styleKey)) {
        polylines = _polyCache[styleKey]!;
      } else {
        final tStyle = Stopwatch()..start();
        polylines = _buildFinalPolylinesForStyle(
          centerlines: centerlines,
          zoom: styleZoomQ,
        );
        tStyle.stop();

        _polyCache[styleKey] = polylines;

        _perf('[PERF] Railways.style build polylines=${polylines.length} = ${tStyle.elapsedMilliseconds}ms');
      }

      // Cancelamento lógico
      if (reqId != _requestSeq) return;

      _activeBucket = useBucket;
      _activeStyleZoomQ = styleZoomQ;

      emit(state.copyWith(isLoading: false, errorMessage: null, polylines: polylines));

      sw.stop();
      _perf('[PERF] Railways.loadByUF END = ${sw.elapsedMilliseconds}ms');
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  /// Chame isso no Map.onCameraChanged / onPositionChanged.
  ///
  /// Ele decide:
  /// - se mudou bucket -> reusa raw e refaz centerline (ou pega cache)
  /// - se mudou apenas estilo -> refaz somente dormentes (rápido) via cache style
  void onZoomChanged({
    required String uf,
    required double zoom,
  }) {
    final ufNorm = uf.trim().toUpperCase();
    final newBucket = bucketForZoom(zoom);
    final newStyleZoomQ = _quantizeZoom(zoom, step: 0.25);

    // nada mudou (nem bucket nem estilo)
    if (_activeBucket == newBucket && _activeStyleZoomQ == newStyleZoomQ) return;

    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, () async {
      // Se não há raw ainda, faz load completo.
      if (!_rawCacheByUf.containsKey(ufNorm)) {
        await loadByUF(ufNorm, zoom: zoom, bucket: newBucket);
        return;
      }

      // Se bucket mudou, precisamos garantir centerlines do bucket.
      final centerKey = '$ufNorm|$newBucket';
      if (!_centerlineCache.containsKey(centerKey)) {
        // gera centerlines a partir do raw cache
        final rowsSegs = _rawCacheByUf[ufNorm]!;
        _centerlineCache[centerKey] = _buildCenterlinesForBucket(
          uf: ufNorm,
          rows: rowsSegs,
          bucket: newBucket,
        );
      }

      // Agora aplica o estilo (cache final).
      _applyStyleFromCache(
        ufNorm: ufNorm,
        bucket: newBucket,
        styleZoomQ: newStyleZoomQ,
      );
    });
  }

  /// Para limpar caches quando necessário (ex.: logout, troca de dataset, etc.)
  void clearCache() {
    _rawCacheByUf.clear();
    _centerlineCache.clear();
    _polyCache.clear();
    _activeBucket = null;
    _activeStyleZoomQ = null;
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }

  // ---------------------------------------------------------------------------
  // DECODER DO TAG (opcional)
  // ---------------------------------------------------------------------------

  Map<String, dynamic>? decodeTag(dynamic tag) {
    if (tag is! String) return null;
    try {
      final obj = jsonDecode(tag);
      if (obj is Map<String, dynamic>) return obj;
      if (obj is Map) return obj.cast<String, dynamic>();
      return null;
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Internos: RAW
  // ---------------------------------------------------------------------------

  List<_RailRowSegments> _buildRawSegmentsFromRows(
      List<Map<String, dynamic>> rows,
      String ufNorm,
      ) {
    final out = <_RailRowSegments>[];

    for (final r in rows) {
      final docId = (r['_id'] ?? '').toString();

      final name = (r['name'] ?? '').toString().trim();
      final code = (r['code'] ?? '').toString().trim();
      final owner = (r['owner'] ?? '').toString().trim();

      final label = (code.isNotEmpty ? code : (name.isNotEmpty ? name : 'Ferrovia'));

      // ✅ Compat:
      // - novo import: "parts" (lista de trechos)
      // - legado: "points"
      final rawGeom = r['parts'] ?? r['points'];
      final normalized = _normalizePartsPayload(rawGeom);

      final segments = _repo.parseSegments(normalized);
      if (segments.isEmpty) continue;

      final cleanSegs = <List<LatLng>>[];
      var rawPointsTotal = 0;

      for (final seg in segments) {
        if (seg.length < 2) continue;
        rawPointsTotal += seg.length;
        cleanSegs.add(seg);
      }
      if (cleanSegs.isEmpty) continue;

      out.add(
        _RailRowSegments(
          docId: docId,
          uf: ufNorm,
          name: name,
          code: code,
          owner: owner,
          label: label,
          segments: cleanSegs,
          rawPointsTotal: rawPointsTotal,
        ),
      );
    }

    return out;
  }

  /// Converte parts=[{pts:[GeoPoint...]},...] -> List<List<GeoPoint>>
  dynamic _normalizePartsPayload(dynamic raw) {
    if (raw is List && raw.isNotEmpty && raw.first is Map) {
      final segs = <List<GeoPoint>>[];

      for (final item in raw) {
        if (item is! Map) continue;
        final ptsRaw = item['pts'];

        if (ptsRaw is List) {
          final pts = <GeoPoint>[];
          for (final p in ptsRaw) {
            if (p is GeoPoint) pts.add(p);
          }
          if (pts.length >= 2) segs.add(pts);
        }
      }

      return segs;
    }

    return raw;
  }

  void _invalidateDerivedCachesForUf(String ufNorm) {
    _centerlineCache.removeWhere((k, _) => k.startsWith('$ufNorm|'));
    _polyCache.removeWhere((k, _) => k.startsWith('$ufNorm|'));
  }

  // ---------------------------------------------------------------------------
  // Centerline (simplificado) por bucket
  // ---------------------------------------------------------------------------

  List<_RailCenterline> _buildCenterlinesForBucket({
    required String uf,
    required List<_RailRowSegments> rows,
    required int bucket,
  }) {
    final out = <_RailCenterline>[];

    // simplificação do eixo (mesmo padrão das rodovias)
    final stride = _strideForBucket(bucket);
    final tolMeters = _toleranceMetersForBucket(bucket);

    for (final rr in rows) {
      for (int segIndex = 0; segIndex < rr.segments.length; segIndex++) {
        var pts = rr.segments[segIndex];
        if (pts.length < 2) continue;

        if (stride > 1) {
          pts = _repo.decimate(pts, stride);
          if (pts.length < 2) continue;
        }

        pts = _repo.simplifyRdpMeters(pts, tolMeters);
        if (pts.length < 2) continue;

        final meta = <String, dynamic>{
          'type': 'railways',
          'docId': rr.docId,
          'segIndex': segIndex,
          'uf': rr.uf,
          'name': rr.name.isEmpty ? null : rr.name,
          'code': rr.code.isEmpty ? null : rr.code,
          'owner': rr.owner.isEmpty ? null : rr.owner,
          'label': rr.label,
        };

        out.add(
          _RailCenterline(
            points: pts,
            metaJson: jsonEncode(meta),
          ),
        );
      }
    }

    return out;
  }

  // ---------------------------------------------------------------------------
  // Final polylines (centerline + dormentes) por estilo (zoom)
  // ---------------------------------------------------------------------------

  List<TappableChangedPolyline> _buildFinalPolylinesForStyle({
    required List<_RailCenterline> centerlines,
    required double zoom,
  }) {
    final polylines = <TappableChangedPolyline>[];

    // Visual:
    // - eixo um pouco mais “pesado” para parecer trilho
    // - dormentes aparecem só a partir de um zoom mínimo
    final showTies = zoom >= 8.0;

    // padrão em pixels (o olho entende)
    final spacingPx = _tieSpacingPx(zoom);
    final tieLenPx = _tieLengthPx(zoom);

    // limites (fluidez)
    final maxTies = _maxTiesForZoom(zoom);

    for (final c in centerlines) {
      final pts = c.points;

      // eixo
      polylines.add(
        TappableChangedPolyline(
          points: pts,
          tag: c.metaJson, // ✅ tag completa no eixo (clicável)
          color: Colors.black,
          defaultColor: Colors.black,
          strokeWidth: _centerlineStrokeForZoom(zoom),
          hitTestable: true,
          isDotted: false,
        ),
      );

      if (!showTies || maxTies <= 0) continue;

      // px -> metros (WebMercator)
      final meanLat = pts.fold<double>(0.0, (a, p) => a + p.latitude) / pts.length;
      final mpp = _metersPerPixel(zoom: zoom, latDeg: meanLat);

      final spacingMeters = spacingPx * mpp;
      final halfLenMeters = (tieLenPx * 0.5) * mpp;

      final ties = _buildRailTies(
        pts: pts,
        spacingMeters: spacingMeters,
        halfLengthMeters: halfLenMeters,
        maxTies: maxTies,
      );

      for (final t in ties) {
        polylines.add(
          TappableChangedPolyline(
            points: t,
            tag: 'rail_tie',
            color: Colors.black,
            defaultColor: Colors.black,
            strokeWidth: _tieStrokeForZoom(zoom),
            hitTestable: false, // ✅ não interfere no tap
            isDotted: false,
          ),
        );
      }
    }

    return polylines;
  }

  void _applyStyleFromCache({
    required String ufNorm,
    required int bucket,
    required double styleZoomQ,
  }) {
    final styleKey = '$ufNorm|$bucket|$styleZoomQ';

    // Se já tem pronto, emite direto
    if (_polyCache.containsKey(styleKey)) {
      _activeBucket = bucket;
      _activeStyleZoomQ = styleZoomQ;
      emit(state.copyWith(isLoading: false, errorMessage: null, polylines: _polyCache[styleKey]!));
      return;
    }

    final centerKey = '$ufNorm|$bucket';
    final centerlines = _centerlineCache[centerKey];
    if (centerlines == null) return;

    final polylines = _buildFinalPolylinesForStyle(centerlines: centerlines, zoom: styleZoomQ);
    _polyCache[styleKey] = polylines;

    _activeBucket = bucket;
    _activeStyleZoomQ = styleZoomQ;

    emit(state.copyWith(isLoading: false, errorMessage: null, polylines: polylines));
  }

  // ---------------------------------------------------------------------------
  // Dormentes: construção (perpendicular) em METROS locais (aprox. equiretangular)
  // ---------------------------------------------------------------------------

  List<List<LatLng>> _buildRailTies({
    required List<LatLng> pts,
    required double spacingMeters,
    required double halfLengthMeters,
    required int maxTies,
  }) {
    if (pts.length < 2) return const [];
    if (spacingMeters <= 0) return const [];
    if (halfLengthMeters <= 0) return const [];

    final out = <List<LatLng>>[];

    final meanLat = pts.fold<double>(0.0, (a, p) => a + p.latitude) / pts.length;
    final cosLat = math.cos(meanLat * math.pi / 180.0);

    var nextAt = spacingMeters;
    var walked = 0.0;

    for (int i = 0; i < pts.length - 1; i++) {
      if (out.length >= maxTies) break;

      final a = pts[i];
      final b = pts[i + 1];

      final ax = _degToMetersX(a.longitude, cosLat);
      final ay = _degToMetersY(a.latitude);
      final bx = _degToMetersX(b.longitude, cosLat);
      final by = _degToMetersY(b.latitude);

      final dx = bx - ax;
      final dy = by - ay;

      final segLen = math.sqrt(dx * dx + dy * dy);
      if (segLen <= 0.0001) continue;

      while (walked + segLen >= nextAt) {
        if (out.length >= maxTies) break;

        final t = (nextAt - walked) / segLen;

        final cx = ax + dx * t;
        final cy = ay + dy * t;

        // direção unitária
        final ux = dx / segLen;
        final uy = dy / segLen;

        // perpendicular
        final px = -uy;
        final py = ux;

        final x1 = cx - px * halfLengthMeters;
        final y1 = cy - py * halfLengthMeters;
        final x2 = cx + px * halfLengthMeters;
        final y2 = cy + py * halfLengthMeters;

        final p1 = LatLng(_metersToDegLat(y1), _metersToDegLon(x1, cosLat));
        final p2 = LatLng(_metersToDegLat(y2), _metersToDegLon(x2, cosLat));

        out.add([p1, p2]);

        nextAt += spacingMeters;
      }

      walked += segLen;
    }

    return out;
  }

  // ---------------------------------------------------------------------------
  // Zoom/bucket (simplificação)
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
  // Estilo em PIXELS (dormentes) + limites (fluidez)
  // ---------------------------------------------------------------------------

  double _tieSpacingPx(double zoom) {
    final z = zoom.clamp(5.0, 14.0);
    final t = (z - 5.0) / (14.0 - 5.0);
    // 26px (zoom baixo) -> 14px (zoom alto)
    return (26.0 + (14.0 - 26.0) * t).clamp(12.0, 30.0);
  }

  double _tieLengthPx(double zoom) {
    final z = zoom.clamp(5.0, 14.0);
    final t = (z - 5.0) / (14.0 - 5.0);
    // 14px (zoom baixo) -> 10px (zoom alto)
    return (14.0 + (10.0 - 14.0) * t).clamp(8.0, 18.0);
  }

  int _maxTiesForZoom(double zoom) {
    if (zoom < 8.0) return 0;   // sem dormentes em visão muito ampla
    if (zoom < 10.0) return 160;
    if (zoom < 12.0) return 320;
    return 600;
  }

  double _centerlineStrokeForZoom(double zoom) {
    // eixo ligeiramente mais espesso em zoom maior
    if (zoom < 8) return 3.0;
    if (zoom < 10) return 3.5;
    if (zoom < 12) return 4.0;
    return 4.5;
  }

  double _tieStrokeForZoom(double zoom) {
    if (zoom < 10) return 2.0;
    if (zoom < 12) return 2.5;
    return 3.0;
  }

  // ---------------------------------------------------------------------------
  // WebMercator: metros por pixel (para converter px -> metros)
  // ---------------------------------------------------------------------------

  double _metersPerPixel({required double zoom, required double latDeg}) {
    final latRad = latDeg * math.pi / 180.0;
    return 156543.03392 * math.cos(latRad) / math.pow(2.0, zoom);
  }

  double _quantizeZoom(double zoom, {double step = 0.25}) {
    return (zoom / step).round() * step;
  }

  // ---------------------------------------------------------------------------
  // Conversões locais (aprox. equiretangular) para construir dormentes em metros
  // ---------------------------------------------------------------------------

  static const double _metersPerDegLat = 111320.0;

  double _degToMetersY(double latDeg) => latDeg * _metersPerDegLat;
  double _degToMetersX(double lonDeg, double cosLat) => lonDeg * _metersPerDegLat * cosLat;

  double _metersToDegLat(double metersY) => metersY / _metersPerDegLat;
  double _metersToDegLon(double metersX, double cosLat) =>
      cosLat == 0 ? 0 : metersX / (_metersPerDegLat * cosLat);

  // ---------------------------------------------------------------------------
  // LOG
  // ---------------------------------------------------------------------------

  void _perf(String msg) {
    if (kDebugMode) {
      print(msg);
    }
  }
}

// =============================================================================
// MODELOS INTERNOS
// =============================================================================

class _RailRowSegments {
  final String docId;
  final String uf;
  final String name;
  final String code;
  final String owner;
  final String label;
  final List<List<LatLng>> segments;

  /// Total de pontos raw (só p/ log)
  final int rawPointsTotal;

  const _RailRowSegments({
    required this.docId,
    required this.uf,
    required this.name,
    required this.code,
    required this.owner,
    required this.label,
    required this.segments,
    required this.rawPointsTotal,
  });
}

class _RailCenterline {
  final List<LatLng> points;

  /// JSON com meta do eixo (clicável)
  final String metaJson;

  const _RailCenterline({
    required this.points,
    required this.metaJson,
  });
}
