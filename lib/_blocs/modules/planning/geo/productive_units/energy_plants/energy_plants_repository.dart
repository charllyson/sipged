// lib/_blocs/modules/planning/geo/productive_units/energy_plants/energy_plants_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

class EnergyPlantsRepository {
  EnergyPlantsRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col() {
    return _db
        .collection('geo')
        .doc('productive_units')
        .collection('usinas_de_energia');
  }

  /// ✅ Para pintar a correntinha (tem dados ou não).
  Future<bool> hasData({required String uf}) async {
    final ufNorm = uf.trim().toUpperCase();

    // tenta por UF
    final snap = await _col().where('uf', isEqualTo: ufNorm).limit(1).get();
    if (snap.docs.isNotEmpty) return true;

    // fallback geral
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

    // fallback: se não tiver UF, retorna tudo
    final all = await _col().get();
    return all.docs.map((d) {
      final data = d.data();
      data['_id'] = d.id;
      return data;
    }).toList();
  }

  bool isValidLatLng(double lat, double lng) =>
      lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;

  /// Converte o que veio do Firestore em LatLng.
  /// Suporta:
  /// - GeoPoint
  /// - Map {lat,lng} / {latitude,longitude}
  /// - GeoJSON Map {type:"Point", coordinates:[lng,lat]}
  /// - List [lng,lat]
  LatLng? parsePoint(dynamic raw) {
    if (raw == null) return null;

    // Caso 1: GeoPoint direto
    if (raw is GeoPoint) {
      final lat = raw.latitude;
      final lng = raw.longitude;
      if (!isValidLatLng(lat, lng)) return null;
      return LatLng(lat, lng);
    }

    // Caso 2: Map
    if (raw is Map) {
      // {lat,lng} ou {latitude,longitude}
      final lat = _asDouble(raw['lat'] ?? raw['latitude']);
      final lng = _asDouble(raw['lng'] ?? raw['lon'] ?? raw['longitude']);
      if (lat != null && lng != null && isValidLatLng(lat, lng)) {
        return LatLng(lat, lng);
      }

      // GeoJSON: { type: "Point", coordinates: [lng, lat] }
      final type = (raw['type'] ?? '').toString().trim().toLowerCase();
      final coords = raw['coordinates'];
      if (type == 'point' && coords is List && coords.length >= 2) {
        final lng2 = _asDouble(coords[0]);
        final lat2 = _asDouble(coords[1]);
        if (lat2 != null && lng2 != null && isValidLatLng(lat2, lng2)) {
          return LatLng(lat2, lng2);
        }
      }

      // Também tenta campos tipo N/E dentro de um map genérico
      final latNE = _asDouble(raw['NumCoordNEmpreendimento'] ??
          raw['numCoordNEmpreendimento'] ??
          raw['coordN'] ??
          raw['latN']);
      final lngNE = _asDouble(raw['NumCoordEEmpreendimento'] ??
          raw['numCoordEEmpreendimento'] ??
          raw['coordE'] ??
          raw['lngE']);
      if (latNE != null && lngNE != null && isValidLatLng(latNE, lngNE)) {
        return LatLng(latNE, lngNE); // (LAT=N, LNG=E)
      }
    }

    // Caso 3: List [lng, lat]
    if (raw is List && raw.length >= 2) {
      final lng = _asDouble(raw[0]);
      final lat = _asDouble(raw[1]);
      if (lat != null && lng != null && isValidLatLng(lat, lng)) {
        return LatLng(lat, lng);
      }
    }

    return null;
  }

  /// ✅ Fallback direto da "row" (documento inteiro),
  /// para casos em que não existe `point/latLng/location` mas existem
  /// campos separados como NumCoordNEmpreendimento / NumCoordEEmpreendimento.
  LatLng? parsePointFromRow(Map<String, dynamic> row) {
    final lat = _asDouble(row['NumCoordNEmpreendimento'] ??
        row['numCoordNEmpreendimento'] ??
        row['coordN'] ??
        row['latitude'] ??
        row['lat']);

    final lng = _asDouble(row['NumCoordEEmpreendimento'] ??
        row['numCoordEEmpreendimento'] ??
        row['coordE'] ??
        row['longitude'] ??
        row['lng'] ??
        row['lon']);

    if (lat == null || lng == null) return null;
    if (lat == 0 || lng == 0) return null;
    if (!isValidLatLng(lat, lng)) return null;

    // IMPORTANTÍSSIMO:
    // N = latitude, E = longitude  -> LatLng(lat, lng)
    return LatLng(lat, lng);
  }

  double? _asDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    final s = v.toString().trim().replaceAll(',', '.');
    return double.tryParse(s);
  }
}
