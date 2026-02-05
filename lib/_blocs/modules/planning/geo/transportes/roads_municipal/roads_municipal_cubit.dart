// lib/_blocs/modules/planning/geo/transportes/roads_municipal/roads_municipal_cubit.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';

import 'package:siged/_widgets/map/polylines/tappable_changed_polyline.dart';

import 'roads_municipal_repository.dart';
import 'roads_municipal_state.dart';

class RoadsMunicipalCubit extends Cubit<RoadsMunicipalState> {
  RoadsMunicipalCubit({required RoadsMunicipalRepository repository})
      : _repo = repository,
        super(const RoadsMunicipalState());

  final RoadsMunicipalRepository _repo;

  // Cache raw por UF (docs já com parts)
  final Map<String, List<_RoadRowSegments>> _rawCacheByUf = {};

  // Cache de polylines por UF + bucket
  final Map<String, List<TappableChangedPolyline>> _polyCache = {};

  // Controle de concorrência
  int _requestSeq = 0;

  // Debounce para mudança de bucket por zoom
  Timer? _debounce;
  static const Duration _debounceDuration = Duration(milliseconds: 180);

  int? _activeBucket;

  // Buckets (ajuste fino conforme seu padrão)
  static int bucketForZoom(double zoom) {
    if (zoom < 7.5) return 0;
    if (zoom < 9.0) return 1;
    if (zoom < 10.5) return 2;
    if (zoom < 12.0) return 3;
    return 4;
  }

  static double toleranceMetersForBucket(int bucket) {
    // municipal é denso => tolerâncias menores
    switch (bucket) {
      case 0:
        return 1200;
      case 1:
        return 700;
      case 2:
        return 350;
      case 3:
        return 160;
      case 4:
      default:
        return 60;
    }
  }

  // Estilo base
  static const double _strokeWidth = 2.0;
  static Color _colorForMunicipal() => Colors.blue.shade500;

  Future<void> loadByUF(
      String uf, {
        required int bucket,
        bool forceRefresh = false,
      }) async {
    final ufNorm = uf.trim().toUpperCase();
    final reqId = ++_requestSeq;

    try {
      emit(state.copyWith(isLoading: true, errorMessage: null));

      // 1) raw cache
      List<_RoadRowSegments> rows;

      if (!forceRefresh && _rawCacheByUf.containsKey(ufNorm)) {
        rows = _rawCacheByUf[ufNorm]!;
      } else {
        final rawDocs = await _repo.loadRawByUf(uf: ufNorm);
        rows = rawDocs
            .map(
              (d) => _RoadRowSegments(
            id: d.id,
            title: d.title,
            code: d.code,
            owner: d.owner,
            parts: d.parts,
            uf: ufNorm,
          ),
        )
            .toList(growable: false);

        _rawCacheByUf[ufNorm] = rows;
      }

      if (reqId != _requestSeq) return;

      // 2) poly cache por UF|bucket
      final cacheKey = '$ufNorm|$bucket';
      if (_polyCache.containsKey(cacheKey)) {
        _activeBucket = bucket;
        emit(state.copyWith(isLoading: false, polylines: _polyCache[cacheKey]!));
        return;
      }

      final tol = toleranceMetersForBucket(bucket);
      final polylines = _buildPolylinesForBucket(
        uf: ufNorm,
        rows: rows,
        toleranceMeters: tol,
        bucket: bucket,
      );

      if (reqId != _requestSeq) return;

      _polyCache[cacheKey] = polylines;
      _activeBucket = bucket;

      emit(state.copyWith(isLoading: false, polylines: polylines));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  void onZoomChanged({required String uf, required double zoom}) {
    final ufNorm = uf.trim().toUpperCase();
    final bucket = bucketForZoom(zoom);

    if (_activeBucket == bucket) return;

    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, () {
      if (!_rawCacheByUf.containsKey(ufNorm)) {
        loadByUF(ufNorm, bucket: bucket);
        return;
      }

      _applyBucketFromCache(ufNorm, bucket);
    });
  }

  void clearCache({String? uf}) {
    if (uf == null) {
      _rawCacheByUf.clear();
      _polyCache.clear();
    } else {
      final ufNorm = uf.trim().toUpperCase();
      _rawCacheByUf.remove(ufNorm);
      _polyCache.removeWhere((k, _) => k.startsWith('$ufNorm|'));
    }
    _activeBucket = null;
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }

  // ---------------------------------------------------------------------------
  // Internos
  // ---------------------------------------------------------------------------

  List<TappableChangedPolyline> _buildPolylinesForBucket({
    required String uf,
    required List<_RoadRowSegments> rows,
    required double toleranceMeters,
    required int bucket,
  }) {
    final polylines = <TappableChangedPolyline>[];
    final baseColor = _colorForMunicipal();

    for (final r in rows) {
      final simplifiedParts =
      _repo.simplifyParts(parts: r.parts, toleranceMeters: toleranceMeters);

      // 1 polyline por segmento (seguro para multi-line)
      for (int i = 0; i < simplifiedParts.length; i++) {
        final List<LatLng> seg = simplifiedParts[i];
        if (seg.length < 2) continue;

        // ✅ PADRÃO IGUAL FEDERAL: tag sempre JSON String
        final meta = <String, dynamic>{
          'type': 'municipal_road',
          'docId': r.id,
          'segIndex': i,
          'uf': uf,
          'name': r.title.isEmpty ? null : r.title,
          'code': r.code.isEmpty ? null : r.code,
          'owner': r.owner.isEmpty ? null : r.owner,
          'label': r.code.isNotEmpty ? r.code : (r.title.isNotEmpty ? r.title : 'Rodovia Municipal'),
          'bucket': bucket,
        };

        polylines.add(
          TappableChangedPolyline(
            points: seg,
            tag: jsonEncode(meta),
            color: baseColor,
            defaultColor: baseColor,
            strokeWidth: _strokeWidth,
            isDotted: false,
            hitTestable: true,
          ),
        );
      }
    }
    return polylines;
  }

  void _applyBucketFromCache(String ufNorm, int bucket) {
    final cacheKey = '$ufNorm|$bucket';
    if (_polyCache.containsKey(cacheKey)) {
      _activeBucket = bucket;
      emit(state.copyWith(
        isLoading: false,
        errorMessage: null,
        polylines: _polyCache[cacheKey]!,
      ));
      return;
    }

    final rows = _rawCacheByUf[ufNorm];
    if (rows == null) return;

    final tol = toleranceMetersForBucket(bucket);
    final polylines = _buildPolylinesForBucket(
      uf: ufNorm,
      rows: rows,
      toleranceMeters: tol,
      bucket: bucket,
    );

    _polyCache[cacheKey] = polylines;
    _activeBucket = bucket;

    emit(state.copyWith(isLoading: false, errorMessage: null, polylines: polylines));
  }
}

class _RoadRowSegments {
  final String id;
  final String title;
  final String code;
  final String owner;
  final List<List<LatLng>> parts;
  final String uf;

  const _RoadRowSegments({
    required this.id,
    required this.title,
    required this.code,
    required this.owner,
    required this.parts,
    required this.uf,
  });
}
