// lib/_blocs/planning/highway_domain/planning_highway_domain_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'planning_highway_domain_data.dart';

class PlanningHighwayDomainRepository {
  PlanningHighwayDomainRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('planning_highway_domain');

  Future<List<PlanningHighwayDomainData>> fetchAll() async {
    final snap = await _col.orderBy('createdAt', descending: false).get();
    return snap.docs
        .map((d) => PlanningHighwayDomainData.fromFirestore(d.id, d.data()))
        .toList();
  }

  /// Importa em lote — `linhas` = metadados por doc; `geometrias` = [{geometryType, points:[{latitude,longitude}...]}...]
  Future<void> importBatch({
    required List<Map<String, dynamic>> linhas,
    required List<Map<String, dynamic>> geometrias,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    // Observação: assumimos que `linhas.length == geometrias.length` OU
    // usaremos o índice mínimo comum.
    final n = (linhas.length < geometrias.length) ? linhas.length : geometrias.length;
    final now = FieldValue.serverTimestamp();

    final wb = _firestore.batch();
    for (int i = 0; i < n; i++) {
      final linha = Map<String, dynamic>.from(linhas[i]);
      final geom = Map<String, dynamic>.from(geometrias[i]);

      // Normaliza pontos para GeoPoint (melhor para queries geoespaciais simples)
      final pts = (geom['points'] as List?) ?? const [];
      final pointsAsGeo = pts.map((p) {
        if (p is GeoPoint) return p;
        if (p is Map) {
          final lat = (p['lat'] ?? p['latitude']) as num;
          final lng = (p['lng'] ?? p['longitude']) as num;
          return GeoPoint(lat.toDouble(), lng.toDouble());
        }
        if (p is List && p.length >= 2) {
          final lat = (p[1] as num).toDouble();
          final lng = (p[0] as num).toDouble();
          return GeoPoint(lat, lng);
        }
        throw Exception('Ponto inválido.');
      }).toList();

      final docRef = _col.doc();
      final data = {
        'props': linha,
        'geometryType': (geom['geometryType'] ?? 'LineString').toString(),
        'points': pointsAsGeo,
        'createdAt': now,
        'createdBy': uid,
        'updatedAt': now,
        'updatedBy': uid,
      };
      wb.set(docRef, data, SetOptions(merge: true));
    }
    await wb.commit();
  }

  /// Remove todos os documentos da coleção (cautela!)
  Future<void> deleteAll() async {
    final snap = await _col.get();
    final wb = _firestore.batch();
    for (final d in snap.docs) {
      wb.delete(d.reference);
    }
    await wb.commit();
  }
}
