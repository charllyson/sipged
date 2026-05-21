import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:sipged/_blocs/system/adm/firebase_admin_data.dart';

class FirebaseAdminRepository {
  FirebaseAdminRepository({
    FirebaseFirestore? db,
  }) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  // ===========================================================================
  // Validações / refs
  // ===========================================================================

  void _validateCollectionPath(String path) {
    final clean = path.trim();

    if (clean.isEmpty) {
      throw ArgumentError('O caminho da coleção não pode estar vazio.');
    }

    final parts = clean.split('/').where((e) => e.trim().isNotEmpty).toList();

    if (parts.length.isEven) {
      throw ArgumentError(
        'Caminho inválido para coleção: "$path". '
            'O caminho de uma coleção precisa terminar em coleção, não documento.',
      );
    }
  }

  CollectionReference<Map<String, dynamic>> _collection(String path) {
    _validateCollectionPath(path);

    return _db.collection(path.trim());
  }

  Future<FirebaseCopyContractModulesResultData>
  copyLegacyContractModulesToTenantHiringMain({
    required FirebaseCopyContractModulesParams params,
    void Function(
        int current,
        int total,
        String label,
        String? detail,
        )? onProgress,
  }) async {
    final cleanTenantId = params.tenantId.trim();
    final cleanSourceContractsPath = params.sourceContractsPath.trim();
    final cleanTargetContractsPath = params.targetContractsPath.trim();

    if (cleanTenantId.isEmpty) {
      throw ArgumentError('tenantId não informado.');
    }

    if (params.modules.isEmpty) {
      throw ArgumentError('Nenhum módulo de contrato informado.');
    }

    _validateCollectionPath(cleanSourceContractsPath);
    _validateCollectionPath(cleanTargetContractsPath);

    final sourceContractsCol = _collection(cleanSourceContractsPath);
    final targetContractsCol = _collection(cleanTargetContractsPath);

    final pageSize = params.pageSize.clamp(1, 200).toInt();
    final batchSize = params.batchSize.clamp(1, 100).toInt();

    int contractsScanned = 0;
    int contractsWithoutModules = 0;
    int rootDocsScanned = 0;
    int sectionDocsScanned = 0;

    int scanned = 0;
    int copied = 0;
    int skipped = 0;
    int alreadyExists = 0;
    int empty = 0;

    final moduleTotals = <String, Map<String, int>>{
      for (final module in params.modules)
        module.targetCollectionId: <String, int>{
          'rootDocsScanned': 0,
          'sectionDocsScanned': 0,
          'copied': 0,
          'skipped': 0,
          'alreadyExists': 0,
          'empty': 0,
        },
    };

    DocumentSnapshot<Map<String, dynamic>>? lastContract;
    final pendingWrites = <_PendingWrite>[];

    onProgress?.call(
      0,
      1,
      'Iniciando migração de Publicação/Arquivamento...',
      'Origem: $cleanSourceContractsPath/{contractId}/{publicacao|arquivamento} → '
          'Destino: $cleanTargetContractsPath/{contractId}/hiring/main/{publicacao|arquivamento}/main',
    );

    while (true) {
      Query<Map<String, dynamic>> contractsQuery =
      sourceContractsCol.orderBy(FieldPath.documentId).limit(pageSize);

      if (lastContract != null) {
        contractsQuery = contractsQuery.startAfterDocument(lastContract);
      }

      final contractsSnap = await contractsQuery.get();

      if (contractsSnap.docs.isEmpty) break;

      for (final contractDoc in contractsSnap.docs) {
        contractsScanned++;

        final contractId = contractDoc.id.trim();

        if (contractId.isEmpty) {
          skipped++;
          continue;
        }

        bool foundAnyModuleForContract = false;

        onProgress?.call(
          contractsScanned,
          1,
          'Lendo contrato...',
          'Contrato: $contractId',
        );

        final targetContractRef = targetContractsCol.doc(
          _safeDocId(contractId),
        );

        final targetHiringMainRef = targetContractRef
            .collection(FirebaseAdminTenantPaths.hiringCollectionId)
            .doc(FirebaseAdminTenantPaths.hiringMainDocId);

        pendingWrites.add(
          _PendingWrite(
            docId: 'hiring/main',
            ref: targetHiringMainRef,
            data: <String, dynamic>{
              'id': FirebaseAdminTenantPaths.hiringMainDocId,
              'tenantId': cleanTenantId,
              'companyId': cleanTenantId,
              'contractId': contractId,
              'uidContract': contractId,
              'uidcontract': contractId,
              'updatedAt': FieldValue.serverTimestamp(),
              'sourceCollectionModel': 'tenant_contract_hiring_main',
            },
            merge: true,
          ),
        );

        for (final module in params.modules) {
          final targetCollectionId = module.targetCollectionId.trim();
          final targetRootDocId = module.targetRootDocId.trim().isEmpty
              ? FirebaseAdminContractModulePaths.mainDocId
              : module.targetRootDocId.trim();

          if (targetCollectionId.isEmpty) {
            skipped++;
            continue;
          }

          final sourceCollectionIds = module.sourceCollectionIds
              .map((value) => value.trim())
              .where((value) => value.isNotEmpty)
              .toSet()
              .toList();

          if (sourceCollectionIds.isEmpty) {
            skipped++;
            continue;
          }

          for (final sourceCollectionId in sourceCollectionIds) {
            final sourceRootCol = contractDoc.reference.collection(
              sourceCollectionId,
            );

            final targetRootDocRef = targetHiringMainRef
                .collection(targetCollectionId)
                .doc(_safeDocId(targetRootDocId));

            final rootDocs = await _readCollectionPaged(
              sourceRootCol,
              pageSize: pageSize,
            );

            if (rootDocs.isEmpty) continue;

            foundAnyModuleForContract = true;

            for (final rootDoc in rootDocs) {
              rootDocsScanned++;
              scanned++;

              moduleTotals[targetCollectionId]!['rootDocsScanned'] =
                  moduleTotals[targetCollectionId]!['rootDocsScanned']! + 1;

              final copyResult = await _queueCopyDoc(
                pendingWrites: pendingWrites,
                sourceDoc: rootDoc,
                targetDocRef: targetRootDocRef,
                tenantId: cleanTenantId,
                contractId: contractId,
                sourceCollectionModel:
                'tenant_contract_hiring_$targetCollectionId',
                merge: params.merge,
                skipExisting: params.skipExisting,
                addMigrationMetadata: params.addMigrationMetadata,
                rewriteDocumentPathFields: params.rewriteDocumentPathFields,
                extraData: <String, dynamic>{
                  'legacySourceCollectionId': sourceCollectionId,
                  'legacySourceRootDocId': rootDoc.id,
                  'moduleCollectionId': targetCollectionId,
                  'moduleDocId': targetRootDocId,
                },
              );

              skipped += copyResult.skipped;
              alreadyExists += copyResult.alreadyExists;
              empty += copyResult.empty;

              moduleTotals[targetCollectionId]!['skipped'] =
                  moduleTotals[targetCollectionId]!['skipped']! +
                      copyResult.skipped;

              moduleTotals[targetCollectionId]!['alreadyExists'] =
                  moduleTotals[targetCollectionId]!['alreadyExists']! +
                      copyResult.alreadyExists;

              moduleTotals[targetCollectionId]!['empty'] =
                  moduleTotals[targetCollectionId]!['empty']! +
                      copyResult.empty;

              onProgress?.call(
                scanned,
                1,
                'Preparando ${module.label}...',
                '${rootDoc.reference.path} → ${targetRootDocRef.path}',
              );

              if (pendingWrites.length >= batchSize) {
                final committed = await _commitPendingWritesSafely(
                  writes: pendingWrites,
                  current: scanned,
                  total: 1,
                  onProgress: onProgress,
                );

                copied += committed;

                moduleTotals[targetCollectionId]!['copied'] =
                    moduleTotals[targetCollectionId]!['copied']! + committed;

                pendingWrites.clear();

                await Future<void>.delayed(const Duration(milliseconds: 80));
              }

              for (final sectionId in module.sectionCollectionIds) {
                final cleanSectionId = sectionId.trim();

                if (cleanSectionId.isEmpty) continue;

                final targetSectionDocId =
                module.targetSectionDocId.trim().isEmpty
                    ? FirebaseAdminContractModulePaths.mainDocId
                    : module.targetSectionDocId.trim();

                final sourceSectionCol = rootDoc.reference.collection(
                  cleanSectionId,
                );

                final targetSectionDocRef = targetRootDocRef
                    .collection(cleanSectionId)
                    .doc(_safeDocId(targetSectionDocId));

                final sectionDocs = await _readCollectionPaged(
                  sourceSectionCol,
                  pageSize: pageSize,
                );

                for (final sectionDoc in sectionDocs) {
                  sectionDocsScanned++;
                  scanned++;

                  moduleTotals[targetCollectionId]!['sectionDocsScanned'] =
                      moduleTotals[targetCollectionId]![
                      'sectionDocsScanned']! +
                          1;

                  final sectionCopyResult = await _queueCopyDoc(
                    pendingWrites: pendingWrites,
                    sourceDoc: sectionDoc,
                    targetDocRef: targetSectionDocRef,
                    tenantId: cleanTenantId,
                    contractId: contractId,
                    sourceCollectionModel:
                    'tenant_contract_hiring_${targetCollectionId}_$cleanSectionId',
                    merge: params.merge,
                    skipExisting: params.skipExisting,
                    addMigrationMetadata: params.addMigrationMetadata,
                    rewriteDocumentPathFields:
                    params.rewriteDocumentPathFields,
                    extraData: <String, dynamic>{
                      'legacySourceCollectionId': sourceCollectionId,
                      'legacySourceRootDocId': rootDoc.id,
                      'legacySourceSectionId': cleanSectionId,
                      'legacySourceSectionDocId': sectionDoc.id,
                      'moduleCollectionId': targetCollectionId,
                      'moduleDocId': targetRootDocId,
                      'sectionId': cleanSectionId,
                      'sectionDocId': targetSectionDocId,
                    },
                  );

                  skipped += sectionCopyResult.skipped;
                  alreadyExists += sectionCopyResult.alreadyExists;
                  empty += sectionCopyResult.empty;

                  moduleTotals[targetCollectionId]!['skipped'] =
                      moduleTotals[targetCollectionId]!['skipped']! +
                          sectionCopyResult.skipped;

                  moduleTotals[targetCollectionId]!['alreadyExists'] =
                      moduleTotals[targetCollectionId]!['alreadyExists']! +
                          sectionCopyResult.alreadyExists;

                  moduleTotals[targetCollectionId]!['empty'] =
                      moduleTotals[targetCollectionId]!['empty']! +
                          sectionCopyResult.empty;

                  onProgress?.call(
                    scanned,
                    1,
                    'Preparando seção de ${module.label}...',
                    '${sectionDoc.reference.path} → ${targetSectionDocRef.path}',
                  );

                  if (pendingWrites.length >= batchSize) {
                    final committed = await _commitPendingWritesSafely(
                      writes: pendingWrites,
                      current: scanned,
                      total: 1,
                      onProgress: onProgress,
                    );

                    copied += committed;

                    moduleTotals[targetCollectionId]!['copied'] =
                        moduleTotals[targetCollectionId]!['copied']! +
                            committed;

                    pendingWrites.clear();

                    await Future<void>.delayed(
                      const Duration(milliseconds: 80),
                    );
                  }
                }
              }
            }
          }
        }

        if (!foundAnyModuleForContract) {
          contractsWithoutModules++;
        }
      }

      lastContract = contractsSnap.docs.last;

      await Future<void>.delayed(const Duration(milliseconds: 40));
    }

    if (pendingWrites.isNotEmpty) {
      final committed = await _commitPendingWritesSafely(
        writes: pendingWrites,
        current: scanned,
        total: 1,
        onProgress: onProgress,
      );

      copied += committed;

      pendingWrites.clear();
    }

    return FirebaseCopyContractModulesResultData(
      tenantId: cleanTenantId,
      sourceContractsPath: cleanSourceContractsPath,
      targetContractsPath: cleanTargetContractsPath,
      totalContractsScanned: contractsScanned,
      totalContractsWithoutModules: contractsWithoutModules,
      totalRootDocsScanned: rootDocsScanned,
      totalSectionDocsScanned: sectionDocsScanned,
      totalScanned: scanned,
      totalCopied: copied,
      totalSkipped: skipped,
      totalAlreadyExists: alreadyExists,
      totalEmpty: empty,
      moduleTotals: moduleTotals,
    );
  }

