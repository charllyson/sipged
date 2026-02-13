// lib/_blocs/modules/planning/geo/transportes/roads_federal/roads_federal_cubit.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';

import 'package:sipged/_widgets/map/polylines/tappable_changed_polyline.dart';

import 'roads_federal_repository.dart';
import 'roads_federal_state.dart';

class RoadsFederalCubit extends Cubit<RoadsFederalState> {
  RoadsFederalCubit({required RoadsFederalRepository repository})
      : _repo = repository,
        super(const RoadsFederalState());

  final RoadsFederalRepository _repo;

  // ---------------------------------------------------------------------------
  // Cache por UF: mantém geometria "raw" em segmentos para re-simplificar rápido.
  // key: UF
  // value: lista de "rows" já com segmentos extraídos
  // ---------------------------------------------------------------------------
  final Map<String, List<_RoadRowSegments>> _rawCacheByUf = {};

  // Cache de polylines por UF + bucket (evita recomputar em troca de zoom)
  // key: "$UF|$bucket"
  final Map<String, List<TappableChangedPolyline>> _polyCache = {};

  // Controle de concorrência
  int _requestSeq = 0;

  // Debounce para mudança de bucket por zoom (evita flood em pan/zoom)
  Timer? _debounce;
  static const Duration _debounceDuration = Duration(milliseconds: 180);

  // Bucket atual “aplicado” (para evitar re-emit desnecessário)
  int? _activeBucket;

  // ---------------------------------------------------------------------------
  // API PÚBLICA
  // ---------------------------------------------------------------------------

