import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';

import 'package:siged/_widgets/map/polylines/tappable_changed_polyline.dart';

import 'roads_state_repository.dart';
import 'roads_state_state.dart';

class RoadsStateCubit extends Cubit<RoadsStateState> {
  RoadsStateCubit({required RoadsStateRepository repository})
      : _repo = repository,
        super(const RoadsStateState());

  final RoadsStateRepository _repo;

  final Map<String, List<_RoadRowSegments>> _rawCacheByUf = {};
  final Map<String, List<TappableChangedPolyline>> _polyCache = {};

  int _requestSeq = 0;

  Timer? _debounce;
  static const Duration _debounceDuration = Duration(milliseconds: 180);

  int? _activeBucket;

  Future<void> loadByUF(
      String uf, {
        int bucket = 3,
        bool forceRefresh = false,
      }) async {
    final ufNorm = uf.trim().toUpperCase();
    final reqId = ++_requestSeq;

    try {
      emit(state.copyWith(isLoading: true, errorMessage: null));

      List<_RoadRowSegments> rowsSegs;

      if (!forceRefresh && _rawCacheByUf.containsKey(ufNorm)) {
        rowsSegs = _rawCacheByUf[ufNorm]!;
      } else {
        final rows = await _repo.fetchByUF(ufNorm);
        rowsSegs = _buildRawSegmentsFromRows(rows, ufNorm);
        _rawCacheByUf[ufNorm] = rowsSegs;
      }

      if (reqId != _requestSeq) return;

      final cacheKey = '$ufNorm|$bucket';
      List<TappableChangedPolyline> polylines;

      if (_polyCache.containsKey(cacheKey)) {
        polylines = _polyCache[cacheKey]!;
      } else {
        final tolMeters = _toleranceMetersForBucket(bucket);
        polylines = _buildPolylinesForBucket(
          uf: ufNorm,
          rows: rowsSegs,
          toleranceMeters: tolMeters,
          bucket: bucket,
        );
        _polyCache[cacheKey] = polylines;
      }

      if (reqId != _requestSeq) return;

      _activeBucket = bucket;
      emit(state.copyWith(isLoading: false, polylines: polylines));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  void onZoomChanged({
    required String uf,
    required double zoom,
  }) {
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

      final label = (code.isNotEmpty
          ? code
          : (name.isNotEmpty ? name : 'Rodovia Estadual'));

      final segments = _repo.parseSegments(r['points']);
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
    final stride = _strideForBucket(bucket);

    for (final rr in rows) {
      for (int segIndex = 0; segIndex < rr.segments.length; segIndex++) {
        var pts = rr.segments[segIndex];
        if (pts.length < 2) continue;

        if (stride > 1) {
          pts = _repo.decimate(pts, stride);
          if (pts.length < 2) continue;
        }

        pts = _repo.simplifyRdpMeters(pts, toleranceMeters);
        if (pts.length < 2) continue;

        final meta = <String, dynamic>{
          'type': 'state_road',
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
            tag: jsonEncode(meta),
            color: Colors.green, // diferencia da federal
            defaultColor: Colors.green.shade600,
            strokeWidth: 2.5,
            hitTestable: true,
            isDotted: false,
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

    final rowsSegs = _rawCacheByUf[ufNorm];
    if (rowsSegs == null) return;

    final tol = _toleranceMetersForBucket(bucket);
    final polylines = _buildPolylinesForBucket(
      uf: ufNorm,
      rows: rowsSegs,
      toleranceMeters: tol,
      bucket: bucket,
    );

    _polyCache[cacheKey] = polylines;
    _activeBucket = bucket;

    emit(state.copyWith(isLoading: false, errorMessage: null, polylines: polylines));
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

  void _perf(String msg) {
    if (kDebugMode) {
      // ignore: avoid_print
      print(msg);
    }
  }
}

class _RoadRowSegments {
  final String docId;
  final String uf;
  final String name;
  final String code;
  final String owner;
  final String label;
  final List<List<LatLng>> segments;
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
