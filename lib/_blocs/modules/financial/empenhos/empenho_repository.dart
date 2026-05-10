import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_data.dart';

import 'empenho_data.dart';

class EmpenhoRepository {
  EmpenhoRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    String? tenantId,
    this.collectionPath,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _tenantId = tenantId?.trim();

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  String? _tenantId;

  /// Permite sobrescrever totalmente o caminho.
  ///
  /// Útil para testes, telas administrativas ou migrações.
  final String? collectionPath;

  void setActiveTenantId(String? tenantId) {
    final clean = tenantId?.trim();

    _tenantId = clean == null || clean.isEmpty ? null : clean;
  }

  String get resolvedTenantId {
    final tid = _tenantId?.trim() ?? '';

    if (tid.isEmpty) {
      throw StateError(
        'Tenant ativo não identificado para carregar empenhos.',
      );
    }

    return tid;
  }

  String get resolvedCollectionPath {
    final customPath = collectionPath?.trim() ?? '';

    if (customPath.isNotEmpty) {
      return customPath;
    }

    return EmpenhoData.tenantCollectionPath(resolvedTenantId);
  }

  CollectionReference<Map<String, dynamic>> _col() {
    return _db.collection(resolvedCollectionPath);
  }

  DocumentReference<Map<String, dynamic>> _doc(String id) {
    return _col().doc(id);
  }

  Future<List<EmpenhoData>> getAll() async {
    final qs = await _col().orderBy('date', descending: true).get();

    return qs.docs.map((d) => EmpenhoData.fromDocument(d)).toList();
  }

  Future<List<EmpenhoData>> getAllByContract({
    required String contractId,
  }) async {
    final cid = contractId.trim();

    if (cid.isEmpty) {
      return <EmpenhoData>[];
    }

    final qs = await _col()
        .where('contractId', isEqualTo: cid)
        .orderBy('date', descending: true)
        .get();

    return qs.docs.map((d) => EmpenhoData.fromDocument(d)).toList();
  }

  Future<List<DfdData>> getAvailableDfds({
    int limit = 1500,
  }) async {
    final currentTenantId = resolvedTenantId;

    final snap = await _db.collectionGroup('objeto').limit(limit).get();

    final map = <String, DfdData>{};

    for (final doc in snap.docs) {
      final data = doc.data();

      final descricao = (data['descricaoObjeto'] ?? '').toString().trim();

      if (descricao.isEmpty) {
        continue;
      }

      final segments = doc.reference.path
          .split('/')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final tenantIndex = segments.indexOf('tenants');

      if (tenantIndex < 0) {
        continue;
      }

      if (tenantIndex + 1 >= segments.length) {
        continue;
      }

      final docTenantId = segments[tenantIndex + 1].trim();

      if (docTenantId != currentTenantId) {
        continue;
      }

      String? contractId;

      for (int i = 0; i < segments.length - 1; i++) {
        if (segments[i] == 'contracts' && i + 1 < segments.length) {
          contractId = segments[i + 1];
          break;
        }
      }

      final cid = (contractId ?? '').trim();

      if (cid.isEmpty) {
        continue;
      }

      final dfd = DfdData(
        contractId: cid,
        descricaoObjeto: descricao,
      );

      final key = '${currentTenantId}__${cid}__${descricao.toLowerCase()}';

      map[key] = dfd;
    }

    final list = map.values.toList()
      ..sort((a, b) {
        final av = (a.descricaoObjeto ?? '').toLowerCase();
        final bv = (b.descricaoObjeto ?? '').toLowerCase();

        return av.compareTo(bv);
      });

    return list;
  }

  Future<String> saveOrUpdate(EmpenhoData e) async {
    final uid = _auth.currentUser?.uid ?? '';
    final tenantId = resolvedTenantId;

    final isUpdate = (e.id ?? '').trim().isNotEmpty;

    final docRef = isUpdate ? _doc(e.id!.trim()) : _col().doc();

    final id = docRef.id;

    final normalized = e.copyWith(id: id);

    final payload = normalized.toFirestore()
      ..addAll({
        'id': id,
        'tenantId': tenantId,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': uid,
      });

    final cid = normalized.contractId?.trim() ?? '';

    if (cid.isNotEmpty) {
      payload['contractId'] = cid;
    } else {
      payload.remove('contractId');
    }

    final demandId = normalized.demandContractId?.trim() ?? '';

    if (demandId.isNotEmpty) {
      payload['demandContractId'] = demandId;
    } else {
      payload.remove('demandContractId');
    }

    final companyId = normalized.companyId?.trim() ?? '';

    if (companyId.isNotEmpty) {
      payload['companyId'] = companyId;
    } else {
      payload.remove('companyId');
    }

    final fundingSourceId = normalized.fundingSourceId?.trim() ?? '';

    if (fundingSourceId.isNotEmpty) {
      payload['fundingSourceId'] = fundingSourceId;
    } else {
      payload.remove('fundingSourceId');
    }

    final existing = await docRef.get();
    final hasCreatedAt =
        existing.exists && existing.data()?['createdAt'] != null;

    if (!hasCreatedAt) {
      payload['createdAt'] = FieldValue.serverTimestamp();
      payload['createdBy'] = uid;
    } else {
      payload.remove('createdAt');
      payload.remove('createdBy');
    }

    await docRef.set(payload, SetOptions(merge: true));

    return id;
  }

  Future<void> deleteById(String empenhoId) async {
    final id = empenhoId.trim();

    if (id.isEmpty) {
      return;
    }

    await _doc(id).delete();
  }
}