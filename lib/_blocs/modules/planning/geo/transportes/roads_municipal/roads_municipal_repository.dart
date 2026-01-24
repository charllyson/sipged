// lib/_blocs/modules/planning/geo/transportes/roads_municipal/roads_municipal_repository.dart
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

class RoadsMunicipalRepository {
  RoadsMunicipalRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  // ✅ PADRÃO IGUAL FEDERAL/ESTADUAL
  CollectionReference<Map<String, dynamic>> _col() {
    return _db
        .collection('geo')
        .doc('transportes')
        .collection('rodovias_municipais');
  }

  /// ✅ Usado para pintar a correntinha (verde quando existir dado).
  Future<bool> hasData({required String uf}) async {
    final ufNorm = uf.trim().toUpperCase();

    final snap = await _col().where('uf', isEqualTo: ufNorm).limit(1).get();
    if (snap.docs.isNotEmpty) return true;

    // fallback: se existir qualquer dado na coleção (mesmo sem UF)
    final any = await _col().limit(1).get();
    return any.docs.isNotEmpty;
  }

  // ===========================================================================
  // LOAD RAW
  // ===========================================================================
  Future<List<RoadsMunicipalDoc>> loadRawByUf({
    required String uf,
    int limit = 5000,
  }) async {
    final ufNorm = uf.trim().toUpperCase();

    Query<Map<String, dynamic>> q = _col().where('uf', isEqualTo: ufNorm);

    QuerySnapshot<Map<String, dynamic>> snap;
    try {
      snap = await q.orderBy('createdAt', descending: true).limit(limit).get();
    } catch (_) {
      snap = await q.limit(limit).get();
    }

    final docs = <RoadsMunicipalDoc>[];

    for (final d in snap.docs) {
      final data = d.data();

      final String title =
      (data['name'] ?? data['code'] ?? d.id).toString().trim();

      final String code = (data['code'] ?? '').toString().trim();
      final String owner = (data['owner'] ?? '').toString().trim();

      // ✅ parts: List<Map>{ pts: List<GeoPoint> } (formato seguro)
      final parts = <List<LatLng>>[];
      final rawParts = data['parts'];

      if (rawParts is List) {
        for (final item in rawParts) {
          // { pts: [...] }
          if (item is Map) {
            final ptsRaw = item['pts'];
            final seg = _geoPointsToLatLng(ptsRaw);
            if (seg.length >= 2) parts.add(seg);
            continue;
          }

          // fallback: lista direta (caso legado)
          if (item is List) {
            final seg = _geoPointsToLatLng(item);
            if (seg.length >= 2) parts.add(seg);
          }
        }
      }

      // ✅ points flatten (fallback se parts vier vazio)
      final flat = _geoPointsToLatLng(data['points']);
      if (parts.isEmpty && flat.length >= 2) {
        parts.add(flat);
      }

      if (parts.isEmpty) continue;

      docs.add(
        RoadsMunicipalDoc(
          id: d.id,
          title: title.isEmpty ? d.id : title,
          code: code,
          owner: owner,
          parts: parts,
          uf: ufNorm,
        ),
      );
    }

    // Se não achou nada por UF, tenta fallback “qualquer dado” (opcional, igual federal)
    if (docs.isNotEmpty) return docs;

    final all = await _col().limit(limit).get();
    for (final d in all.docs) {
      final data = d.data();

      final String title =
      (data['name'] ?? data['code'] ?? d.id).toString().trim();

      final String code = (data['code'] ?? '').toString().trim();
      final String owner = (data['owner'] ?? '').toString().trim();

      final parts = <List<LatLng>>[];
      final rawParts = data['parts'];

      if (rawParts is List) {
        for (final item in rawParts) {
          if (item is Map) {
            final seg = _geoPointsToLatLng(item['pts']);
            if (seg.length >= 2) parts.add(seg);
            continue;
          }
          if (item is List) {
            final seg = _geoPointsToLatLng(item);
            if (seg.length >= 2) parts.add(seg);
          }
        }
      }

      final flat = _geoPointsToLatLng(data['points']);
      if (parts.isEmpty && flat.length >= 2) parts.add(flat);

      if (parts.isEmpty) continue;

      docs.add(
        RoadsMunicipalDoc(
          id: d.id,
          title: title.isEmpty ? d.id : title,
          code: code,
          owner: owner,
          parts: parts,
          uf: (data['uf'] ?? '').toString().trim().toUpperCase(),
        ),
      );
    }

    return docs;
  }

  // ===========================================================================
  // SIMPLIFY (por segmento)
  // ===========================================================================
  List<List<LatLng>> simplifyParts({
    required List<List<LatLng>> parts,
    required double toleranceMeters,
  }) {
    if (toleranceMeters <= 0) return parts;

    return parts
        .map((seg) => _rdp(seg, toleranceMeters))
        .where((seg) => seg.length >= 2)
        .toList(growable: false);
  }

  // ===========================================================================
  // Helpers
  // ===========================================================================
  List<LatLng> _geoPointsToLatLng(dynamic raw) {
    final out = <LatLng>[];
    if (raw is! List) return out;

    for (final p in raw) {
      if (p is GeoPoint) {
        out.add(LatLng(p.latitude, p.longitude));
      }
    }
    return out;
  }

  // ---------------- RDP (Douglas-Peucker) ----------------
  List<LatLng> _rdp(List<LatLng> pts, double epsMeters) {
    if (pts.length <= 2) return pts;

    final keep = List<bool>.filled(pts.length, false);
    keep[0] = true;
    keep[pts.length - 1] = true;

    void recurse(int a, int b) {
      if (b <= a + 1) return;

      double maxDist = -1;
      int idx = -1;

      for (int i = a + 1; i < b; i++) {
        final d = _perpDistanceMeters(pts[i], pts[a], pts[b]);
        if (d > maxDist) {
          maxDist = d;
          idx = i;
        }
      }

      if (maxDist > epsMeters && idx != -1) {
        keep[idx] = true;
        recurse(a, idx);
        recurse(idx, b);
      }
    }

    recurse(0, pts.length - 1);

    final out = <LatLng>[];
    for (int i = 0; i < pts.length; i++) {
      if (keep[i]) out.add(pts[i]);
    }
    return out.length >= 2 ? out : pts;
  }

  double _perpDistanceMeters(LatLng p, LatLng a, LatLng b) {
    // projeção simples equiretangular
    final ax = a.longitude;
    final ay = a.latitude;
    final bx = b.longitude;
    final by = b.latitude;
    final px = p.longitude;
    final py = p.latitude;

    final dx = bx - ax;
    final dy = by - ay;

    if (dx == 0 && dy == 0) {
      return _haversineMeters(p, a);
    }

    final t = ((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy);
    final tt = t.clamp(0.0, 1.0);

    final proj = LatLng(ay + dy * tt, ax + dx * tt);
    return _haversineMeters(p, proj);
  }

  double _haversineMeters(LatLng p1, LatLng p2) {
    const r = 6371000.0;
    final dLat = _deg2rad(p2.latitude - p1.latitude);
    final dLon = _deg2rad(p2.longitude - p1.longitude);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(p1.latitude)) *
            math.cos(_deg2rad(p2.latitude)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  double _deg2rad(double d) => d * math.pi / 180.0;
}

class RoadsMunicipalDoc {
  final String id;
  final String title;
  final String code;
  final String owner;
  final List<List<LatLng>> parts;
  final String uf;

  const RoadsMunicipalDoc({
    required this.id,
    required this.title,
    required this.code,
    required this.owner,
    required this.parts,
    required this.uf,
  });
}
