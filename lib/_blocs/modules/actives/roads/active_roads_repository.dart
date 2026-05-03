import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:sipged/_blocs/modules/actives/roads/active_roads_data.dart';

class ActiveRoadsRepository {
  ActiveRoadsRepository({
    String? tenantId,
    FirebaseFirestore? firestore,
  })  : _tenantId = tenantId ?? _manualTenantIdForTest,
        _db = firestore ?? FirebaseFirestore.instance;

  /// ---------------------------------------------------------------------------
  /// TESTE TEMPORÁRIO MULTI-TENANT
  /// ---------------------------------------------------------------------------
  ///
  /// ID fixo usado enquanto o TenantContext/TenantCubit ainda não estiver
  /// integrado oficialmente.
  ///
  /// Quando for remover o tenant fixo, altere para:
  ///
  /// static const String? _manualTenantIdForTest = null;
  ///
  static const String _manualTenantIdForTest = 'SZQmefRUqdtLB14ahcuh';

  final String? _tenantId;
  final FirebaseFirestore _db;

  bool get _hasTenant {
    return _tenantId != null && _tenantId.trim().isNotEmpty;
  }

  String get effectiveTenantId {
    return _tenantId?.trim() ?? '';
  }

  String get collectionPath {
    if (_hasTenant) {
      return 'tenants/$effectiveTenantId/assets/roads/items';
    }

    return 'actives_roads';
  }

  String get tilesBasePath {
    if (_hasTenant) {
      return 'tenants/$effectiveTenantId/assets/roads/tiles';
    }

    return 'actives_roads_tiles';
  }

  CollectionReference<Map<String, dynamic>> get _ref {
    return _db.collection(collectionPath);
  }

  // ---------------------------------------------------------------------------
  // ROAD DATA
  // ---------------------------------------------------------------------------

  Future<List<ActiveRoadsData>> fetchAll() async {
    final qs = await _ref.get();

    final list = <ActiveRoadsData>[];

    for (final doc in qs.docs) {
      final data = doc.data();
      final fixed = _normalizeIfNeeded(data, doc.reference);

      list.add(
        ActiveRoadsData.fromMap(
          fixed,
          id: doc.id,
        ),
      );
    }

    return list;
  }

  Future<List<ActiveRoadsData>> fetchByTiles({
    required int bucket,
    required List<String> quadKeys,
  }) async {
    if (quadKeys.isEmpty) return const <ActiveRoadsData>[];

    final byId = <String, ActiveRoadsData>{};

    for (final qk in quadKeys) {
      final qs = await _db
          .collection(tilesBasePath)
          .doc('b$bucket')
          .collection(qk)
          .doc('roads')
          .collection('items')
          .get();

      for (final doc in qs.docs) {
        final data = doc.data();
        final fixed = _normalizeIfNeeded(data, doc.reference);

        final road = ActiveRoadsData.fromMap(
          fixed,
          id: doc.id,
        );

        final id = road.id;
        if (id != null && id.trim().isNotEmpty) {
          byId[id] = road;
        }
      }
    }

    return byId.values.toList(growable: false);
  }

  Future<ActiveRoadsData?> getById(String id) async {
    if (id.trim().isEmpty) return null;

    final snap = await _ref.doc(id.trim()).get();

    if (!snap.exists) return null;

    final data = snap.data() ?? <String, dynamic>{};
    final fixed = _normalizeIfNeeded(data, snap.reference);

    return ActiveRoadsData.fromMap(
      fixed,
      id: snap.id,
    );
  }

  Future<ActiveRoadsData> upsert(ActiveRoadsData data) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;

    final docRef = data.id != null && data.id!.trim().isNotEmpty
        ? _ref.doc(data.id!.trim())
        : _ref.doc();

    final id = data.id != null && data.id!.trim().isNotEmpty
        ? data.id!.trim()
        : docRef.id;

    final json = data.toMap()
      ..addAll({
        'id': id,
        if (_hasTenant) 'tenantId': effectiveTenantId,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': firebaseUser?.uid ?? '',
      });

    final snap = await docRef.get();
    final isNew = !snap.exists || snap.data()?['createdAt'] == null;

    if (isNew) {
      json['createdAt'] = FieldValue.serverTimestamp();
      json['createdBy'] = firebaseUser?.uid ?? '';
    }

    await docRef.set(
      json,
      SetOptions(merge: true),
    );

    final after = await docRef.get();
    final afterData = after.data() ?? <String, dynamic>{};
    final fixed = _normalizeIfNeeded(afterData, after.reference);

