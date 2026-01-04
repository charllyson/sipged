// lib/_blocs/actives/railway/active_railways_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'active_railway_data.dart';

class ActiveRailwaysRepository {
  final FirebaseFirestore _firestore;

  ActiveRailwaysRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _ref =>
      _firestore.collection('actives_railways');

  // ---------------------------------------------------------------------------
  // FETCH ALL
  // ---------------------------------------------------------------------------
  Future<List<ActiveRailwayData>> fetchAll() async {
    final snap = await _ref.get();
    final result = <ActiveRailwayData>[];

    for (final doc in snap.docs) {
      final data = Map<String, dynamic>.from(doc.data());

      // Caso legado: geometryType == MultiLineString + points em formato multi-line aninhado
      final needsFix = data['geometryType'] == 'MultiLineString' ||
          (data['points'] is List &&
              (data['points'] as List).isNotEmpty &&
              (data['points'] as List).first is List);

      if (needsFix && data['points'] is List) {
        final multiPoints =
        List<List<dynamic>>.from(data['points'] as List<dynamic>);
        final flattened = _normalizeMultiLineToGeoPoints(multiPoints);

        data['points'] = flattened;
        data['geometryType'] = 'LineString';

        // atualiza documento (migração silenciosa)
        await doc.reference.update({
          'points': flattened,
          'geometryType': 'LineString',
        });
      }

      final rd = ActiveRailwayData.fromMap(data)..id = doc.id;
      if (rd.id != null && rd.points != null && rd.points!.isNotEmpty) {
        result.add(rd);
      }
    }

    result.sort((a, b) {
      final aKey = '${a.codigo ?? ''}_${a.id ?? ''}';
      final bKey = '${b.codigo ?? ''}_${b.id ?? ''}';
      return aKey.compareTo(bKey);
    });

    return List.unmodifiable(result);
  }

  // ---------------------------------------------------------------------------
  // UPSERT / DELETE
  // ---------------------------------------------------------------------------
  Future<ActiveRailwayData> upsert(ActiveRailwayData data) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final docRef = data.id != null ? _ref.doc(data.id) : _ref.doc();
    data.id ??= docRef.id;

    final base = data.toFirestore()
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

  // ---------------------------------------------------------------------------
  // IMPORT BATCH (mesma lógica do antigo BLoC, agora central no repo)
  // ---------------------------------------------------------------------------
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

      if (i < geometrias.length) {
        final sub = Map<String, dynamic>.from(geometrias[i]);

        if (sub['geometryType'] == 'MultiLineString' &&
            sub['points'] is List) {
          final multi = List<List<dynamic>>.from(sub['points']);
          final flattened = _normalizeMultiLineToGeoPoints(multi);
          sub['points'] = flattened;
          sub['geometryType'] = 'LineString';
        }

        final pontos = sub['points'] as List<dynamic>?;
        final tipo = sub['geometryType'] ?? 'LineString';
        linha['geometryType'] = tipo;

        if (pontos != null) {
          linha['points'] = pontos.map((p) {
            if (p is GeoPoint) return p;
            if (p is List && p.length >= 2) {
              final lat = (p[1] as num).toDouble(); // [lon, lat]
              final lng = (p[0] as num).toDouble();
              return GeoPoint(lat, lng);
            }
            return GeoPoint(
              (p['latitude'] as num).toDouble(),
              (p['longitude'] as num).toDouble(),
            );
          }).toList();
        }
      }

      await docRef.set(linha, SetOptions(merge: true));
    }
  }

  /// Achata uma MultiLineString em uma única `List<GeoPoint>`, ordenando por continuidade.
  List<GeoPoint> _normalizeMultiLineToGeoPoints(
      List<List<dynamic>> segmentos) {
    final caminhoFinal = <Map<String, double>>[];

    double _dist(Map<String, double> p1, Map<String, double> p2) {
      final dx = p1['longitude']! - p2['longitude']!;
      final dy = p1['latitude']! - p2['latitude']!;
      return dx * dx + dy * dy;
    }

    for (var trecho in segmentos) {
      final pontos = trecho.map<Map<String, double>>((p) {
        if (p is GeoPoint) {
          return {'latitude': p.latitude, 'longitude': p.longitude};
        }
        if (p is List && p.length >= 2) {
          return {
            'latitude': (p[1] as num).toDouble(),
            'longitude': (p[0] as num).toDouble(),
          };
        }
        return {
          'latitude': (p['latitude'] as num).toDouble(),
          'longitude': (p['longitude'] as num).toDouble(),
        };
      }).toList();

      if (caminhoFinal.isEmpty) {
        caminhoFinal.addAll(pontos);
      } else {
        final ultimo = caminhoFinal.last;
        final primeiro = pontos.first;
        final fim = pontos.last;

        final distFirst = _dist(ultimo, primeiro);
        final distLast = _dist(ultimo, fim);

        final pontosOrdenados =
        distLast < distFirst ? pontos.reversed.toList() : pontos;
        caminhoFinal.addAll(pontosOrdenados);
      }
    }

    return caminhoFinal
        .map((p) => GeoPoint(p['latitude']!, p['longitude']!))
        .toList();
  }
}
