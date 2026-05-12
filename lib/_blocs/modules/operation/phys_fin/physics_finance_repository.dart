// lib/_blocs/modules/operation/phys_fin/physics_finance_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'physics_finance_data.dart';

class PhysicsFinanceRepository {
  PhysicsFinanceRepository({
    FirebaseFirestore? db,
    FirebaseAuth? auth,
    String? tenantId,
  })  : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _tenantId = tenantId?.trim();

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  String? _tenantId;

  // ---------------------------------------------------------------------------
  // Tenant obrigatório
  // ---------------------------------------------------------------------------

  String get tenantId {
    final id = _tenantId?.trim();

    if (id == null || id.isEmpty) {
      throw StateError(
        'tenantId não definido em PhysicsFinanceRepository. '
            'Selecione uma empresa antes de acessar o planejamento físico-financeiro.',
      );
    }

    return id;
  }

  String? get currentTenantId {
    final id = _tenantId?.trim();
    return id == null || id.isEmpty ? null : id;
  }

  bool get hasTenant {
    final id = _tenantId?.trim();
    return id != null && id.isNotEmpty;
  }

  void setActiveTenantId(String? value) {
    final clean = value?.trim();
    final next = clean == null || clean.isEmpty ? null : clean;

    if (_tenantId == next) return;

    _tenantId = next;
  }

  String _requireContractId(String contractId) {
    final clean = contractId.trim();

    if (clean.isEmpty) {
      throw ArgumentError('contractId é obrigatório.');
    }

    return clean;
  }

  String _requireAdditiveId(String additiveId) {
    final clean = additiveId.trim();

    if (clean.isEmpty) {
      throw ArgumentError('additiveId é obrigatório.');
    }

    return clean;
  }

  String _requireScheduleId(String scheduleId) {
    final clean = scheduleId.trim();

    if (clean.isEmpty) {
      throw ArgumentError('scheduleId é obrigatório.');
    }

    return clean;
  }

  // ---------------------------------------------------------------------------
  // References
  // ---------------------------------------------------------------------------

  CollectionReference<Map<String, dynamic>> _contractsCollection() {
    return _db.collection('tenants').doc(tenantId).collection('contracts');
  }

  DocumentReference<Map<String, dynamic>> _contractDoc(String contractId) {
    return _contractsCollection().doc(_requireContractId(contractId));
  }

  CollectionReference<Map<String, dynamic>> _additivesCollection(
      String contractId,
      ) {
    return _contractDoc(contractId).collection('additives');
  }

  DocumentReference<Map<String, dynamic>> _additiveDoc({
    required String contractId,
    required String additiveId,
  }) {
    return _additivesCollection(contractId).doc(
      _requireAdditiveId(additiveId),
    );
  }

  CollectionReference<Map<String, dynamic>> _collection({
    required String contractId,
    required String additiveId,
  }) {
    return _additiveDoc(
      contractId: contractId,
      additiveId: additiveId,
    ).collection('schedules');
  }

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  Future<List<PhysicsFinanceData>> list({
    required String contractId,
    required String additiveId,
  }) async {
    final cleanContractId = _requireContractId(contractId);
    final cleanAdditiveId = _requireAdditiveId(additiveId);

    QuerySnapshot<Map<String, dynamic>> snapshot;

    try {
      snapshot = await _collection(
        contractId: cleanContractId,
        additiveId: cleanAdditiveId,
      ).orderBy('termOrder').get();
    } on FirebaseException catch (e) {
      if (e.code == 'failed-precondition' || e.code == 'not-found') {
        snapshot = await _collection(
          contractId: cleanContractId,
          additiveId: cleanAdditiveId,
        ).get();
      } else {
        rethrow;
      }
    }

    final list = snapshot.docs.map((doc) {
      return PhysicsFinanceData.fromSnapshot(
        contractId: cleanContractId,
        additiveId: cleanAdditiveId,
        snap: doc,
      );
    }).toList();

    list.sort(
          (a, b) => a.termOrder.compareTo(b.termOrder),
    );

    return list;
  }

  Future<PhysicsFinanceData?> get({
    required String contractId,
    required String additiveId,
    required int termOrder,
  }) async {
    final cleanContractId = _requireContractId(contractId);
    final cleanAdditiveId = _requireAdditiveId(additiveId);

    if (termOrder <= 0) {
      throw ArgumentError('termOrder deve ser maior que zero.');
    }

    final String id = PhysicsFinanceData.docIdForTerm(termOrder);

    final doc = await _collection(
      contractId: cleanContractId,
      additiveId: cleanAdditiveId,
    ).doc(id).get();

    if (!doc.exists) return null;

    return PhysicsFinanceData.fromSnapshot(
      contractId: cleanContractId,
      additiveId: cleanAdditiveId,
      snap: doc,
    );
  }

  Future<void> upsert({
    required String contractId,
    required String additiveId,
    required PhysicsFinanceData schedule,
    String? updatedBy,
  }) async {
    final cleanContractId = _requireContractId(contractId);
    final cleanAdditiveId = _requireAdditiveId(additiveId);

    if (schedule.termOrder <= 0) {
      throw ArgumentError('termOrder deve ser maior que zero.');
    }

    final String uid = updatedBy ?? _auth.currentUser?.uid ?? '';

    final String docId = schedule.id.trim().isNotEmpty
        ? schedule.id.trim()
        : PhysicsFinanceData.docIdForTerm(schedule.termOrder);

    final docRef = _collection(
      contractId: cleanContractId,
      additiveId: cleanAdditiveId,
    ).doc(docId);

    final payload = schedule.toMap(
      updatedByOverride: uid,
    )
      ..addAll(
        <String, dynamic>{
          'id': docId,
          'tenantId': tenantId,
          'companyId': tenantId,
          'contractId': cleanContractId,
          'additiveId': cleanAdditiveId,
          'termOrder': schedule.termOrder,
          'recordPath': docRef.path,
          'sourceCollectionModel': 'tenant_contract_additive_schedules',
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': uid,
        },
      );

    final snapshot = await docRef.get();

    if (!snapshot.exists || snapshot.data()?['createdAt'] == null) {
      payload['createdAt'] = FieldValue.serverTimestamp();
      payload['createdBy'] = uid;
    } else {
      payload.remove('createdAt');
      payload.remove('createdBy');
    }

    await docRef.set(
      payload,
      SetOptions(merge: true),
    );
  }

  Future<void> delete({
    required String contractId,
    required String additiveId,
    required String scheduleId,
  }) async {
    final cleanContractId = _requireContractId(contractId);
    final cleanAdditiveId = _requireAdditiveId(additiveId);
    final cleanScheduleId = _requireScheduleId(scheduleId);

    await _collection(
      contractId: cleanContractId,
      additiveId: cleanAdditiveId,
    ).doc(cleanScheduleId).delete();
  }
}