    return ActiveRoadsData.fromMap(
      fixed,
      id: after.id,
    );
  }

  Future<void> deleteById(String id) async {
    if (id.trim().isEmpty) return;

    await _ref.doc(id.trim()).delete();
  }

  // ---------------------------------------------------------------------------
  // IMPORTAÇÃO
  // ---------------------------------------------------------------------------

  Future<void> importarRodoviasComCoordenadas({
    required List<Map<String, dynamic>> linhasPrincipais,
    required List<Map<String, dynamic>> subcolecoes,
  }) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;

    for (int i = 0; i < linhasPrincipais.length; i++) {
      final linha = Map<String, dynamic>.from(linhasPrincipais[i]);
      final docRef = _ref.doc();

      linha['id'] = docRef.id;

      if (_hasTenant) {
        linha['tenantId'] = effectiveTenantId;
      }

      linha['updatedAt'] = FieldValue.serverTimestamp();
      linha['updatedBy'] = firebaseUser?.uid ?? '';
      linha['createdAt'] = FieldValue.serverTimestamp();
      linha['createdBy'] = firebaseUser?.uid ?? '';

      if (i < subcolecoes.length) {
        final sub = Map<String, dynamic>.from(subcolecoes[i]);

        if (sub['geometryType'] == 'MultiLineString' && sub['points'] is List) {
          final ml = (sub['points'] as List).cast<List>();
          final flattened = _flattenMultiLinePoints(ml);

          sub['points'] = flattened;
          sub['geometryType'] = 'LineString';
        }

        final pontos = sub['points'] as List? ?? const [];

        linha['geometryType'] = sub['geometryType'] ?? 'LineString';

        linha['points'] = pontos.map((p) {
          if (p is GeoPoint) return p;

          if (p is Map) {
            final lat = p['latitude'] ?? p['lat'];
            final lon = p['longitude'] ?? p['lng'] ?? p['lon'];

            return GeoPoint(
              (lat as num).toDouble(),
              (lon as num).toDouble(),
            );
          }

          if (p is List && p.length >= 2) {
            return GeoPoint(
              (p[1] as num).toDouble(),
              (p[0] as num).toDouble(),
            );
          }

          throw ArgumentError('Ponto inválido: $p');
        }).toList();
      }

      await docRef.set(
        linha,
        SetOptions(merge: true),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // NORMALIZAÇÃO DE GEOMETRIA
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _normalizeIfNeeded(
      Map<String, dynamic> data,
      DocumentReference ref,
      ) {
    try {
      final pts = data['points'];
      final gtype = (data['geometryType'] ?? '').toString();

      final isNested = pts is List &&
          pts.isNotEmpty &&
          (pts.first is List || gtype == 'MultiLineString');

      if (!isNested) {
        return data;
      }

      final ml = pts.cast<List>();

      final flattened = _flattenMultiLinePoints(ml)
          .map((p) {
        return GeoPoint(
          p['latitude']!,
          p['longitude']!,
        );
      })
          .toList();

      final fixed = Map<String, dynamic>.from(data)
        ..['points'] = flattened
        ..['geometryType'] = 'LineString';

      ref.update({
        'points': flattened,
        'geometryType': 'LineString',
        if (_hasTenant) 'tenantId': effectiveTenantId,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
      });

      return fixed;
    } catch (_) {
      return data;
    }
  }

  List<Map<String, double>> _flattenMultiLinePoints(List<List> multi) {
    final caminho = <Map<String, double>>[];

    double dist(Map<String, double> a, Map<String, double> b) {
      final dx = a['longitude']! - b['longitude']!;
      final dy = a['latitude']! - b['latitude']!;
      return dx * dx + dy * dy;
    }

    for (final seg in multi) {
      final pontos = seg.map<Map<String, double>>((p) {
        if (p is GeoPoint) {
          return {
            'latitude': p.latitude,
            'longitude': p.longitude,
          };
        }

        if (p is Map) {
          final lat = p['latitude'] ?? p['lat'];
          final lon = p['longitude'] ?? p['lng'] ?? p['lon'];

          return {
            'latitude': (lat as num).toDouble(),
            'longitude': (lon as num).toDouble(),
          };
        }

        if (p is List && p.length >= 2) {
          return {
            'latitude': (p[1] as num).toDouble(),
            'longitude': (p[0] as num).toDouble(),
          };
        }

        throw ArgumentError('Ponto inválido: $p');
      }).toList();

      if (pontos.isEmpty) continue;

      if (caminho.isEmpty) {
        caminho.addAll(pontos);
      } else {
        final last = caminho.last;
        final first = pontos.first;
        final end = pontos.last;

        final distFirst = dist(last, first);
        final distEnd = dist(last, end);

        final ordered = distEnd < distFirst ? pontos.reversed.toList() : pontos;

        caminho.addAll(ordered);
      }
    }

    return caminho;
  }
}