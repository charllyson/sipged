import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProgressRepository {
  final FirebaseFirestore db;
  ProgressRepository({FirebaseFirestore? db})
      : db = db ?? FirebaseFirestore.instance;

  /// Streama os flags de approved e completed do documento da etapa:
  /// contracts/{contractId}/{collectionName}/{stageId}
  Stream<Map<String, bool>> watchApprovalAndCompleted({
    required String contractId,
    required String collectionName,
    required String stageId,
  }) {
    final ref = db
        .collection('contracts')
        .doc(contractId)
        .collection(collectionName)
        .doc(stageId);

    return ref.snapshots().map((snap) {
      final data = snap.data() as Map<String, dynamic>?;

      bool approved = false;
      bool completed = false;

      if (data != null) {
        final approval = data['approval'];
        if (approval is Map<String, dynamic>) {
          approved = approval['approved'] == true;
        }
        final stage = data['stage'];
        if (stage is Map<String, dynamic>) {
          completed = stage['completed'] == true;
        }
      }

      return {'approved': approved, 'completed': completed};
    });
  }

  /// Marca a etapa como aprovada inicialmente (grava approvedBy).
  Future<void> approveStage({
    required String contractId,
    required String collectionName,
    required String stageId,
    required String approverUid,
    required String approverName,
  }) async {
    final ref = db
        .collection('contracts')
        .doc(contractId)
        .collection(collectionName)
        .doc(stageId);

    await db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data() as Map<String, dynamic>?;

      final hasCreatedAt =
          (data?['approval'] is Map<String, dynamic>) &&
              (data?['approval']['createdAt'] != null);

      final write = {
        'approval': {
          'approved': true,
          'approvedBy': {'uid': approverUid, 'name': approverName},
          'updatedAt': FieldValue.serverTimestamp(),
          if (!hasCreatedAt) 'createdAt': FieldValue.serverTimestamp(),
        },
        'updatedAt': FieldValue.serverTimestamp(),
      };

      tx.set(ref, write, SetOptions(merge: true));
    });
  }

  /// Opcional: atualiza metadados após já aprovado.
  Future<void> touchApproval({
    required String contractId,
    required String collectionName,
    required String stageId,
    required String updatedByUid,
    required String updatedByName,
  }) async {
    final ref = db
        .collection('contracts')
        .doc(contractId)
        .collection(collectionName)
        .doc(stageId);

    await ref.set({
      'approval': {
        'approved': true,
        'updatedBy': {'uid': updatedByUid, 'name': updatedByName},
        'updatedAt': FieldValue.serverTimestamp(),
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Define conclusão (mantendo estrutura nested para responsável/aprovador).
  Future<void> setCompleted({
    required String contractId,
    required String collectionName,
    required String stageId,
    required bool completed,
    String? responsibleUserId,
    String? approverUserId,
    String? responsibleName,
    String? approverName,
  }) async {
    final ref = db
        .collection('contracts')
        .doc(contractId)
        .collection(collectionName)
        .doc(stageId);

    await ref.set({
      'stage': {
        'completed': completed,
        'responsible': {
          'uid': responsibleUserId,
          'name': responsibleName,
        },
        'approver': {
          'uid': approverUserId,
          'name': approverName,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
