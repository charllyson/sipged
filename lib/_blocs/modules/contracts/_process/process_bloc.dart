import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';

import 'package:siged/_blocs/modules/contracts/_process/process_data.dart';
import 'package:siged/_blocs/system/permitions/module_permission.dart' as perms;

class ProcessBloc extends BlocBase {

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // -------------------- Streams de estado --------------------
  final _loadingController = BehaviorSubject<bool>();

  // -------------------- Helpers internos --------------------
  Map<String, bool> _norm(Map<String, bool>? m) => perms.normalizePermMap(m);


  Future<ProcessData?> getContractById(String id) async {
    try {
      final doc = await _db.collection('contracts').doc(id).get();
      if (!doc.exists) return null;
      final data = doc.data()!;
      return ProcessData.fromJson(data, id: doc.id);
    } catch (e) {
      return null;
    }
  }


  Future<ProcessData?> getSpecificContract({
    required String uidContract,
  }) async {
    final doc = await _db.collection('contracts').doc(uidContract).get();
    if (!doc.exists) return null;
    return ProcessData.fromDocument(snapshot: doc);
  }

  // -------------------- Permissões (ACL por documento) --------------------

  Future<void> updateContractPermissions({
    required String contractId,
    required String userId,
    required String permissionType, // 'read' | 'create' | 'edit' | 'delete' | 'approve'
    required bool value,
  }) async {
    try {
      _loadingController.add(true);
      await _db.collection('contracts').doc(contractId).update({
        'permissionContractId.$userId.$permissionType': value,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
      });
    } catch (e) {
      // você pode logar se quiser
    } finally {
      _loadingController.add(false);
    }
  }

  Future<void> setParticipantPerms({
    required String contractId,
    required String userId,
    required Map<String, bool> perms,
  }) async {
    try {
      _loadingController.add(true);
      final normalized = _norm(perms);
      await _db.collection('contracts').doc(contractId).update({
        'permissionContractId.$userId': normalized,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
      });
    } finally {
      _loadingController.add(false);
    }
  }

  /// Papel agora é **global**. Aqui gravamos apenas o rótulo em `participantsInfo`
  /// para exibição, **sem** resetar a ACL do documento.
  Future<void> setParticipantRole({
    required String contractId,
    required String userId,
    required String role,
  }) async {
    try {
      _loadingController.add(true);
      await _db.collection('contracts').doc(contractId).update({
        'participantsInfo.$userId.role': role,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
      });
    } finally {
      _loadingController.add(false);
    }
  }

  Future<void> saveContractPermissions(ProcessData contractData) async {
    if (contractData.id == null) return;
    try {
      _loadingController.add(true);
      await _db.collection('contracts').doc(contractData.id).update({
        'permissionContractId': contractData.permissionContractId
            .map((k, v) => MapEntry(k, _norm(v))),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
      });
    } catch (e) {
      // log se quiser
    } finally {
      _loadingController.add(false);
    }
  }


  // -------------------- Dispose --------------------
  @override
  void dispose() {
    _loadingController.close();
    super.dispose();
  }
}

/// Helpers relacionados a participantes do contrato
extension ContractParticipants on ProcessBloc {
  Future<void> addParticipant({
    required String contractId,
    required String userId,
    Map<String, bool>? permMap,
    Map<String, dynamic> meta = const {},
  }) async {
    try {
      _loadingController.add(true);

      final initPerms = _norm(permMap ?? perms.initialDocPerms());

      await _db.collection('contracts').doc(contractId).update({
        'permissionContractId.$userId': initPerms,
        if (meta.isNotEmpty) 'participantsInfo.$userId': meta,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
      });
    } finally {
      _loadingController.add(false);
    }
  }

  Future<void> removeParticipant({
    required String contractId,
    required String userId,
  }) async {
    try {
      _loadingController.add(true);
      await _db.collection('contracts').doc(contractId).update({
        'permissionContractId.$userId': FieldValue.delete(),
        'participantsInfo.$userId': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
      });
    } finally {
      _loadingController.add(false);
    }
  }

  Future<void> updateParticipantMeta({
    required String contractId,
    required String userId,
    required Map<String, dynamic> meta,
  }) async {
    try {
      _loadingController.add(true);
      await _db.collection('contracts').doc(contractId).update({
        'participantsInfo.$userId': meta,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
      });
    } finally {
      _loadingController.add(false);
    }
  }

  Future<void> setParticipantPermsExt({
    required String contractId,
    required String userId,
    required Map<String, bool> permsMap,
  }) async {
    await setParticipantPerms(
      contractId: contractId,
      userId: userId,
      perms: permsMap,
    );
  }

  Future<void> setParticipantRoleExt({
    required String contractId,
    required String userId,
    required String role,
  }) async {
    await setParticipantRole(
      contractId: contractId,
      userId: userId,
      role: role,
    );
  }
}