  /// Carrega as rodovias da UF (raw + simplificação inicial).
  /// Você pode passar um bucket inicial (ex: baseado no zoom atual).
  Future<void> loadByUF(
      String uf, {
        int bucket = 3,
        bool forceRefresh = false,
      }) async {
    final ufNorm = uf.trim().toUpperCase();
    final reqId = ++_requestSeq;

    try {
      emit(state.copyWith(isLoading: true, errorMessage: null));

      final sw = Stopwatch()..start();
      _perf('[PERF] RoadsFederal.loadByUF(uf=$ufNorm,bucket=$bucket) :: start = 0ms');

      // 1) Fetch + parse segmentos (somente se não tiver cache ou forceRefresh)
      List<_RoadRowSegments> rowsSegs;

      if (!forceRefresh && _rawCacheByUf.containsKey(ufNorm)) {
        rowsSegs = _rawCacheByUf[ufNorm]!;
      } else {
        final tFetch = Stopwatch()..start();
        final rows = await _repo.fetchByUF(ufNorm);
        tFetch.stop();
        _perf(
          '[PERF] RoadsFederal.loadByUF(uf=$ufNorm,bucket=$bucket) :: fetch rows=${rows.length} = ${tFetch.elapsedMilliseconds}ms',
        );

        final tParse = Stopwatch()..start();
        rowsSegs = _buildRawSegmentsFromRows(rows, ufNorm);
        tParse.stop();

        // Conta pontos raw (apenas para log)
        final rawPointsTotal = rowsSegs.fold<int>(
          0,
              (acc, e) => acc + e.rawPointsTotal,
        );

        _perf(
          '[PERF] RoadsFederal.loadByUF(uf=$ufNorm,bucket=$bucket) :: parse geoms=${rowsSegs.length} rawPointsTotal=$rawPointsTotal = ${tParse.elapsedMilliseconds}ms',
        );

        _rawCacheByUf[ufNorm] = rowsSegs;
      }

      // Cancelamento lógico (se veio outra request no meio)
      if (reqId != _requestSeq) return;

      // 2) Build polylines para o bucket solicitado (usa cache por UF|bucket)
      final cacheKey = '$ufNorm|$bucket';
      List<TappableChangedPolyline> polylines;

      if (_polyCache.containsKey(cacheKey)) {
        polylines = _polyCache[cacheKey]!;
      } else {
        final tolMeters = _toleranceMetersForBucket(bucket);

        final tSimpl = Stopwatch()..start();
        polylines = _buildPolylinesForBucket(
          uf: ufNorm,
          rows: rowsSegs,
          toleranceMeters: tolMeters,
          bucket: bucket,
        );
        tSimpl.stop();

        final simpPointsTotal = polylines.fold<int>(
          0,
              (acc, p) => acc + p.points.length,
        );

        _perf(
          '[PERF] RoadsFederal.loadByUF(uf=$ufNorm,bucket=$bucket) :: simplify tol=${tolMeters.toStringAsFixed(0)}m simpPointsTotal=$simpPointsTotal = ${sw.elapsedMilliseconds}ms',
        );

        // Cache
        _polyCache[cacheKey] = polylines;
      }

      // Cancelamento lógico
      if (reqId != _requestSeq) return;

      // 3) Emit final
      final tBuild = Stopwatch()..start();
      _activeBucket = bucket;
      emit(state.copyWith(isLoading: false, polylines: polylines));
      tBuild.stop();

      _perf(
        '[PERF] RoadsFederal.loadByUF(uf=$ufNorm,bucket=$bucket) :: build polylines=${polylines.length} = ${sw.elapsedMilliseconds}ms',
      );
      _perf(
        '[PERF] RoadsFederal.loadByUF(uf=$ufNorm,bucket=$bucket) :: END = ${sw.elapsedMilliseconds}ms',
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  /// Chame isso no PlanningMap.onCameraChanged (ou MapController listener).
  /// Ex.: cubit.onZoomChanged(uf: _currentUF, zoom: zoom);
  void onZoomChanged({
    required String uf,
    required double zoom,
  }) {
    final ufNorm = uf.trim().toUpperCase();
    final bucket = bucketForZoom(zoom);

    // Se bucket não mudou, não faz nada.
    if (_activeBucket == bucket) return;

    // Debounce: evita recomputar durante zoom/pan contínuo.
    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, () {
      // Se ainda não tem cache raw, tenta carregar (lazy).
      if (!_rawCacheByUf.containsKey(ufNorm)) {
        loadByUF(ufNorm, bucket: bucket);
        return;
      }

      // Se tem raw, só re-simplifica/pega cache por bucket.
      _applyBucketFromCache(ufNorm, bucket);
    });
  }

  /// Para limpar caches quando necessário (ex.: logout, troca de dataset, etc.)
  void clearCache() {
    _rawCacheByUf.clear();
    _polyCache.clear();
    _activeBucket = null;
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
  // HELPERS INTERNOS
  // ---------------------------------------------------------------------------

  List<_RoadRowSegments> _buildRawSegmentsFromRows(
      List<Map<String, dynamic>> rows,
      String ufNorm,
      ) {
    final out = <_RoadRowSegments>[];

    for (final r in rows) {
      final docId = (r['_id'] ?? '').toString();

      final name = (r['name'] ?? '').toString().trim();
      final code = (r['code'] ?? '').toString().trim();
      final owner = (r['owner'] ?? '').toString().trim();

      // Label simples (String) para o MapInteractive
      final label = (code.isNotEmpty ? code : (name.isNotEmpty ? name : 'Rodovia Federal'));

      // Segmentar corretamente (evita "pontes" entre trechos desconectados)
      final segments = _repo.parseSegments(r['points']);
      if (segments.isEmpty) continue;

      // Filtra segmentos muito pequenos
      final cleanSegs = <List<LatLng>>[];
      var rawPointsTotal = 0;

      for (final seg in segments) {
        if (seg.length < 2) continue;
        rawPointsTotal += seg.length;
        cleanSegs.add(seg);
      }
      if (cleanSegs.isEmpty) continue;

      out.add(
        _RoadRowSegments(
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

  List<TappableChangedPolyline> _buildPolylinesForBucket({
    required String uf,
    required List<_RoadRowSegments> rows,
    required double toleranceMeters,
    required int bucket,
  }) {
    final polylines = <TappableChangedPolyline>[];

    // Estratégia “big tech”:
    // - Mantém segmentos separados
    // - Simplifica por zoom/bucket
    // - (Opcional) stride/decimation antes do RDP para reduzir custo
    // - Mantém metadados por segmento, evitando qualquer cast interno quebrar

    // Ajuste de custo: stride sugerido por bucket (p/ reduzir custo do RDP)
    final stride = _strideForBucket(bucket);

    for (final rr in rows) {
      for (int segIndex = 0; segIndex < rr.segments.length; segIndex++) {
        var pts = rr.segments[segIndex];
        if (pts.length < 2) continue;

        // 1) Decimation (barato)
        if (stride > 1) {
          pts = _repo.decimate(pts, stride);
          if (pts.length < 2) continue;
        }

        // 2) RDP em metros (mais caro)
        pts = _repo.simplifyRdpMeters(pts, toleranceMeters);
        if (pts.length < 2) continue;

        final meta = <String, dynamic>{
          'type': 'federal_road',
          'docId': rr.docId,
          'segIndex': segIndex,
          'uf': rr.uf,
          'name': rr.name.isEmpty ? null : rr.name,
          'code': rr.code.isEmpty ? null : rr.code,
          'owner': rr.owner.isEmpty ? null : rr.owner,
          'label': rr.label,
        };

        polylines.add(
          TappableChangedPolyline(
            points: pts,
            tag: jsonEncode(meta), // ✅ sempre String (JSON)
            color: Colors.redAccent,
            defaultColor: Colors.redAccent,
            strokeWidth: 3.0,
            hitTestable: true,
            isDotted: false,
          ),
        );
      }
    }

    return polylines;
  }

  void _applyBucketFromCache(String ufNorm, int bucket) {
    // Se já temos polylines em cache, só emite.
    final cacheKey = '$ufNorm|$bucket';
    if (_polyCache.containsKey(cacheKey)) {
      _activeBucket = bucket;
      emit(state.copyWith(isLoading: false, errorMessage: null, polylines: _polyCache[cacheKey]!));
      return;
    }

    // Caso contrário, reconstroi a partir do raw cache.
    final rowsSegs = _rawCacheByUf[ufNorm];
    if (rowsSegs == null) return;

    final tol = _toleranceMetersForBucket(bucket);

    final sw = Stopwatch()..start();
    _perf('[PERF] RoadsFederal.applyBucket(uf=$ufNorm,bucket=$bucket) :: start = 0ms');

    final polylines = _buildPolylinesForBucket(
      uf: ufNorm,
      rows: rowsSegs,
      toleranceMeters: tol,
      bucket: bucket,
    );

    _polyCache[cacheKey] = polylines;
    _activeBucket = bucket;

    emit(state.copyWith(isLoading: false, errorMessage: null, polylines: polylines));

    sw.stop();
    final simpPointsTotal = polylines.fold<int>(0, (acc, p) => acc + p.points.length);
    _perf(
      '[PERF] RoadsFederal.applyBucket(uf=$ufNorm,bucket=$bucket) :: END = ${sw.elapsedMilliseconds}ms simpPointsTotal=$simpPointsTotal tol=${tol.toStringAsFixed(0)}m',
    );
  }

  // ---------------------------------------------------------------------------
  // BUCKET / TOLERÂNCIA (AJUSTE FINO)
  // ---------------------------------------------------------------------------

  /// Converte zoom em bucket (1..5). Ajuste conforme seu mapa.
  static int bucketForZoom(double zoom) {
    if (zoom < 6.2) return 1;
    if (zoom < 7.5) return 2;
    if (zoom < 9.2) return 3;
    if (zoom < 11.2) return 4;
    return 5;
  }

  /// Tolerância em metros por bucket (evita deformar em zoom alto).
  double _toleranceMetersForBucket(int bucket) {
    switch (bucket) {
      case 1:
        return 1800; // visão bem geral
      case 2:
        return 900;
      case 3:
        return 300;
      case 4:
        return 80;
      case 5:
      default:
        return 20; // detalhe urbano
    }
  }

  /// Stride/decimation por bucket: reduz custo do RDP drasticamente.
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
        return 1; // sem stride em zoom alto
    }
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

// =============================================================================
// MODELO INTERNO: row + segmentos raw
// =============================================================================

class _RoadRowSegments {
  final String docId;
  final String uf;
  final String name;
  final String code;
  final String owner;
  final String label;
  final List<List<LatLng>> segments;

  /// Total de pontos raw (só p/ log)
  final int rawPointsTotal;

  const _RoadRowSegments({
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
