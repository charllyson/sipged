import 'package:cloud_firestore/cloud_firestore.dart';

class ProgressRepository {
  ProgressRepository({
    FirebaseFirestore? db,
    required String tenantId,
  })  : db = db ?? FirebaseFirestore.instance,
        _tenantId = _validateTenantId(tenantId);

  final FirebaseFirestore db;
  final String _tenantId;

  String get tenantId => _tenantId;

  static const String kStageDocId = 'main';

  static String _validateTenantId(String tenantId) {
    final cleanTenantId = tenantId.trim();

    if (cleanTenantId.isEmpty) {
      throw ArgumentError('tenantId é obrigatório para ProgressRepository.');
    }

    return cleanTenantId;
  }

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
    return defaultStageCollectionMap[stageKey.trim()];
  }

  // ===========================================================================
  // CAMINHO TENANTIZADO
  // ===========================================================================

  CollectionReference<Map<String, dynamic>> _contractsCol() {
    return db.collection('tenants').doc(tenantId).collection('contracts');
  }

  DocumentReference<Map<String, dynamic>> _contractDoc(String contractId) {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) {
      throw ArgumentError('contractId não informado.');
    }

    return _contractsCol().doc(cleanContractId);
  }

  DocumentReference<Map<String, dynamic>> _hiringMainDoc(String contractId) {
    return _contractDoc(contractId).collection('hiring').doc('main');
  }

  DocumentReference<Map<String, dynamic>> stageDoc({
    required String contractId,
    required String collectionName,
  }) {
    final cleanContractId = contractId.trim();
    final cleanCollectionName = collectionName.trim();

    if (cleanContractId.isEmpty) {
      throw ArgumentError('contractId não informado.');
    }

    if (cleanCollectionName.isEmpty) {
      throw ArgumentError('collectionName não informado.');
    }

    return _hiringMainDoc(cleanContractId)
        .collection(cleanCollectionName)
        .doc(kStageDocId);
  }

  DocumentReference<Map<String, dynamic>>? stageDocByKey({
    required String contractId,
    required String stageKey,
  }) {
    final cleanStageKey = stageKey.trim();

    if (cleanStageKey.isEmpty) {
      return null;
    }

    final collectionName = collectionNameOf(cleanStageKey);

    if (collectionName == null) {
      return null;
    }

    return stageDoc(
      contractId: contractId,
      collectionName: collectionName,
    );
  }

  Future<void> _ensureHiringMain(String contractId) async {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) {
      throw Exception('contractId não informado.');
    }

    await _contractDoc(cleanContractId).set(
      <String, dynamic>{
        'id': cleanContractId,
        'tenantId': tenantId,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await _hiringMainDoc(cleanContractId).set(
      <String, dynamic>{
        'id': 'main',
        'module': 'hiring',
        'tenantId': tenantId,
        'contractId': cleanContractId,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> _ensureStageMain({
    required String contractId,
    required String collectionName,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanCollectionName = collectionName.trim();

    if (cleanContractId.isEmpty) {
      throw Exception('contractId não informado.');
    }

    if (cleanCollectionName.isEmpty) {
      throw Exception('collectionName não informado.');
    }

    await _ensureHiringMain(cleanContractId);

    await stageDoc(
      contractId: cleanContractId,
      collectionName: cleanCollectionName,
    ).set(
      <String, dynamic>{
        'id': kStageDocId,
        'module': 'hiring',
        'tenantId': tenantId,
        'contractId': cleanContractId,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return value.map(
            (key, val) => MapEntry(
          key.toString(),
          val,
        ),
      );
    }

    return const <String, dynamic>{};
  }

  bool _readApproved(Map<String, dynamic>? data) {
    if (data == null) {
      return false;
    }

    final approval = _asMap(data['approval']);

    return approval['approved'] == true;
  }

  bool _readCompleted(Map<String, dynamic>? data) {
    if (data == null) {
      return false;
    }

    final stage = _asMap(data['stage']);

    return stage['completed'] == true;
  }

  // ===========================================================================
  // LEITURA DE PROGRESSO
  // ===========================================================================

  Stream<Map<String, bool>> watchApprovalAndCompleted({
    required String contractId,
    required String collectionName,
  }) {
    final cleanContractId = contractId.trim();
    final cleanCollectionName = collectionName.trim();

    if (cleanContractId.isEmpty || cleanCollectionName.isEmpty) {
      return Stream<Map<String, bool>>.value(
        const <String, bool>{
          'approved': false,
          'completed': false,
        },
      );
    }

    final ref = stageDoc(
      contractId: cleanContractId,
      collectionName: cleanCollectionName,
    );

    return ref.snapshots().map((snap) {
      final data = snap.data();

      return <String, bool>{
        'approved': _readApproved(data),
        'completed': _readCompleted(data),
      };
    });
  }

  Stream<Map<String, bool>> watchStageByKey({
    required String contractId,
    required String stageKey,
  }) {
    final cleanContractId = contractId.trim();
    final cleanStageKey = stageKey.trim();

    if (cleanContractId.isEmpty || cleanStageKey.isEmpty) {
      return Stream<Map<String, bool>>.value(
        const <String, bool>{
          'approved': false,
          'completed': false,
        },
      );
    }

    final collectionName = collectionNameOf(cleanStageKey);

    if (collectionName == null) {
      return Stream<Map<String, bool>>.value(
        const <String, bool>{
          'approved': false,
          'completed': false,
        },
      );
    }

    return watchApprovalAndCompleted(
      contractId: cleanContractId,
      collectionName: collectionName,
    );
  }

  Future<bool> isStageCompleted({
    required String contractId,
    required String stageKey,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanStageKey = stageKey.trim();

    if (cleanContractId.isEmpty || cleanStageKey.isEmpty) {
      return false;
    }

    final ref = stageDocByKey(
      contractId: cleanContractId,
      stageKey: cleanStageKey,
    );

    if (ref == null) {
      return false;
    }

    final snap = await ref.get();
    final data = snap.data();

    final approved = _readApproved(data);
    final completed = _readCompleted(data);

    return approved || completed;
  }

  Future<Map<String, bool>> loadAllStages({
    required String contractId,
  }) async {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) {
      return const <String, bool>{};
    }

    final out = <String, bool>{};

    for (final stageKey in orderedStages) {
      out[stageKey] = await isStageCompleted(
        contractId: cleanContractId,
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
    final cleanContractId = contractId.trim();
    final cleanCollectionName = collectionName.trim();
    final cleanApproverUid = approverUid.trim();
    final cleanApproverName = approverName.trim();

    if (cleanContractId.isEmpty) {
      throw Exception('contractId não informado.');
    }

    if (cleanCollectionName.isEmpty) {
      throw Exception('collectionName não informado.');
    }

    if (cleanApproverUid.isEmpty) {
      throw Exception('approverUid não informado.');
    }

    await _ensureStageMain(
      contractId: cleanContractId,
      collectionName: cleanCollectionName,
    );

    final ref = stageDoc(
      contractId: cleanContractId,
      collectionName: cleanCollectionName,
    );

    await db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data();

      final approval = _asMap(data?['approval']);
      final hasCreatedAt = approval['createdAt'] != null;

      tx.set(
        ref,
        <String, dynamic>{
          'id': kStageDocId,
          'module': 'hiring',
          'tenantId': tenantId,
          'contractId': cleanContractId,
          'approval': <String, dynamic>{
            'approved': true,
            'approvedBy': <String, dynamic>{
              'uid': cleanApproverUid,
              'name': cleanApproverName,
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
    final cleanContractId = contractId.trim();
    final cleanCollectionName = collectionName.trim();
    final cleanUpdatedByUid = updatedByUid.trim();
    final cleanUpdatedByName = updatedByName.trim();

    if (cleanContractId.isEmpty) {
      throw Exception('contractId não informado.');
    }

    if (cleanCollectionName.isEmpty) {
      throw Exception('collectionName não informado.');
    }

    if (cleanUpdatedByUid.isEmpty) {
      throw Exception('updatedByUid não informado.');
    }

    await _ensureStageMain(
      contractId: cleanContractId,
      collectionName: cleanCollectionName,
    );

    final ref = stageDoc(
      contractId: cleanContractId,
      collectionName: cleanCollectionName,
    );

    await ref.set(
      <String, dynamic>{
        'id': kStageDocId,
        'module': 'hiring',
        'tenantId': tenantId,
        'contractId': cleanContractId,
        'approval': <String, dynamic>{
          'approved': true,
          'updatedBy': <String, dynamic>{
            'uid': cleanUpdatedByUid,
            'name': cleanUpdatedByName,
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
    final cleanContractId = contractId.trim();
    final cleanCollectionName = collectionName.trim();

    if (cleanContractId.isEmpty) {
      throw Exception('contractId não informado.');
    }

    if (cleanCollectionName.isEmpty) {
      throw Exception('collectionName não informado.');
    }

    await _ensureStageMain(
      contractId: cleanContractId,
      collectionName: cleanCollectionName,
    );

    final ref = stageDoc(
      contractId: cleanContractId,
      collectionName: cleanCollectionName,
    );

    await ref.set(
      <String, dynamic>{
        'id': kStageDocId,
        'module': 'hiring',
        'tenantId': tenantId,
        'contractId': cleanContractId,
        'stage': <String, dynamic>{
          'completed': completed,
          'responsible': <String, dynamic>{
            'uid': responsibleUserId?.trim(),
            'name': responsibleName?.trim(),
          },
          'approver': <String, dynamic>{
            'uid': approverUserId?.trim(),
            'name': approverName?.trim(),
          },
          'updatedAt': FieldValue.serverTimestamp(),
        },
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}