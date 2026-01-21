import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

class RoadsFederalRepository {
  RoadsFederalRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col() {
    return _db
        .collection('geo')
        .doc('transportes')
        .collection('rodovias_federais');
  }

  /// ✅ Usado para pintar a correntinha (verde quando existir dado).
  Future<bool> hasData({required String uf}) async {
    final ufNorm = uf.trim().toUpperCase();

    final snap = await _col()
        .where('uf', isEqualTo: ufNorm)
        .limit(1)
        .get();

    if (snap.docs.isNotEmpty) return true;

    // fallback opcional: se existir qualquer dado na coleção
    final any = await _col().limit(1).get();
    return any.docs.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> fetchByUF(String uf) async {
    final ufNorm = uf.trim().toUpperCase();

    final snap = await _col().where('uf', isEqualTo: ufNorm).get();

    if (snap.docs.isNotEmpty) {
      return snap.docs.map((d) {
        final data = d.data();
        data['_id'] = d.id;
        return data;
      }).toList();
    }

    final all = await _col().get();
    return all.docs.map((d) {
      final data = d.data();
      data['_id'] = d.id;
      return data;
    }).toList();
  }

  // ===========================================================================
  // PARSER (EM SEGMENTOS)
  // ===========================================================================

  List<List<LatLng>> parseSegments(dynamic raw) {
    if (raw == null) return const <List<LatLng>>[];

    // Caso 1: GeoJSON style {type, coordinates}
    if (raw is Map) {
      final type = (raw['type'] ?? '').toString();
      final coords = raw['coordinates'];

      if (coords is! List) return const <List<LatLng>>[];

      if (type == 'LineString') {
        final seg = _parseGeoJsonLineString(coords);
        return seg.length >= 2 ? <List<LatLng>>[seg] : const <List<LatLng>>[];
      }

      if (type == 'MultiLineString') {
        final segs = <List<LatLng>>[];
        for (final line in coords) {
          if (line is! List) continue;
          final seg = _parseGeoJsonLineString(line);
          if (seg.length >= 2) segs.add(seg);
        }
        return segs;
      }

      // fallback
      final seg = _parseGeoJsonLineString(coords);
      return seg.length >= 2 ? <List<LatLng>>[seg] : const <List<LatLng>>[];
    }

    // Caso 2: List
    if (raw is List) return _parseListAsSegments(raw);

    return const <List<LatLng>>[];
  }

  List<List<LatLng>> _parseListAsSegments(List list) {
    if (list.isEmpty) return const <List<LatLng>>[];
    final first = list.first;

    if (first is GeoPoint) {
      final seg = <LatLng>[];
      for (final e in list) {
        if (e is! GeoPoint) continue;
        seg.add(LatLng(e.latitude, e.longitude));
      }
      return seg.length >= 2 ? <List<LatLng>>[seg] : const <List<LatLng>>[];
    }

    if (first is List && first.isNotEmpty && first.first is GeoPoint) {
      final segs = <List<LatLng>>[];
      for (final line in list) {
        if (line is! List) continue;
        final seg = <LatLng>[];
        for (final e in line) {
          if (e is! GeoPoint) continue;
          seg.add(LatLng(e.latitude, e.longitude));
        }
        if (seg.length >= 2) segs.add(seg);
      }
      return segs;
    }

    if (first is Map) {
      final seg = <LatLng>[];
      for (final e in list) {
        if (e is! Map) continue;
        final lat = _asDouble(e['lat'] ?? e['latitude']);
        final lng = _asDouble(e['lng'] ?? e['lon'] ?? e['longitude']);
        if (lat == null || lng == null) continue;
        seg.add(LatLng(lat, lng));
      }
      return seg.length >= 2 ? <List<LatLng>>[seg] : const <List<LatLng>>[];
    }

    if (first is List) {
      if (first.isNotEmpty && first.first is List) {
        final segs = <List<LatLng>>[];
        for (final line in list) {
          if (line is! List) continue;
          final seg = _parseGeoJsonLineString(line);
          if (seg.length >= 2) segs.add(seg);
        }
        return segs;
      }

      final seg = _parseGeoJsonLineString(list);
      return seg.length >= 2 ? <List<LatLng>>[seg] : const <List<LatLng>>[];
    }

    return const <List<LatLng>>[];
  }

  List<LatLng> _parseGeoJsonLineString(List coords) {
    final pts = <LatLng>[];
    for (final c in coords) {
      if (c is! List || c.length < 2) continue;
      final lng = _asDouble(c[0]);
      final lat = _asDouble(c[1]);
      if (lat == null || lng == null) continue;
      pts.add(LatLng(lat, lng));
    }
    return pts;
  }

  double? _asDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    final s = v.toString().trim().replaceAll(',', '.');
    return double.tryParse(s);
  }

  // ===========================================================================
  // SIMPLIFICAÇÃO (por segmento)
  // ===========================================================================

  List<LatLng> decimate(List<LatLng> pts, int step) {
    if (pts.length <= 2) return pts;
    if (step <= 1) return pts;

    final out = <LatLng>[pts.first];
    for (int i = step; i < pts.length - 1; i += step) {
      out.add(pts[i]);
    }
    out.add(pts.last);
    return out;
  }

  List<LatLng> simplifyRdpMeters(List<LatLng> pts, double toleranceMeters) {
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

    final ax = _degToMetersX(a.longitude, cosLat);
    final ay = _degToMetersY(a.latitude);
    final bx = _degToMetersX(b.longitude, cosLat);
    final by = _degToMetersY(b.latitude);
    final px = _degToMetersX(p.longitude, cosLat);
    final py = _degToMetersY(p.latitude);

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

  static const double _metersPerDegLat = 111320.0;
  double _degToMetersY(double latDeg) => latDeg * _metersPerDegLat;
  double _degToMetersX(double lonDeg, double cosLat) =>
      lonDeg * _metersPerDegLat * cosLat;
}

class _IdxPair {
  final int a;
  final int b;
  const _IdxPair(this.a, this.b);
}
