import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'contract_data.dart';

import 'package:sipged/_blocs/system/permission/permission_cubit.dart';

class ContractRepository {
  ContractRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  String get _currentUid => _auth.currentUser?.uid ?? '';

  String _cleanTenantId(String tenantId) {
    final clean = tenantId.trim();

    if (clean.isEmpty) {
      throw ArgumentError('tenantId é obrigatório para acessar contratos.');
    }

    return clean;
  }

  CollectionReference<Map<String, dynamic>> _contractsRef(String tenantId) {
    final cleanTenantId = _cleanTenantId(tenantId);

    return _db
        .collection('tenants')
        .doc(cleanTenantId)
        .collection('contracts');
  }

  DocumentReference<Map<String, dynamic>> _contractDoc({
    required String tenantId,
    required String contractId,
  }) {
    final cleanTenantId = _cleanTenantId(tenantId);
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) {
      throw ArgumentError('contractId é obrigatório para acessar contrato.');
    }

    return _contractsRef(cleanTenantId).doc(cleanContractId);
  }

  Map<String, bool> _norm(dynamic raw) {
    return SystemPermission.normalizeDocPerms(raw);
  }

  String? _contractIdFromPath(String path) {
    final parts = path.split('/');

    for (var i = 0; i < parts.length - 1; i++) {
      if (parts[i] != 'contracts') continue;

      final id = parts[i + 1].trim();

      if (id.isNotEmpty) {
        return id;
      }
    }

    return null;
  }

  Future<void> _ensureContractParentDoc({
    required String tenantId,
    required String contractId,
    Map<String, dynamic> extraData = const <String, dynamic>{},
  }) async {
    final cleanTenantId = _cleanTenantId(tenantId);
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) {
      throw ArgumentError('contractId é obrigatório para criar contrato.');
    }

    await _contractDoc(
      tenantId: cleanTenantId,
      contractId: cleanContractId,
    ).set(
      <String, dynamic>{
        'id': cleanContractId,
        'tenantId': cleanTenantId,
        'companyId': cleanTenantId,
        ...extraData,
        'updatedAt': FieldValue.serverTimestamp(),
        if (_currentUid.trim().isNotEmpty) 'updatedBy': _currentUid,
      },
      SetOptions(merge: true),
    );
  }

  Future<List<ContractData>> getAllContracts({
    required String tenantId,
  }) async {
    final cleanTenantId = _cleanTenantId(tenantId);
    final byId = <String, ContractData>{};

    final snapshot = await _contractsRef(cleanTenantId).get();

    for (final doc in snapshot.docs) {
      try {
        final contract = ContractData.fromDocument(snapshot: doc);
        final id = contract.id?.trim();

        if (id != null && id.isNotEmpty) {
          byId[id] = contract;
        }
      } catch (_) {
        continue;
      }
    }

    final hiringSnapshot = await _db
        .collectionGroup('hiring')
        .where('tenantId', isEqualTo: cleanTenantId)
        .get();

    for (final doc in hiringSnapshot.docs) {
      final data = doc.data();

      final contractIdFromField = data['contractId']?.toString().trim();
      final uidContractFromField = data['uidContract']?.toString().trim();
      final uidcontractFromField = data['uidcontract']?.toString().trim();
      final contractIdFromPath = _contractIdFromPath(doc.reference.path);

      final contractId =
      contractIdFromField != null && contractIdFromField.isNotEmpty
          ? contractIdFromField
          : uidContractFromField != null && uidContractFromField.isNotEmpty
          ? uidContractFromField
          : uidcontractFromField != null &&
          uidcontractFromField.isNotEmpty
          ? uidcontractFromField
          : contractIdFromPath;

      if (contractId == null || contractId.trim().isEmpty) {
        continue;
      }

      final cleanContractId = contractId.trim();

      if (byId.containsKey(cleanContractId)) {
        continue;
      }

      byId[cleanContractId] = ContractData.fromJson(
        <String, dynamic>{
          ...data,
          'id': cleanContractId,
        },
        id: cleanContractId,
      );
    }

    final dfdSnapshot = await _db
        .collectionGroup('dfd')
        .where('tenantId', isEqualTo: cleanTenantId)
        .get();

    for (final doc in dfdSnapshot.docs) {
      final data = doc.data();

      final contractIdFromField = data['contractId']?.toString().trim();
      final uidContractFromField = data['uidContract']?.toString().trim();
      final uidcontractFromField = data['uidcontract']?.toString().trim();
      final contractIdFromPath = _contractIdFromPath(doc.reference.path);

      final contractId =
      contractIdFromField != null && contractIdFromField.isNotEmpty
          ? contractIdFromField
          : uidContractFromField != null && uidContractFromField.isNotEmpty
          ? uidContractFromField
          : uidcontractFromField != null &&
          uidcontractFromField.isNotEmpty
          ? uidcontractFromField
          : contractIdFromPath;

      if (contractId == null || contractId.trim().isEmpty) {
        continue;
      }

      final cleanContractId = contractId.trim();

      if (byId.containsKey(cleanContractId)) {
        continue;
      }

      byId[cleanContractId] = ContractData.fromJson(
        <String, dynamic>{
          ...data,
          'id': cleanContractId,
        },
        id: cleanContractId,
      );
    }

    final list = byId.values.toList(growable: false)
      ..sort((a, b) => (a.id ?? '').compareTo(b.id ?? ''));

    return list;
  }

  Future<ContractData?> getContractById({
    required String tenantId,
    required String id,
  }) async {
    final cleanTenantId = _cleanTenantId(tenantId);
    final cleanId = id.trim();

    if (cleanId.isEmpty) return null;

    final doc = await _contractDoc(
      tenantId: cleanTenantId,
      contractId: cleanId,
    ).get();

    if (doc.exists) {
      return ContractData.fromDocument(snapshot: doc);
    }

    final hiringDoc = await _contractDoc(
      tenantId: cleanTenantId,
      contractId: cleanId,
    ).collection('hiring').doc('main').get();

    if (hiringDoc.exists) {
      final data = hiringDoc.data() ?? const <String, dynamic>{};

      return ContractData.fromJson(
        <String, dynamic>{
          ...data,
          'id': cleanId,
        },
        id: cleanId,
      );
    }

    return null;
  }

  Future<ContractData?> getSpecificContract({
    required String tenantId,
    required String uidContract,
  }) async {
    final cleanTenantId = _cleanTenantId(tenantId);
    final cleanId = uidContract.trim();

    if (cleanId.isEmpty) return null;

    final doc = await _contractDoc(
      tenantId: cleanTenantId,
      contractId: cleanId,
    ).get();

    if (doc.exists) {
      return ContractData.fromDocument(snapshot: doc);
    }

    final hiringDoc = await _contractDoc(
      tenantId: cleanTenantId,
      contractId: cleanId,
    ).collection('hiring').doc('main').get();

    if (!hiringDoc.exists) return null;

    final data = hiringDoc.data() ?? const <String, dynamic>{};

    return ContractData.fromJson(
      <String, dynamic>{
        ...data,
        'id': cleanId,
      },
      id: cleanId,
    );
  }

  Future<void> updateContractPermissions({
    required String tenantId,
    required String contractId,
    required String userId,
    required String permissionType,
    required bool value,
  }) async {
    final cleanTenantId = _cleanTenantId(tenantId);
    final cleanContractId = contractId.trim();
    final cleanUserId = userId.trim();
    final cleanPermissionType = permissionType.trim();

    if (cleanContractId.isEmpty ||
        cleanUserId.isEmpty ||
        cleanPermissionType.isEmpty) {
      return;
    }

    await _ensureContractParentDoc(
      tenantId: cleanTenantId,
      contractId: cleanContractId,
    );

    await _contractDoc(
      tenantId: cleanTenantId,
      contractId: cleanContractId,
    ).set(
      <String, dynamic>{
        'permissionContractId.$cleanUserId.$cleanPermissionType': value,
        'updatedAt': FieldValue.serverTimestamp(),
        if (_currentUid.trim().isNotEmpty) 'updatedBy': _currentUid,
      },
      SetOptions(merge: true),
    );
  }

  Future<void> setParticipantPerms({
    required String tenantId,
    required String contractId,
    required String userId,
    required Map<String, bool> permsMap,
  }) async {
    final cleanTenantId = _cleanTenantId(tenantId);
    final cleanContractId = contractId.trim();
    final cleanUserId = userId.trim();

    if (cleanContractId.isEmpty || cleanUserId.isEmpty) return;

    final normalized = _norm(permsMap);

    await _ensureContractParentDoc(
      tenantId: cleanTenantId,
      contractId: cleanContractId,
    );

    await _contractDoc(
      tenantId: cleanTenantId,
      contractId: cleanContractId,
    ).set(
      <String, dynamic>{
        'permissionContractId.$cleanUserId': normalized,
        'updatedAt': FieldValue.serverTimestamp(),
        if (_currentUid.trim().isNotEmpty) 'updatedBy': _currentUid,
      },
      SetOptions(merge: true),
    );
  }

  Future<void> setParticipantRole({
    required String tenantId,
    required String contractId,
    required String userId,
    required String role,
  }) async {
    final cleanTenantId = _cleanTenantId(tenantId);
    final cleanContractId = contractId.trim();
    final cleanUserId = userId.trim();
    final cleanRole = role.trim();

    if (cleanContractId.isEmpty || cleanUserId.isEmpty || cleanRole.isEmpty) {
      return;
    }

    await _ensureContractParentDoc(
      tenantId: cleanTenantId,
      contractId: cleanContractId,
    );

    await _contractDoc(
      tenantId: cleanTenantId,
      contractId: cleanContractId,
    ).set(
      <String, dynamic>{
        'participantsInfo.$cleanUserId.role': cleanRole,
        'updatedAt': FieldValue.serverTimestamp(),
        if (_currentUid.trim().isNotEmpty) 'updatedBy': _currentUid,
      },
      SetOptions(merge: true),
    );
  }

  Future<void> saveContractPermissions({
    required String tenantId,
    required ContractData contractData,
  }) async {
    final cleanTenantId = _cleanTenantId(tenantId);
    final contractId = contractData.id?.trim();

    if (contractId == null || contractId.isEmpty) return;

    final normalizedMap = contractData.permissionContractId.map(
          (uid, rawPerms) {
        return MapEntry(
          uid.trim(),
          _norm(rawPerms),
        );
      },
    )..removeWhere((uid, _) => uid.isEmpty);

    await _ensureContractParentDoc(
      tenantId: cleanTenantId,
      contractId: contractId,
    );

    await _contractDoc(
      tenantId: cleanTenantId,
      contractId: contractId,
    ).set(
      <String, dynamic>{
        'permissionContractId': normalizedMap,
        'updatedAt': FieldValue.serverTimestamp(),
        if (_currentUid.trim().isNotEmpty) 'updatedBy': _currentUid,
      },
      SetOptions(merge: true),
    );
  }

  Future<void> addParticipant({
    required String tenantId,
    required String contractId,
    required String userId,
    Map<String, bool>? permMap,
    Map<String, dynamic> meta = const {},
  }) async {
    final cleanTenantId = _cleanTenantId(tenantId);
    final cleanContractId = contractId.trim();
    final cleanUserId = userId.trim();

    if (cleanContractId.isEmpty || cleanUserId.isEmpty) return;

    final initPerms = _norm(
      permMap ?? SystemPermission.initialDocPerms(),
    );

    await _ensureContractParentDoc(
      tenantId: cleanTenantId,
      contractId: cleanContractId,
    );

    await _contractDoc(
      tenantId: cleanTenantId,
      contractId: cleanContractId,
    ).set(
      <String, dynamic>{
        'permissionContractId.$cleanUserId': initPerms,
        if (meta.isNotEmpty) 'participantsInfo.$cleanUserId': meta,
        'updatedAt': FieldValue.serverTimestamp(),
        if (_currentUid.trim().isNotEmpty) 'updatedBy': _currentUid,
      },
      SetOptions(merge: true),
    );
  }

  Future<void> removeParticipant({
    required String tenantId,
    required String contractId,
    required String userId,
  }) async {
    final cleanTenantId = _cleanTenantId(tenantId);
    final cleanContractId = contractId.trim();
    final cleanUserId = userId.trim();

    if (cleanContractId.isEmpty || cleanUserId.isEmpty) return;

    await _contractDoc(
      tenantId: cleanTenantId,
      contractId: cleanContractId,
    ).update(
      <String, dynamic>{
        'permissionContractId.$cleanUserId': FieldValue.delete(),
        'participantsInfo.$cleanUserId': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
        if (_currentUid.trim().isNotEmpty) 'updatedBy': _currentUid,
      },
    );
  }

  Future<void> updateParticipantMeta({
    required String tenantId,
    required String contractId,
    required String userId,
    required Map<String, dynamic> meta,
  }) async {
    final cleanTenantId = _cleanTenantId(tenantId);
    final cleanContractId = contractId.trim();
    final cleanUserId = userId.trim();

    if (cleanContractId.isEmpty || cleanUserId.isEmpty) return;

    await _ensureContractParentDoc(
      tenantId: cleanTenantId,
      contractId: cleanContractId,
    );

    await _contractDoc(
      tenantId: cleanTenantId,
      contractId: cleanContractId,
    ).set(
      <String, dynamic>{
        'participantsInfo.$cleanUserId': meta,
        'updatedAt': FieldValue.serverTimestamp(),
        if (_currentUid.trim().isNotEmpty) 'updatedBy': _currentUid,
      },
      SetOptions(merge: true),
    );
  }

  Future<void> delete({
    required String tenantId,
    required String id,
  }) async {
    final cleanTenantId = _cleanTenantId(tenantId);
    final cleanId = id.trim();

    if (cleanId.isEmpty) return;

    await _contractDoc(
      tenantId: cleanTenantId,
      contractId: cleanId,
    ).delete();
  }
}