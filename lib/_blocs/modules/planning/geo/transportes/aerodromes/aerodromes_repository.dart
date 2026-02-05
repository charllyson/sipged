import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

class AerodromesRepository {
  AerodromesRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col() {
    // ✅ EXIGÊNCIA: dentro de transportes no banco
    return _db.collection('geo').doc('transportes').collection('aerodromos');
  }

  /// ✅ Para pintar a correntinha (tem dados ou não).
  Future<bool> hasData({required String uf}) async {
    final ufNorm = uf.trim().toUpperCase();

    final snap = await _col().where('uf', isEqualTo: ufNorm).limit(1).get();
    if (snap.docs.isNotEmpty) return true;

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

  bool isValidLatLng(double lat, double lng) =>
      lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;

  LatLng? parsePoint(dynamic raw) {
    if (raw == null) return null;

    if (raw is GeoPoint) {
      final lat = raw.latitude;
      final lng = raw.longitude;
      if (!isValidLatLng(lat, lng)) return null;
      return LatLng(lat, lng);
    }

    if (raw is Map) {
      final lat = _asDouble(raw['lat'] ?? raw['latitude']);
      final lng = _asDouble(raw['lng'] ?? raw['lon'] ?? raw['longitude']);
      if (lat != null && lng != null && isValidLatLng(lat, lng)) {
        return LatLng(lat, lng);
      }

      final type = (raw['type'] ?? '').toString().trim().toLowerCase();
      final coords = raw['coordinates'];
      if (type == 'point' && coords is List && coords.length >= 2) {
        final lng2 = _asDouble(coords[0]);
        final lat2 = _asDouble(coords[1]);
        if (lat2 != null && lng2 != null && isValidLatLng(lat2, lng2)) {
          return LatLng(lat2, lng2);
        }
      }
    }

    if (raw is List && raw.length >= 2) {
      final lng = _asDouble(raw[0]);
      final lat = _asDouble(raw[1]);
      if (lat != null && lng != null && isValidLatLng(lat, lng)) {
        return LatLng(lat, lng);
      }
    }

    return null;
  }

  LatLng? parsePointFromRow(Map<String, dynamic> row) {
    final lat = _asDouble(
      row['latitude'] ??
          row['lat'] ??
          row['LAT'] ??
          row['LATITUDE'] ??
          row['coordN'] ??
          row['NumCoordN'],
    );

    final lng = _asDouble(
      row['longitude'] ??
          row['lng'] ??
          row['lon'] ??
          row['LON'] ??
          row['LONGITUDE'] ??
          row['coordE'] ??
          row['NumCoordE'],
    );

    if (lat == null || lng == null) return null;
    if (lat == 0 || lng == 0) return null;
    if (!isValidLatLng(lat, lng)) return null;
    return LatLng(lat, lng);
  }

  double? _asDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    final s = v.toString().trim().replaceAll(',', '.');
    return double.tryParse(s);
  }
}
