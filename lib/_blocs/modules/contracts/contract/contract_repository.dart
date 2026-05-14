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

  static const List<String> _permissionKeys = <String>[
    'read',
    'create',
    'edit',
    'delete',
    'approve',
  ];

  String _cleanTenantId(String tenantId) {
    final clean = tenantId.trim();

    if (clean.isEmpty) {
      throw ArgumentError('tenantId é obrigatório para acessar contratos.');
    }

    return clean;
  }

  String _cleanContractId(String contractId) {
    final clean = contractId.trim();

    if (clean.isEmpty) {
      throw ArgumentError('contractId é obrigatório para acessar contrato.');
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
    final cleanContractId = _cleanContractId(contractId);

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

  String? _resolveContractIdFromMapAndPath({
    required Map<String, dynamic> data,
    required String path,
  }) {
    final contractIdFromField = data['contractId']?.toString().trim();
    final uidContractFromField = data['uidContract']?.toString().trim();
    final uidcontractFromField = data['uidcontract']?.toString().trim();
    final idFromField = data['id']?.toString().trim();
    final contractIdFromPath = _contractIdFromPath(path);

    if (contractIdFromField != null && contractIdFromField.isNotEmpty) {
      return contractIdFromField;
    }

    if (uidContractFromField != null && uidContractFromField.isNotEmpty) {
      return uidContractFromField;
    }

    if (uidcontractFromField != null && uidcontractFromField.isNotEmpty) {
      return uidcontractFromField;
    }

    if (idFromField != null && idFromField.isNotEmpty) {
      return idFromField;
    }

    return contractIdFromPath;
  }

  Map<String, dynamic> _auditSetMap() {
    return <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
      if (_currentUid.trim().isNotEmpty) 'updatedBy': _currentUid.trim(),
    };
  }

  Map<Object, Object?> _auditUpdateMap() {
    return <Object, Object?>{
      'updatedAt': FieldValue.serverTimestamp(),
      if (_currentUid.trim().isNotEmpty) 'updatedBy': _currentUid.trim(),
    };
  }

  List<FieldPath> _legacyPermissionLiteralPaths(String userId) {
    final cleanUserId = userId.trim();

    if (cleanUserId.isEmpty) return const <FieldPath>[];

    return <FieldPath>[
      FieldPath(<String>['permissionContractId.$cleanUserId']),
      for (final key in _permissionKeys)
        FieldPath(<String>['permissionContractId.$cleanUserId.$key']),
    ];
  }

  List<FieldPath> _legacyParticipantLiteralPaths(String userId) {
    final cleanUserId = userId.trim();

    if (cleanUserId.isEmpty) return const <FieldPath>[];

    return <FieldPath>[
      FieldPath(<String>['participantsInfo.$cleanUserId']),
      FieldPath(<String>['participantsInfo.$cleanUserId.role']),
    ];
  }

  Map<Object, Object?> _legacyDeleteMapForUser(String userId) {
    final data = <Object, Object?>{};

    for (final path in _legacyPermissionLiteralPaths(userId)) {
      data[path] = FieldValue.delete();
    }

    for (final path in _legacyParticipantLiteralPaths(userId)) {
      data[path] = FieldValue.delete();
    }

    return data;
  }

  Future<void> _ensureContractParentDoc({
    required String tenantId,
    required String contractId,
    Map<String, dynamic> extraData = const <String, dynamic>{},
  }) async {
    final cleanTenantId = _cleanTenantId(tenantId);
    final cleanContractId = _cleanContractId(contractId);

    await _contractDoc(
      tenantId: cleanTenantId,
      contractId: cleanContractId,
    ).set(
      <String, dynamic>{
        'id': cleanContractId,
        'tenantId': cleanTenantId,
        'companyId': cleanTenantId,
        ...extraData,
        ..._auditSetMap(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> _updateContractFields({
    required String tenantId,
    required String contractId,
    required Map<Object, Object?> data,
  }) async {
    final cleanTenantId = _cleanTenantId(tenantId);
    final cleanContractId = _cleanContractId(contractId);

    await _ensureContractParentDoc(
      tenantId: cleanTenantId,
      contractId: cleanContractId,
    );

    await _contractDoc(
      tenantId: cleanTenantId,
      contractId: cleanContractId,
    ).update(
      <Object, Object?>{
        ...data,
        ..._auditUpdateMap(),
      },
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

      final contractId = _resolveContractIdFromMapAndPath(
        data: data,
        path: doc.reference.path,
      );

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

      final contractId = _resolveContractIdFromMapAndPath(
        data: data,
        path: doc.reference.path,
      );

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
    bool forceServer = false,
  }) async {
    final cleanTenantId = _cleanTenantId(tenantId);
    final cleanId = id.trim();

    if (cleanId.isEmpty) return null;

    final docRef = _contractDoc(
      tenantId: cleanTenantId,
      contractId: cleanId,
    );

    final doc = await docRef.get(
      forceServer ? const GetOptions(source: Source.server) : null,
    );

    if (doc.exists) {
      return ContractData.fromDocument(snapshot: doc);
    }

    final hiringDoc = await docRef.collection('hiring').doc('main').get(
      forceServer ? const GetOptions(source: Source.server) : null,
    );

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
    bool forceServer = false,
  }) async {
    final cleanTenantId = _cleanTenantId(tenantId);
    final cleanId = uidContract.trim();

    if (cleanId.isEmpty) return null;

    return getContractById(
      tenantId: cleanTenantId,
      id: cleanId,
      forceServer: forceServer,
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
    final cleanContractId = _cleanContractId(contractId);
    final cleanUserId = userId.trim();
    final cleanPermissionType = permissionType.trim();

    if (cleanUserId.isEmpty || cleanPermissionType.isEmpty) {
      return;
    }

    await _updateContractFields(
      tenantId: cleanTenantId,
      contractId: cleanContractId,
      data: <Object, Object?>{
        ..._legacyDeleteMapForUser(cleanUserId),
        FieldPath(
          <String>[
            'permissionContractId',
            cleanUserId,
            cleanPermissionType,
          ],
        ): value,
      },
    );
  }

  Future<void> setParticipantPerms({
    required String tenantId,
    required String contractId,
    required String userId,
    required Map<String, bool> permsMap,
  }) async {
    final cleanTenantId = _cleanTenantId(tenantId);
    final cleanContractId = _cleanContractId(contractId);
    final cleanUserId = userId.trim();

    if (cleanUserId.isEmpty) return;

    final normalized = _norm(permsMap);

    await _updateContractFields(
      tenantId: cleanTenantId,
      contractId: cleanContractId,
      data: <Object, Object?>{
        ..._legacyDeleteMapForUser(cleanUserId),
        FieldPath(
          <String>[
            'permissionContractId',
            cleanUserId,
          ],
        ): normalized,
      },
    );
  }

  Future<void> setParticipantRole({
    required String tenantId,
    required String contractId,
    required String userId,
    required String role,
  }) async {
    final cleanTenantId = _cleanTenantId(tenantId);
    final cleanContractId = _cleanContractId(contractId);
    final cleanUserId = userId.trim();
    final cleanRole = role.trim();

    if (cleanUserId.isEmpty || cleanRole.isEmpty) {
      return;
    }

    await _updateContractFields(
      tenantId: cleanTenantId,
      contractId: cleanContractId,
      data: <Object, Object?>{
        FieldPath(<String>['participantsInfo.$cleanUserId.role']):
        FieldValue.delete(),
        FieldPath(
          <String>[
            'participantsInfo',
            cleanUserId,
            'role',
          ],
        ): cleanRole,
      },
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
        ..._auditSetMap(),
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
    final cleanContractId = _cleanContractId(contractId);
    final cleanUserId = userId.trim();

    if (cleanUserId.isEmpty) return;

    final initPerms = _norm(
      permMap ?? SystemPermission.initialDocPerms(),
    );

    final cleanMeta = Map<String, dynamic>.from(meta);

    final role = cleanMeta['role']?.toString().trim();

    if (role == null || role.isEmpty) {
      cleanMeta['role'] = 'COLABORADOR';
    }

    await _updateContractFields(
      tenantId: cleanTenantId,
      contractId: cleanContractId,
      data: <Object, Object?>{
        ..._legacyDeleteMapForUser(cleanUserId),
        FieldPath(
          <String>[
            'permissionContractId',
            cleanUserId,
          ],
        ): initPerms,
        FieldPath(
          <String>[
            'participantsInfo',
            cleanUserId,
          ],
        ): cleanMeta,
      },
    );
  }

  Future<void> removeParticipant({
    required String tenantId,
    required String contractId,
    required String userId,
  }) async {
    final cleanTenantId = _cleanTenantId(tenantId);
    final cleanContractId = _cleanContractId(contractId);
    final cleanUserId = userId.trim();

    if (cleanUserId.isEmpty) return;

    await _updateContractFields(
      tenantId: cleanTenantId,
      contractId: cleanContractId,
      data: <Object, Object?>{
        ..._legacyDeleteMapForUser(cleanUserId),
        FieldPath(
          <String>[
            'permissionContractId',
            cleanUserId,
          ],
        ): FieldValue.delete(),
        FieldPath(
          <String>[
            'participantsInfo',
            cleanUserId,
          ],
        ): FieldValue.delete(),
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
    final cleanContractId = _cleanContractId(contractId);
    final cleanUserId = userId.trim();

    if (cleanUserId.isEmpty) return;

    await _updateContractFields(
      tenantId: cleanTenantId,
      contractId: cleanContractId,
      data: <Object, Object?>{
        FieldPath(<String>['participantsInfo.$cleanUserId']):
        FieldValue.delete(),
        FieldPath(
          <String>[
            'participantsInfo',
            cleanUserId,
          ],
        ): Map<String, dynamic>.from(meta),
      },
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