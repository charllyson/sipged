// lib/_blocs/modules/contracts/hiring/0Stages/pipeline_progress.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/hiring_stages.dart';

class PipelineProgressService {
  final FirebaseFirestore db;
  final Map<String, String> stageCollectionMap;

  PipelineProgressService({
    FirebaseFirestore? db,
    Map<String, String>? stageCollectionMap,
  })  : db = db ?? FirebaseFirestore.instance,
        stageCollectionMap = stageCollectionMap ?? {
          // Ajuste aqui se algum nome de coleção for diferente no Firestore.
          HiringStageKey.dfd:          'dfd',
          HiringStageKey.etp:          'etp',
          HiringStageKey.tr:           'tr',
          HiringStageKey.cotacao:      'cotacao',
          HiringStageKey.edital:       'edital',
          HiringStageKey.habilitacao:  'habilitacao',
          HiringStageKey.dotacao:      'dotacao',
          HiringStageKey.minuta:       'minuta',
          HiringStageKey.parecer:      'parecer',
          HiringStageKey.publicacao:   'publicacao',
          HiringStageKey.arquivamento: 'arquivamento',
        };

  /// Resolve o *mesmo* documento que será usado em:
  /// - isStageCompleted
  ///
  /// Regra:
  /// 1) Tenta 'main'
  /// 2) Se não existir, usa o primeiro doc da coleção (para etapas antigas)
  Future<String?> resolveStageDocId({
    required String contractId,
    required String stageKey,
  }) async {
    final collectionName = stageCollectionMap[stageKey];
    if (collectionName == null) return null;

    final colRef = db
        .collection('contracts')
        .doc(contractId)
        .collection(collectionName);

    // 1) tenta 'main'
    final mainRef = colRef.doc('main');
    final mainSnap = await mainRef.get();
    if (mainSnap.exists) {
      return mainRef.id; // 'main'
    }

    // 2) fallback: primeiro doc
    final qs = await colRef.limit(1).get();
    if (qs.docs.isEmpty) return null;

    return qs.docs.first.id;
  }

  /// Lê o documento _resolvido_ e retorna (approved || completed).
  Future<bool> isStageCompleted({
    required String contractId,
    required String stageKey,
  }) async {
    final collectionName = stageCollectionMap[stageKey];
    if (collectionName == null) return false;

    final stageId = await resolveStageDocId(
      contractId: contractId,
      stageKey: stageKey,
    );
    if (stageId == null) return false;

    final ref = db
        .collection('contracts')
        .doc(contractId)
        .collection(collectionName)
        .doc(stageId);

    final snap = await ref.get();
    final data = snap.data();
    if (data == null) return false;

    final approval = (data['approval'] as Map?) ?? const {};
    final stage    = (data['stage'] as Map?) ?? const {};
    final approved  = approval['approved'] == true;
    final completed = stage['completed'] == true;

    return approved || completed;
  }

  /// Carrega o mapa completed para todas as etapas na ordem definida.
  Future<Map<String, bool>> loadAll({required String contractId}) async {
    final out = <String, bool>{};
    for (final k in HiringStageKey.ordered) {
      out[k] = await isStageCompleted(contractId: contractId, stageKey: k);
    }
    return out;
  }

  /// Compat legacy (usa resolveStageDocId).
  Future<String?> firstDocIdOfStage({
    required String contractId,
    required String stageKey,
  }) {
    return resolveStageDocId(contractId: contractId, stageKey: stageKey);
  }
}
