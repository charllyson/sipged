// lib/_blocs/modules/contracts/measurement/physics_finance/physics_finance_repository.dart

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
  // Tenant
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

    if (id == null || id.isEmpty) {
      return null;
    }

    return id;
  }

  bool get hasTenant {
    final id = _tenantId?.trim();

    return id != null && id.isNotEmpty;
  }

  void setActiveTenantId(String? value) {
    final clean = value?.trim();
    final next = clean == null || clean.isEmpty ? null : clean;

    if (_tenantId == next) {
      return;
    }

    _tenantId = next;
  }

  // ---------------------------------------------------------------------------
  // Validators
  // ---------------------------------------------------------------------------

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

  int _requireTermOrder(int termOrder) {
    if (termOrder <= 0) {
      throw ArgumentError('termOrder deve ser maior que zero.');
    }

    return termOrder;
  }

  // ---------------------------------------------------------------------------
  // References
  // ---------------------------------------------------------------------------

  CollectionReference<Map<String, dynamic>> _contractsCollection() {
    return _db.collection('tenants').doc(tenantId).collection('contracts');
  }

  DocumentReference<Map<String, dynamic>> _contractDoc(String contractId) {
    return _contractsCollection().doc(
      _requireContractId(contractId),
    );
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

  DocumentReference<Map<String, dynamic>> _scheduleDoc({
    required String contractId,
    required String additiveId,
    required String scheduleId,
  }) {
    return _collection(
      contractId: contractId,
      additiveId: additiveId,
    ).doc(
      _requireScheduleId(scheduleId),
    );
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

    final List<PhysicsFinanceData> schedules = snapshot.docs.map((doc) {
      return PhysicsFinanceData.fromSnapshot(
        contractId: cleanContractId,
        additiveId: cleanAdditiveId,
        snap: doc,
      );
    }).toList();

    schedules.sort(
          (a, b) => a.termOrder.compareTo(b.termOrder),
    );

    return schedules;
  }

  Future<PhysicsFinanceData?> get({
    required String contractId,
    required String additiveId,
    required int termOrder,
  }) async {
    final cleanContractId = _requireContractId(contractId);
    final cleanAdditiveId = _requireAdditiveId(additiveId);
    final cleanTermOrder = _requireTermOrder(termOrder);

    final String scheduleId = PhysicsFinanceData.docIdForTerm(cleanTermOrder);

    final doc = await _scheduleDoc(
      contractId: cleanContractId,
      additiveId: cleanAdditiveId,
      scheduleId: scheduleId,
    ).get();

    if (!doc.exists) {
      return null;
    }

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
    final cleanTermOrder = _requireTermOrder(schedule.termOrder);

    final String uid = updatedBy?.trim().isNotEmpty == true
        ? updatedBy!.trim()
        : _auth.currentUser?.uid ?? '';

    final String scheduleId = schedule.id.trim().isNotEmpty
        ? schedule.id.trim()
        : PhysicsFinanceData.docIdForTerm(cleanTermOrder);

    final DocumentReference<Map<String, dynamic>> docRef = _scheduleDoc(
      contractId: cleanContractId,
      additiveId: cleanAdditiveId,
      scheduleId: scheduleId,
    );

    final DocumentSnapshot<Map<String, dynamic>> snapshot = await docRef.get();

    final bool creating = !snapshot.exists ||
        snapshot.data()?['createdAt'] == null;

    final PhysicsFinanceData normalizedSchedule = schedule.copyWith(
      id: scheduleId,
      contractId: cleanContractId,
      additiveId: cleanAdditiveId,
      termOrder: cleanTermOrder,
    );

    final Map<String, dynamic> payload = normalizedSchedule.toMap(
      tenantId: tenantId,
      recordPath: docRef.path,
      updatedByOverride: uid,
      includeCreatedFields: creating,
      createdByOverride: uid,
    );

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

    await _scheduleDoc(
      contractId: cleanContractId,
      additiveId: cleanAdditiveId,
      scheduleId: cleanScheduleId,
    ).delete();
  }

  Future<void> deleteByTerm({
    required String contractId,
    required String additiveId,
    required int termOrder,
  }) async {
    final cleanTermOrder = _requireTermOrder(termOrder);

    await delete(
      contractId: contractId,
      additiveId: additiveId,
      scheduleId: PhysicsFinanceData.docIdForTerm(cleanTermOrder),
    );
  }
}