  /// Alias mantido para não quebrar chamadas antigas.
  Future<FirebaseCopyContractModulesResultData>
  copyLegacyContractModulesToTenantContracts({
    required FirebaseCopyContractModulesParams params,
    void Function(
        int current,
        int total,
        String label,
        String? detail,
        )? onProgress,
  }) {
    return copyLegacyContractModulesToTenantHiringMain(
      params: params,
      onProgress: onProgress,
    );
  }

  /// Alias mantido para não quebrar chamadas antigas.
  Future<FirebaseCopyContractModulesResultData>
  copyLegacyHiringStagesToTenantHiringMain({
    required FirebaseCopyContractModulesParams params,
    void Function(
        int current,
        int total,
        String label,
        String? detail,
        )? onProgress,
  }) {
    return copyLegacyContractModulesToTenantHiringMain(
      params: params,
      onProgress: onProgress,
    );
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  _readCollectionPaged(
      CollectionReference<Map<String, dynamic>> col, {
        required int pageSize,
      }) async {
    final out = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

    DocumentSnapshot<Map<String, dynamic>>? last;

    while (true) {
      Query<Map<String, dynamic>> query =
      col.orderBy(FieldPath.documentId).limit(pageSize.clamp(1, 200));

      if (last != null) {
        query = query.startAfterDocument(last);
      }

      final snap = await query.get();

      if (snap.docs.isEmpty) break;

      out.addAll(snap.docs);
      last = snap.docs.last;
    }

    return out;
  }

  Future<_QueueCopyResult> _queueCopyDoc({
    required List<_PendingWrite> pendingWrites,
    required QueryDocumentSnapshot<Map<String, dynamic>> sourceDoc,
    required DocumentReference<Map<String, dynamic>> targetDocRef,
    required String tenantId,
    required String contractId,
    required String sourceCollectionModel,
    required bool merge,
    required bool skipExisting,
    required bool addMigrationMetadata,
    required bool rewriteDocumentPathFields,
    Map<String, dynamic> extraData = const <String, dynamic>{},
  }) async {
    if (skipExisting) {
      final targetSnap = await targetDocRef.get();

      if (targetSnap.exists) {
        return const _QueueCopyResult(
          skipped: 1,
          alreadyExists: 1,
          empty: 0,
        );
      }
    }

    final data = sourceDoc.data();

    if (data.isEmpty) {
      return const _QueueCopyResult(
        skipped: 1,
        alreadyExists: 0,
        empty: 1,
      );
    }

    final toCopy = _buildCopyData(
      sourcePath: sourceDoc.reference.path,
      docId: sourceDoc.id,
      data: data,
      addMigrationMetadata: addMigrationMetadata,
      targetDocPath: targetDocRef.path,
      rewriteDocumentPathFields: rewriteDocumentPathFields,
    );

    if (toCopy.isEmpty) {
      return const _QueueCopyResult(
        skipped: 1,
        alreadyExists: 0,
        empty: 1,
      );
    }

    toCopy['id'] = targetDocRef.id;
    toCopy['tenantId'] = tenantId;
    toCopy['companyId'] = tenantId;
    toCopy['contractId'] = contractId;
    toCopy['uidContract'] = contractId;
    toCopy['uidcontract'] = contractId;
    toCopy['legacySourceId'] = sourceDoc.id;
    toCopy['legacySourcePath'] = sourceDoc.reference.path;
    toCopy['recordPath'] = targetDocRef.path;
    toCopy['sourceCollectionModel'] = sourceCollectionModel;

    if (extraData.isNotEmpty) {
      toCopy.addAll(extraData);
    }

    pendingWrites.add(
      _PendingWrite(
        docId: targetDocRef.id,
        ref: targetDocRef,
        data: toCopy,
        merge: merge,
      ),
    );

    return const _QueueCopyResult(
      skipped: 0,
      alreadyExists: 0,
      empty: 0,
    );
  }

  // ===========================================================================
  // Preview / count
  // ===========================================================================

  Future<int> countCollectionDocs(String path) async {
    final col = _collection(path);

    int count = 0;
    DocumentSnapshot<Map<String, dynamic>>? last;

    while (true) {
      Query<Map<String, dynamic>> query =
      col.orderBy(FieldPath.documentId).limit(300);

      if (last != null) {
        query = query.startAfterDocument(last);
      }

      final snap = await query.get();

      if (snap.docs.isEmpty) break;

      count += snap.docs.length;
      last = snap.docs.last;
    }

    return count;
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> previewCollection({
    required String path,
    int limit = 50,
  }) async {
    final col = _collection(path);

    final snap = await col
        .orderBy(FieldPath.documentId)
        .limit(limit.clamp(1, 200))
        .get();

    return snap.docs;
  }

  // ===========================================================================
  // Build copy data / commits
  // ===========================================================================

  Map<String, dynamic> _buildCopyData({
    required String sourcePath,
    required String docId,
    required Map<String, dynamic> data,
    required bool addMigrationMetadata,
    required String targetDocPath,
    required bool rewriteDocumentPathFields,
  }) {
    final toCopy = Map<String, dynamic>.from(data);

    if (toCopy.isEmpty) return toCopy;

    if (rewriteDocumentPathFields) {
      if (toCopy.containsKey('recordPath')) {
        toCopy['recordPath'] = targetDocPath;
      }

      if (toCopy.containsKey('sourcePath')) {
        toCopy['sourcePath'] = targetDocPath;
      }

      if (toCopy.containsKey('path')) {
        final raw = toCopy['path'];

        if (raw is String && raw.contains('/')) {
          toCopy['path'] = targetDocPath;
        }
      }
    }

    if (addMigrationMetadata) {
      toCopy.addAll({
        'migrationSourcePath': sourcePath,
        'migrationSourceDocId': docId,
        'migrationTargetPath': targetDocPath,
        'migratedAt': FieldValue.serverTimestamp(),
      });
    }

    return toCopy;
  }

  Future<int> _commitPendingWritesSafely({
    required List<_PendingWrite> writes,
    required int current,
    required int total,
    required void Function(
        int current,
        int total,
        String label,
        String? detail,
        )? onProgress,
  }) async {
    if (writes.isEmpty) return 0;

    onProgress?.call(
      current,
      total,
      'Gravando lote...',
      'Tentando gravar ${writes.length} documento(s).',
    );

    try {
      await _commitWrites(writes);

      onProgress?.call(
        current,
        total,
        'Lote gravado...',
        '${writes.length} documento(s) gravado(s) com sucesso.',
      );

      return writes.length;
    } catch (e) {
      final isTooBig = _isTransactionTooBigError(e);

      if (!isTooBig || writes.length == 1) {
        final docId = writes.length == 1 ? writes.first.docId : 'lote';

        throw Exception(
          'Falha ao gravar $docId. '
              'Quantidade no lote: ${writes.length}. '
              'Erro original: $e',
        );
      }

      final middle = writes.length ~/ 2;
      final left = writes.sublist(0, middle);
      final right = writes.sublist(middle);

      onProgress?.call(
        current,
        total,
        'Lote grande demais...',
        'Dividindo lote de ${writes.length} em '
            '${left.length} + ${right.length}.',
      );

      final leftCommitted = await _commitPendingWritesSafely(
        writes: left,
        current: current,
        total: total,
        onProgress: onProgress,
      );

      final rightCommitted = await _commitPendingWritesSafely(
        writes: right,
        current: current,
        total: total,
        onProgress: onProgress,
      );

      return leftCommitted + rightCommitted;
    }
  }

  Future<void> _commitWrites(List<_PendingWrite> writes) async {
    final batch = _db.batch();

    for (final write in writes) {
      if (write.merge) {
        batch.set(
          write.ref,
          write.data,
          SetOptions(merge: true),
        );
      } else {
        batch.set(
          write.ref,
          write.data,
        );
      }
    }

    await batch.commit();
  }

  bool _isTransactionTooBigError(Object error) {
    final text = error.toString().toLowerCase();

    return text.contains('transaction too big') ||
        text.contains('decrease transaction size') ||
        text.contains('maximum request size') ||
        text.contains('request payload size');
  }

  String _safeDocId(String value) {
    final clean = value.trim();

    if (clean.isEmpty) {
      return DateTime.now().microsecondsSinceEpoch.toString();
    }

    return clean
        .replaceAll(RegExp(r'[/#?\[\]*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
  }
}

class _PendingWrite {
  const _PendingWrite({
    required this.docId,
    required this.ref,
    required this.data,
    required this.merge,
  });

  final String docId;
  final DocumentReference<Map<String, dynamic>> ref;
  final Map<String, dynamic> data;
  final bool merge;
}

class _QueueCopyResult {
  const _QueueCopyResult({
    required this.skipped,
    required this.alreadyExists,
    required this.empty,
  });

  final int skipped;
  final int alreadyExists;
  final int empty;
}