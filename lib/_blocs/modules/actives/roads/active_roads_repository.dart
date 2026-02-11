// lib/_blocs/modules/actives/roads/active_roads_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:siged/_blocs/modules/actives/roads/active_roads_data.dart';

class ActiveRoadsRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _ref = FirebaseFirestore.instance.collection('actives_roads');

  /// ✅ Mantém para debug/admin (carrega tudo)
  Future<List<ActiveRoadsData>> fetchAll() async {
    final qs = await _ref.get();

    final list = <ActiveRoadsData>[];
    for (final doc in qs.docs) {
      final data = doc.data();
      final fixed = _normalizeIfNeeded(data, doc.reference);
      list.add(ActiveRoadsData.fromMap(fixed, id: doc.id));
    }
    return list;
  }

  /// ✅ NOVO: tiles/bucket (viewport only)
  ///
  /// Estrutura recomendada:
  /// actives_roads_tiles/b{bucket}/{quadKey}/items/{roadId}
  ///
  /// Doc:
  ///  - id (opcional)
  ///  - acronym, roadCode, stateSurface, regional, extension...
  ///  - points: [GeoPoint...]
  ///  - geometryType: 'LineString'
  Future<List<ActiveRoadsData>> fetchByTiles({
    required int bucket,
    required List<String> quadKeys,
  }) async {
    if (quadKeys.isEmpty) return const [];

    final byId = <String, ActiveRoadsData>{};

    for (final qk in quadKeys) {
      final qs = await _db
          .collection('actives_roads_tiles')
          .doc('b$bucket')
          .collection(qk)
          .doc('roads')
          .collection('items')
          .get();

      for (final doc in qs.docs) {
        final data = doc.data();
        final fixed = _normalizeIfNeeded(data, doc.reference);
        final road = ActiveRoadsData.fromMap(fixed, id: doc.id);
        if (road.id != null) byId[road.id!] = road;
      }
    }

    return byId.values.toList(growable: false);
  }

  Future<ActiveRoadsData> upsert(ActiveRoadsData data) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final docRef = data.id != null ? _ref.doc(data.id) : _ref.doc();
    final id = data.id ?? docRef.id;

    final base = data.toMap()..['id'] = id;
    base['updatedAt'] = FieldValue.serverTimestamp();
    base['updatedBy'] = uid;

    final snap = await docRef.get();
    final isNew = !snap.exists || (snap.data()?['createdAt'] == null);

    if (isNew) {
      base['createdAt'] = FieldValue.serverTimestamp();
      base['createdBy'] = uid;
    }

    await docRef.set(base, SetOptions(merge: true));
    final after = await docRef.get();
    return ActiveRoadsData.fromMap(after.data() as Map<String, dynamic>, id: after.id);
  }

  Future<void> deleteById(String id) async => _ref.doc(id).delete();

  Future<void> importarRodoviasComCoordenadas({
    required List<Map<String, dynamic>> linhasPrincipais,
    required List<Map<String, dynamic>> subcolecoes,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    for (int i = 0; i < linhasPrincipais.length; i++) {
      final linha = Map<String, dynamic>.from(linhasPrincipais[i]);
      final docRef = _ref.doc();
      linha['id'] = docRef.id;

      linha['updatedAt'] = FieldValue.serverTimestamp();
      linha['updatedBy'] = uid;
      linha['createdAt'] = FieldValue.serverTimestamp();
      linha['createdBy'] = uid;

      if (i < subcolecoes.length) {
        final sub = Map<String, dynamic>.from(subcolecoes[i]);

        if (sub['geometryType'] == 'MultiLineString' && sub['points'] is List) {
          final ml = (sub['points'] as List).cast<List>();
          final flattened = _flattenMultiLinePoints(ml);
          sub['points'] = flattened;
          sub['geometryType'] = 'LineString';
        }

        final pontos = (sub['points'] as List?) ?? const [];
        linha['geometryType'] = sub['geometryType'] ?? 'LineString';
        linha['points'] = pontos.map((p) {
          final lat = (p['latitude'] as num).toDouble();
          final lng = (p['longitude'] as num).toDouble();
          return GeoPoint(lat, lng);
        }).toList();
      }

      await docRef.set(linha, SetOptions(merge: true));
    }
  }

  // -------- internals --------

  Map<String, dynamic> _normalizeIfNeeded(
      Map<String, dynamic> data,
      DocumentReference ref,
      ) {
    try {
      final pts = data['points'];
      final gtype = (data['geometryType'] ?? '').toString();

      final isNested = pts is List &&
          pts.isNotEmpty &&
          (pts.first is List || (gtype == 'MultiLineString'));

      if (isNested) {
        final ml = (pts).cast<List>();
        final flattened = _flattenMultiLinePoints(ml)
            .map((p) => GeoPoint(p['latitude']!, p['longitude']!))
            .toList();

        data = Map<String, dynamic>.from(data)
          ..['points'] = flattened
          ..['geometryType'] = 'LineString';

        // opcional: persistir correção
        // ignore: unawaited_futures
        ref.update({'points': flattened, 'geometryType': 'LineString'});
      }
      return data;
    } catch (_) {
      return data;
    }
  }

  List<Map<String, double>> _flattenMultiLinePoints(List<List> multi) {
    final caminho = <Map<String, double>>[];

    for (final seg in multi) {
      final pontos = seg.map<Map<String, double>>((p) {
        return {
          'latitude': (p['latitude'] as num).toDouble(),
          'longitude': (p['longitude'] as num).toDouble(),
        };
      }).toList();

      if (caminho.isEmpty) {
        caminho.addAll(pontos);
      } else {
        final last = caminho.last;
        final first = pontos.first;
        final end = pontos.last;

        double dist(Map<String, double> a, Map<String, double> b) {
          final dx = a['longitude']! - b['longitude']!;
          final dy = a['latitude']! - b['latitude']!;
          return dx * dx + dy * dy;
        }

        final distFirst = dist(last, first);
        final distEnd = dist(last, end);
        final ordered = distEnd < distFirst ? pontos.reversed.toList() : pontos;
        caminho.addAll(ordered);
      }
    }
    return caminho;
  }
}
