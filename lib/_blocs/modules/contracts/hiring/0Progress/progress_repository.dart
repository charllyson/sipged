// lib/_blocs/modules/contracts/hiring/0Stages/progress_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class ProgressRepository {
  ProgressRepository({FirebaseFirestore? db})
      : db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore db;

  static const String kStageDocId = 'main';

  // ===========================================================================
  // CHAVES DOS ESTÁGIOS
  // ===========================================================================

  static const String stageDfd = 'dfd';
  static const String stageEtp = 'etp';
  static const String stageTr = 'tr';
  static const String stageCotacao = 'cotacao';
  static const String stageEdital = 'edital';
  static const String stageHabilitacao = 'habilitacao';
  static const String stageDotacao = 'dotacao';
  static const String stageMinuta = 'minuta';
  static const String stageParecer = 'parecer';
  static const String stagePublicacao = 'publicacao';
  static const String stageArquivamento = 'arquivamento';

  static const List<String> orderedStages = <String>[
    stageDfd,
    stageEtp,
    stageTr,
    stageCotacao,
    stageEdital,
    stageHabilitacao,
    stageDotacao,
    stageMinuta,
    stageParecer,
    stagePublicacao,
    stageArquivamento,
  ];

  static const Map<String, String> defaultStageCollectionMap =
  <String, String>{
    stageDfd: 'dfd',
    stageEtp: 'etp',
    stageTr: 'tr',
    stageCotacao: 'cotacao',
    stageEdital: 'edital',
    stageHabilitacao: 'habilitacao',
    stageDotacao: 'dotacao',
    stageMinuta: 'minuta',
    stageParecer: 'parecer',
    stagePublicacao: 'publicacao',
    stageArquivamento: 'arquivamento',
  };

  String? collectionNameOf(String stageKey) {
    return defaultStageCollectionMap[stageKey];
  }

  DocumentReference<Map<String, dynamic>> stageDoc({
    required String contractId,
    required String collectionName,
  }) {
    return db
        .collection('contracts')
        .doc(contractId)
        .collection(collectionName)
        .doc(kStageDocId);
  }

  DocumentReference<Map<String, dynamic>>? stageDocByKey({
    required String contractId,
    required String stageKey,
  }) {
    final collectionName = collectionNameOf(stageKey);
    if (collectionName == null) return null;

    return stageDoc(
      contractId: contractId,
      collectionName: collectionName,
    );
  }

  // ===========================================================================
  // LEITURA DE PROGRESSO
  // ===========================================================================

  Stream<Map<String, bool>> watchApprovalAndCompleted({
    required String contractId,
    required String collectionName,
  }) {
    final ref = stageDoc(
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
        } else if (approval is Map) {
          approved = approval['approved'] == true;
        }

        final stage = data['stage'];

        if (stage is Map<String, dynamic>) {
          completed = stage['completed'] == true;
        } else if (stage is Map) {
          completed = stage['completed'] == true;
        }
      }

      return <String, bool>{
        'approved': approved,
        'completed': completed,
      };
    });
  }

  Stream<Map<String, bool>> watchStageByKey({
    required String contractId,
    required String stageKey,
  }) {
    final collectionName = collectionNameOf(stageKey);

    if (collectionName == null) {
      return Stream<Map<String, bool>>.value(
        const <String, bool>{
          'approved': false,
          'completed': false,
        },
      );
    }

    return watchApprovalAndCompleted(
      contractId: contractId,
      collectionName: collectionName,
    );
  }

  Future<bool> isStageCompleted({
    required String contractId,
    required String stageKey,
  }) async {
    final ref = stageDocByKey(
      contractId: contractId,
      stageKey: stageKey,
    );

    if (ref == null) return false;

    final snap = await ref.get();
    final data = snap.data();

    if (data == null) return false;

    final approvalRaw = data['approval'];
    final stageRaw = data['stage'];

    final approval = approvalRaw is Map
        ? Map<String, dynamic>.from(approvalRaw)
        : const <String, dynamic>{};

    final stage = stageRaw is Map
        ? Map<String, dynamic>.from(stageRaw)
        : const <String, dynamic>{};

    final approved = approval['approved'] == true;
    final completed = stage['completed'] == true;

    return approved || completed;
  }

  Future<Map<String, bool>> loadAllStages({
    required String contractId,
  }) async {
    final out = <String, bool>{};

    for (final stageKey in orderedStages) {
      out[stageKey] = await isStageCompleted(
        contractId: contractId,
        stageKey: stageKey,
      );
    }

    return out;
  }

  // ===========================================================================
  // ESCRITA DE APROVAÇÃO / CONCLUSÃO
  // ===========================================================================

  Future<void> approveStage({
    required String contractId,
    required String collectionName,
    required String approverUid,
    required String approverName,
  }) async {
    final ref = stageDoc(
      contractId: contractId,
      collectionName: collectionName,
    );

    await db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data();

      final approvalRaw = data?['approval'];
      final approval = approvalRaw is Map
          ? Map<String, dynamic>.from(approvalRaw)
          : const <String, dynamic>{};

      final hasCreatedAt = approval['createdAt'] != null;

      tx.set(
        ref,
        <String, dynamic>{
          'approval': <String, dynamic>{
            'approved': true,
            'approvedBy': <String, dynamic>{
              'uid': approverUid,
              'name': approverName,
            },
            'updatedAt': FieldValue.serverTimestamp(),
            if (!hasCreatedAt) 'createdAt': FieldValue.serverTimestamp(),
          },
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }

  Future<void> touchApproval({
    required String contractId,
    required String collectionName,
    required String updatedByUid,
    required String updatedByName,
  }) async {
    final ref = stageDoc(
      contractId: contractId,
      collectionName: collectionName,
    );

    await ref.set(
      <String, dynamic>{
        'approval': <String, dynamic>{
          'approved': true,
          'updatedBy': <String, dynamic>{
            'uid': updatedByUid,
            'name': updatedByName,
          },
          'updatedAt': FieldValue.serverTimestamp(),
        },
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> setCompleted({
    required String contractId,
    required String collectionName,
    required bool completed,
    String? responsibleUserId,
    String? approverUserId,
    String? responsibleName,
    String? approverName,
  }) async {
    final ref = stageDoc(
      contractId: contractId,
      collectionName: collectionName,
    );

    await ref.set(
      <String, dynamic>{
        'stage': <String, dynamic>{
          'completed': completed,
          'responsible': <String, dynamic>{
            'uid': responsibleUserId,
            'name': responsibleName,
          },
          'approver': <String, dynamic>{
            'uid': approverUserId,
            'name': approverName,
          },
          'updatedAt': FieldValue.serverTimestamp(),
        },
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}