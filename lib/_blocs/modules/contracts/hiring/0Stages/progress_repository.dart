// lib/_blocs/modules/contracts/hiring/0Stages/progress_repository.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProgressRepository {
  final FirebaseFirestore db;
  ProgressRepository({FirebaseFirestore? db})
      : db = db ?? FirebaseFirestore.instance;

  static const String kStageDocId = 'main';

  /// Helper: retorna o doc fixo `contracts/{contractId}/{collectionName}/main`
  DocumentReference<Map<String, dynamic>> _stageDoc({
    required String contractId,
    required String collectionName,
  }) {
    return db
        .collection('contracts')
        .doc(contractId)
        .collection(collectionName)
        .doc(kStageDocId);
  }

  /// Streama os flags de approved e completed do doc fixo:
  ///   contracts/{contractId}/{collectionName}/main
  Stream<Map<String, bool>> watchApprovalAndCompleted({
    required String contractId,
    required String collectionName,
  }) {
    final ref = _stageDoc(
      contractId: contractId,
      collectionName: collectionName,
    );

    return ref.snapshots().map((snap) {
      final data = snap.data();

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

  /// Versão "auto" agora só delega para o doc `main`
  Stream<Map<String, bool>> watchStageAutoDoc({
    required String contractId,
    required String collectionName,
  }) {
    return watchApprovalAndCompleted(
      contractId: contractId,
      collectionName: collectionName,
    );
  }

  /// Marca a etapa como aprovada inicialmente (grava approvedBy) em `main`.
  Future<void> approveStage({
    required String contractId,
    required String collectionName,
    required String approverUid,
    required String approverName,
  }) async {
    final ref = _stageDoc(
      contractId: contractId,
      collectionName: collectionName,
    );

    await db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data();

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

  /// Opcional: atualiza metadados após já aprovado (sempre em `main`).
  Future<void> touchApproval({
    required String contractId,
    required String collectionName,
    required String updatedByUid,
    required String updatedByName,
  }) async {
    final ref = _stageDoc(
      contractId: contractId,
      collectionName: collectionName,
    );

    await ref.set({
      'approval': {
        'approved': true,
        'updatedBy': {'uid': updatedByUid, 'name': updatedByName},
        'updatedAt': FieldValue.serverTimestamp(),
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Define conclusão (mantendo estrutura nested para responsável/aprovador)
  /// sempre no doc `main`.
  Future<void> setCompleted({
    required String contractId,
    required String collectionName,
    required bool completed,
    String? responsibleUserId,
    String? approverUserId,
    String? responsibleName,
    String? approverName,
  }) async {
    final ref = _stageDoc(
      contractId: contractId,
      collectionName: collectionName,
    );

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
