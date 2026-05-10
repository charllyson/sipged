// lib/_blocs/modules/actives/roads/active_roads_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:sipged/_blocs/modules/actives/roads/active_roads_data.dart';

class ActiveRoadsRepository {
  ActiveRoadsRepository({
    String? tenantId,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _tenantId = _cleanTenantId(tenantId),
        _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  String? _tenantId;

  static String? _cleanTenantId(String? value) {
    final clean = value?.trim();
    return clean == null || clean.isEmpty ? null : clean;
  }

  String? get currentTenantId => _cleanTenantId(_tenantId);

  bool get hasTenant => currentTenantId != null;

  String get tenantId {
    final clean = currentTenantId;

    if (clean == null || clean.isEmpty) {
      throw StateError(
        'tenantId não definido em ActiveRoadsRepository. '
            'Selecione uma empresa antes de acessar rodovias.',
      );
    }

    return clean;
  }

  void setActiveTenantId(String? value) {
    final next = _cleanTenantId(value);
    if (_tenantId == next) return;
    _tenantId = next;
  }

  String get collectionPath {
    return 'tenants/$tenantId/assets/roads/items';
  }

  String get tilesBasePath {
    return 'tenants/$tenantId/assets/roads/tiles';
  }

  CollectionReference<Map<String, dynamic>> get _ref {
    return _db.collection(collectionPath);
  }

  String _uid() {
    return _auth.currentUser?.uid ?? '';
  }

  // ---------------------------------------------------------------------------
  // ROAD DATA
  // ---------------------------------------------------------------------------

  Future<List<ActiveRoadsData>> fetchAll() async {
    if (!hasTenant) return const <ActiveRoadsData>[];

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
    if (!hasTenant) return const <ActiveRoadsData>[];
    if (quadKeys.isEmpty) return const <ActiveRoadsData>[];

    final byId = <String, ActiveRoadsData>{};

    for (final quadKey in quadKeys) {
      final qs = await _db
          .collection(tilesBasePath)
          .doc('b$bucket')
          .collection(quadKey)
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

        final id = road.id?.trim();

        if (id != null && id.isNotEmpty) {
          byId[id] = road;
        }
      }
    }

    return byId.values.toList(growable: false);
  }

  Future<ActiveRoadsData?> getById(String id) async {
    if (!hasTenant) return null;

    final cleanId = id.trim();
    if (cleanId.isEmpty) return null;

    final snap = await _ref.doc(cleanId).get();

    if (!snap.exists) return null;

    final data = snap.data() ?? <String, dynamic>{};
    final fixed = _normalizeIfNeeded(data, snap.reference);

    return ActiveRoadsData.fromMap(
      fixed,
      id: snap.id,
    );
  }

  Future<ActiveRoadsData> upsert(ActiveRoadsData data) async {
    if (!hasTenant) {
      throw StateError(
        'tenantId é obrigatório para salvar rodovia.',
      );
    }

    final existingId = data.id?.trim();

    final docRef = existingId != null && existingId.isNotEmpty
        ? _ref.doc(existingId)
        : _ref.doc();

    final id = existingId != null && existingId.isNotEmpty
        ? existingId
        : docRef.id;

    final snap = await docRef.get();
    final isNew = !snap.exists || snap.data()?['createdAt'] == null;

    final json = data.copyWith(id: id).toMap()
      ..addAll({
        'id': id,
        'tenantId': tenantId,
        'companyId': tenantId,
        'recordPath': docRef.path,
        'sourceCollectionModel': 'tenant_assets_roads_items',
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _uid(),
      });

    if (isNew) {
      json['createdAt'] = FieldValue.serverTimestamp();
      json['createdBy'] = _uid();
    } else {
      json.remove('createdAt');
      json.remove('createdBy');
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
    if (!hasTenant) return;

    final cleanId = id.trim();
    if (cleanId.isEmpty) return;

    await _ref.doc(cleanId).delete();
  }

  // ---------------------------------------------------------------------------
  // IMPORTAÇÃO
  // ---------------------------------------------------------------------------

  Future<void> importarRodoviasComCoordenadas({
    required List<Map<String, dynamic>> linhasPrincipais,
    required List<Map<String, dynamic>> subcolecoes,
  }) async {
    if (!hasTenant) {
      throw StateError(
        'tenantId é obrigatório para importar rodovias.',
      );
    }

    for (int i = 0; i < linhasPrincipais.length; i++) {
      final linha = Map<String, dynamic>.from(linhasPrincipais[i]);
      final docRef = _ref.doc();

      linha['id'] = docRef.id;
      linha['tenantId'] = tenantId;
      linha['companyId'] = tenantId;
      linha['recordPath'] = docRef.path;
      linha['sourceCollectionModel'] = 'tenant_assets_roads_items';
      linha['updatedAt'] = FieldValue.serverTimestamp();
      linha['updatedBy'] = _uid();
      linha['createdAt'] = FieldValue.serverTimestamp();
      linha['createdBy'] = _uid();

      if (i < subcolecoes.length) {
        final sub = Map<String, dynamic>.from(subcolecoes[i]);

        if (sub['geometryType'] == 'MultiLineString' && sub['points'] is List) {
          final multiLine = (sub['points'] as List).cast<List>();
          final flattened = _flattenMultiLinePoints(multiLine);

          sub['points'] = flattened;
          sub['geometryType'] = 'LineString';
        }

        final pontos = sub['points'] as List? ?? const [];

        linha['geometryType'] = sub['geometryType'] ?? 'LineString';

        linha['points'] = pontos.map((point) {
          if (point is GeoPoint) return point;

          if (point is Map) {
            final lat = point['latitude'] ?? point['lat'];
            final lon = point['longitude'] ?? point['lng'] ?? point['lon'];

            return GeoPoint(
              (lat as num).toDouble(),
              (lon as num).toDouble(),
            );
          }

          if (point is List && point.length >= 2) {
            return GeoPoint(
              (point[1] as num).toDouble(),
              (point[0] as num).toDouble(),
            );
          }

          throw ArgumentError('Ponto inválido: $point');
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
      DocumentReference<Map<String, dynamic>> ref,
      ) {
    try {
      final points = data['points'];
      final geometryType = (data['geometryType'] ?? '').toString();

      final isNested = points is List &&
          points.isNotEmpty &&
          (points.first is List || geometryType == 'MultiLineString');

      if (!isNested) {
        return data;
      }

      final multiLine = points.cast<List>();

      final flattened = _flattenMultiLinePoints(multiLine).map((point) {
        return GeoPoint(
          point['latitude']!,
          point['longitude']!,
        );
      }).toList();

      final fixed = Map<String, dynamic>.from(data)
        ..['points'] = flattened
        ..['geometryType'] = 'LineString'
        ..['tenantId'] = tenantId
        ..['companyId'] = tenantId
        ..['recordPath'] = ref.path;

      ref.update({
        'points': flattened,
        'geometryType': 'LineString',
        'tenantId': tenantId,
        'companyId': tenantId,
        'recordPath': ref.path,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _uid(),
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

    for (final segment in multi) {
      final pontos = segment.map<Map<String, double>>((point) {
        if (point is GeoPoint) {
          return {
            'latitude': point.latitude,
            'longitude': point.longitude,
          };
        }

        if (point is Map) {
          final lat = point['latitude'] ?? point['lat'];
          final lon = point['longitude'] ?? point['lng'] ?? point['lon'];

          return {
            'latitude': (lat as num).toDouble(),
            'longitude': (lon as num).toDouble(),
          };
        }

        if (point is List && point.length >= 2) {
          return {
            'latitude': (point[1] as num).toDouble(),
            'longitude': (point[0] as num).toDouble(),
          };
        }

        throw ArgumentError('Ponto inválido: $point');
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