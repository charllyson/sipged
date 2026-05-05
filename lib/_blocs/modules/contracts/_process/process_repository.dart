import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'process_data.dart';

import 'package:sipged/_blocs/system/permission/permission_cubit.dart';

class ProcessRepository {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  ProcessRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _contracts {
    return _db.collection('contracts');
  }

  String get _currentUid => _auth.currentUser?.uid ?? '';

  Map<String, bool> _norm(dynamic raw) {
    return SystemPermission.normalizeDocPerms(raw);
  }

  Future<List<ProcessData>> getAllContracts() async {
    final snapshot = await _contracts.get();

    return snapshot.docs
        .map((doc) => ProcessData.fromDocument(snapshot: doc))
        .toList();
  }

  Future<ProcessData?> getContractById(String id) async {
    if (id.trim().isEmpty) return null;

    try {
      final doc = await _contracts.doc(id).get();

      if (!doc.exists) return null;

      return ProcessData.fromDocument(snapshot: doc);
    } catch (_) {
      return null;
    }
  }

  Future<ProcessData?> getSpecificContract({
    required String uidContract,
  }) async {
    if (uidContract.trim().isEmpty) return null;

    final doc = await _contracts.doc(uidContract).get();

    if (!doc.exists) return null;

    return ProcessData.fromDocument(snapshot: doc);
  }

  Future<void> updateContractPermissions({
    required String contractId,
    required String userId,
    required String permissionType,
    required bool value,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanUserId = userId.trim();
    final cleanPermissionType = permissionType.trim();

    if (cleanContractId.isEmpty ||
        cleanUserId.isEmpty ||
        cleanPermissionType.isEmpty) {
      return;
    }

    await _contracts.doc(cleanContractId).update({
      'permissionContractId.$cleanUserId.$cleanPermissionType': value,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _currentUid,
    });
  }

  Future<void> setParticipantPerms({
    required String contractId,
    required String userId,
    required Map<String, bool> permsMap,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanUserId = userId.trim();

    if (cleanContractId.isEmpty || cleanUserId.isEmpty) return;

    final normalized = _norm(permsMap);

    await _contracts.doc(cleanContractId).update({
      'permissionContractId.$cleanUserId': normalized,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _currentUid,
    });
  }

  Future<void> setParticipantRole({
    required String contractId,
    required String userId,
    required String role,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanUserId = userId.trim();

    if (cleanContractId.isEmpty || cleanUserId.isEmpty) return;

    await _contracts.doc(cleanContractId).update({
      'participantsInfo.$cleanUserId.role': role.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _currentUid,
    });
  }

  Future<void> saveContractPermissions(ProcessData contractData) async {
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

    await _contracts.doc(contractId).update({
      'permissionContractId': normalizedMap,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _currentUid,
    });
  }

  Future<void> addParticipant({
    required String contractId,
    required String userId,
    Map<String, bool>? permMap,
    Map<String, dynamic> meta = const {},
  }) async {
    final cleanContractId = contractId.trim();
    final cleanUserId = userId.trim();

    if (cleanContractId.isEmpty || cleanUserId.isEmpty) return;

    final initPerms = _norm(
      permMap ?? SystemPermission.initialDocPerms(),
    );

    await _contracts.doc(cleanContractId).update({
      'permissionContractId.$cleanUserId': initPerms,
      if (meta.isNotEmpty) 'participantsInfo.$cleanUserId': meta,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _currentUid,
    });
  }

  Future<void> removeParticipant({
    required String contractId,
    required String userId,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanUserId = userId.trim();

    if (cleanContractId.isEmpty || cleanUserId.isEmpty) return;

    await _contracts.doc(cleanContractId).update({
      'permissionContractId.$cleanUserId': FieldValue.delete(),
      'participantsInfo.$cleanUserId': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _currentUid,
    });
  }

  Future<void> updateParticipantMeta({
    required String contractId,
    required String userId,
    required Map<String, dynamic> meta,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanUserId = userId.trim();

    if (cleanContractId.isEmpty || cleanUserId.isEmpty) return;

    await _contracts.doc(cleanContractId).update({
      'participantsInfo.$cleanUserId': meta,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _currentUid,
    });
  }

  Future<void> delete(String id) async {
    final cleanId = id.trim();

    if (cleanId.isEmpty) return;

    await _contracts.doc(cleanId).delete();
  }
}