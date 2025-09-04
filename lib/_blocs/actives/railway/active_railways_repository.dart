import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:siged/_blocs/actives/railway/active_railway_data.dart';

class ActiveRailwaysRepository {
  final _ref = FirebaseFirestore.instance.collection('actives_railways');

  Future<List<ActiveRailwayData>> fetchAll() async {
    final qs = await _ref.get();
    final out = <ActiveRailwayData>[];
    for (final doc in qs.docs) {
      final data = doc.data();

      // Aceita dois formatos:
      // a) Campo 'multiLine' (list<list<[lon,lat]>> ou list<list<Map>>)
      // b) Campo 'geometry' GeoJSON (type + coordinates)
      // Se vier como 'points' de LineString (herdado de roads), também converte.

      final fixed = Map<String, dynamic>.from(data);

      // Normaliza 'points' (LineString) -> multiLine com 1 segmento (se existir)
      if (fixed['points'] is List && fixed['multiLine'] == null && fixed['geometry'] == null) {
        final pts = (fixed['points'] as List)
            .where((e) => e != null)
            .map((e) {
          if (e is GeoPoint) return [e.longitude, e.latitude];
          if (e is Map) return [ (e['longitude'] as num).toDouble(), (e['latitude'] as num).toDouble() ];
          if (e is List && e.length >= 2) return [ (e[0] as num).toDouble(), (e[1] as num).toDouble() ];
          return null;
        })
            .whereType<List<double>>()
            .toList();
        fixed['multiLine'] = [pts];
      }

      out.add(ActiveRailwayData.fromMap(fixed)..id = doc.id);
    }
    return out;
  }

  Future<ActiveRailwayData> upsert(ActiveRailwayData data) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final docRef = data.id != null ? _ref.doc(data.id) : _ref.doc();
    data.id ??= docRef.id;

    final base = data.toMap()
      ..['id'] = data.id
      ..['updatedAt'] = FieldValue.serverTimestamp()
      ..['updatedBy'] = uid;

    final snap = await docRef.get();
    final isNew = !snap.exists || (snap.data()?['createdAt'] == null);
    if (isNew) {
      base['createdAt'] = FieldValue.serverTimestamp();
      base['createdBy'] = uid;
    }

    await docRef.set(base, SetOptions(merge: true));
    final after = await docRef.get();
    final map = after.data() as Map<String, dynamic>;
    return ActiveRailwayData.fromMap(map)..id = after.id;
  }

  Future<void> deleteById(String id) async => _ref.doc(id).delete();

  /// Importa várias ferrovias recebendo os dados “linha” + geometrias.
  /// Espera cada geometria no formato:
  /// { "geometryType": "MultiLineString"|"LineString",
  ///   "points": [
  ///     // MultiLine: [ [ {longitude, latitude}, ... ], [ ... ] ]
  ///     // LineString: [ {longitude, latitude}, ... ]
  ///   ]
  /// }
  Future<void> importBatch({
    required List<Map<String, dynamic>> linhasPrincipais,
    required List<Map<String, dynamic>> geometrias,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    for (int i = 0; i < linhasPrincipais.length; i++) {
      final linha = Map<String, dynamic>.from(linhasPrincipais[i]);
      final docRef = _ref.doc();
      linha['id'] = docRef.id;

      linha['createdAt'] = FieldValue.serverTimestamp();
      linha['createdBy'] = uid;
      linha['updatedAt'] = FieldValue.serverTimestamp();
      linha['updatedBy'] = uid;

      // Normaliza geometria para armazenar como multiLine (preferência para ferrovias)
      if (i < geometrias.length) {
        final g = Map<String, dynamic>.from(geometrias[i]);
        final type = (g['geometryType'] ?? 'MultiLineString').toString();
        final points = g['points'] as List? ?? const [];

        if (type == 'LineString') {
          // vira multiLine com 1 segmento
          final line = points.map((p) {
            final lat = (p['latitude'] as num).toDouble();
            final lng = (p['longitude'] as num).toDouble();
            return [lng, lat];
          }).toList();
          linha['multiLine'] = [line];
        } else {
          // MultiLineString esperado: lista de listas
          final multi = points.map<List>((segmento) {
            return (segmento as List).map((p) {
              final lat = (p['latitude'] as num).toDouble();
              final lng = (p['longitude'] as num).toDouble();
              return [lng, lat];
            }).toList();
          }).toList();
          linha['multiLine'] = multi;
        }
      }

      await docRef.set(linha, SetOptions(merge: true));
    }
  }
}
