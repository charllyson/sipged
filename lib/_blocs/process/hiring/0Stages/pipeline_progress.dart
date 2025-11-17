import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:siged/_blocs/process/hiring/0Progress/hiring_stages.dart';

class PipelineProgressService {
  final FirebaseFirestore db;
  final Map<String, String> stageCollectionMap;

  PipelineProgressService({
    FirebaseFirestore? db,
    Map<String, String>? stageCollectionMap,
  })  : db = db ?? FirebaseFirestore.instance,
        stageCollectionMap = stageCollectionMap ?? {
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

  /// Lê o primeiro documento da coleção da etapa e retorna (approved || completed).
  Future<bool> isStageCompleted({
    required String contractId,
    required String stageKey,
  }) async {
    final collectionName = stageCollectionMap[stageKey];
    if (collectionName == null) return false;

    final qs = await db
        .collection('contracts')
        .doc(contractId)
        .collection(collectionName)
        .limit(1)
        .get();

    if (qs.docs.isEmpty) return false;

    final data = qs.docs.first.data();
    final approval = (data['approval'] as Map?) ?? const {};
    final stage    = (data['stage'] as Map?) ?? const {};
    final approved = approval['approved'] == true;
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

  /// Descobre o ID do primeiro documento de uma etapa (se existir). Útil para watch.
  Future<String?> firstDocIdOfStage({
    required String contractId,
    required String stageKey,
  }) async {
    final collectionName = stageCollectionMap[stageKey];
    if (collectionName == null) return null;

    final qs = await db
        .collection('contracts')
        .doc(contractId)
        .collection(collectionName)
        .limit(1)
        .get();

    if (qs.docs.isEmpty) return null;
    return qs.docs.first.id;
  }
}
