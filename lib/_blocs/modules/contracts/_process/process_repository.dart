import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'process_data.dart';
import 'package:sipged/_blocs/system/module/module_permission.dart' as perms;

class ProcessRepository {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  ProcessRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _contracts =>
      _db.collection('contracts');

  Map<String, bool> _norm(Map<String, bool>? map) =>
      perms.normalizePermMap(map);

  String get _currentUid => _auth.currentUser?.uid ?? '';

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
    await _contracts.doc(contractId).update({
      'permissionContractId.$userId.$permissionType': value,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _currentUid,
    });
  }

  Future<void> setParticipantPerms({
    required String contractId,
    required String userId,
    required Map<String, bool> permsMap,
  }) async {
    final normalized = _norm(permsMap);

    await _contracts.doc(contractId).update({
      'permissionContractId.$userId': normalized,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _currentUid,
    });
  }

  Future<void> setParticipantRole({
    required String contractId,
    required String userId,
    required String role,
  }) async {
    await _contracts.doc(contractId).update({
      'participantsInfo.$userId.role': role,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _currentUid,
    });
  }

  Future<void> saveContractPermissions(ProcessData contractData) async {
    final contractId = contractData.id;
    if (contractId == null || contractId.isEmpty) return;

    final normalizedMap = contractData.permissionContractId.map(
          (k, v) => MapEntry(k, _norm(v)),
    );

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
    final initPerms = _norm(permMap ?? perms.initialDocPerms());

    await _contracts.doc(contractId).update({
      'permissionContractId.$userId': initPerms,
      if (meta.isNotEmpty) 'participantsInfo.$userId': meta,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _currentUid,
    });
  }

  Future<void> removeParticipant({
    required String contractId,
    required String userId,
  }) async {
    await _contracts.doc(contractId).update({
      'permissionContractId.$userId': FieldValue.delete(),
      'participantsInfo.$userId': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _currentUid,
    });
  }

  Future<void> updateParticipantMeta({
    required String contractId,
    required String userId,
    required Map<String, dynamic> meta,
  }) async {
    await _contracts.doc(contractId).update({
      'participantsInfo.$userId': meta,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _currentUid,
    });
  }

  Future<void> delete(String id) async {
    await _contracts.doc(id).delete();
  }
}