// lib/_blocs/system/adm/firebase_admin_repository.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sipged/_blocs/system/adm/firebase_admin_data.dart';

class FirebaseAdminRepository {
  FirebaseAdminRepository({
    FirebaseFirestore? db,
  }) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

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

  void _validateDocumentPath(String path) {
    final clean = path.trim();

    if (clean.isEmpty) {
      throw ArgumentError('O caminho do documento não pode estar vazio.');
    }

    final parts = clean.split('/').where((e) => e.trim().isNotEmpty).toList();

    if (parts.length.isOdd) {
      throw ArgumentError(
        'Caminho inválido para documento: "$path". '
            'O caminho de um documento precisa terminar em documento, não coleção.',
      );
    }
  }

  DocumentReference<Map<String, dynamic>> _document(String path) {
    _validateDocumentPath(path);
    return _db.doc(path.trim());
  }

  Future<FirebaseLegacyCompanyMigrationResultData> migrateLegacyCompanyToTenant({
    required String tenantId,
    bool merge = true,
    bool skipExisting = false,
    bool addMigrationMetadata = true,
    bool rewriteDocumentPathFields = true,
    bool copySubcollectionsWhenTargetExists = true,
    void Function(
        int current,
        int total,
        String label,
        String? detail,
        )? onProgress,
  }) async {
    final cleanTenantId = tenantId.trim();

    if (cleanTenantId.isEmpty) {
      throw ArgumentError('Informe o Tenant ID.');
    }

    final sourceDocPath = FirebaseAdminSetupTenantPaths.legacyCompanyDocPath;
    final targetDocPath = FirebaseAdminSetupTenantPaths.tenantDocPath(
      cleanTenantId,
    );

    _validateDocumentPath(sourceDocPath);
    _validateDocumentPath(targetDocPath);

    final sourceDocRef = _document(sourceDocPath);
    final targetDocRef = _document(targetDocPath);

    final rules = FirebaseAdminSetupTenantPaths.migrationRules(cleanTenantId);
    final totalSteps = 1 + rules.length;

    onProgress?.call(
      0,
      totalSteps,
      'Lendo empresa legada...',
      sourceDocRef.path,
    );

    final sourceSnap = await sourceDocRef.get();

    if (!sourceSnap.exists || sourceSnap.data() == null) {
      throw ArgumentError('Documento de origem não encontrado: $sourceDocPath');
    }

    final targetSnap = await targetDocRef.get();
    final targetAlreadyExists = targetSnap.exists;

    bool documentCopied = false;
    bool documentSkipped = false;

    int subcollectionsProcessed = 0;
    int subDocsCopied = 0;
    int subDocsSkipped = 0;

    if (skipExisting && targetAlreadyExists) {
      documentSkipped = true;

      onProgress?.call(
        1,
        totalSteps,
        'Tenant já existe...',
        targetDocRef.path,
      );
    } else {
      final data = sourceSnap.data() ?? <String, dynamic>{};

      final toCopy = _buildCopyData(
        sourcePath: sourceDocRef.path,
        docId: sourceDocRef.id,
        data: data,
        selectedFields: null,
        addMigrationMetadata: addMigrationMetadata,
        targetDocPath: targetDocRef.path,
        rewriteDocumentPathFields: rewriteDocumentPathFields,
      );

      final normalized = _normalizeLegacyCompanyDataForTenant(
        tenantId: cleanTenantId,
        sourceDocId: sourceDocRef.id,
        targetDocPath: targetDocRef.path,
        data: toCopy,
      );

      onProgress?.call(
        1,
        totalSteps,
        'Gravando documento do tenant...',
        targetDocRef.path,
      );

      if (merge) {
        await targetDocRef.set(normalized, SetOptions(merge: true));
      } else {
        await targetDocRef.set(normalized);
      }

      documentCopied = true;
    }

    if (!targetAlreadyExists || copySubcollectionsWhenTargetExists) {
      for (int i = 0; i < rules.length; i++) {
        final rule = rules[i];

        onProgress?.call(
          i + 2,
          totalSteps,
          'Migrando ${rule.sourceSubcollection}...',
          '${sourceDocRef.path}/${rule.sourceSubcollection} → ${rule.targetCollectionPath}',
        );

        final result = await _copyLegacyCompanySubcollectionToTenant(
          tenantId: cleanTenantId,
          rule: rule,
          sourceSubCol: sourceDocRef.collection(rule.sourceSubcollection),
          merge: merge,
          skipExisting: skipExisting,
          addMigrationMetadata: addMigrationMetadata,
          rewriteDocumentPathFields: rewriteDocumentPathFields,
          current: i + 2,
          total: totalSteps,
          onProgress: onProgress,
        );

        subcollectionsProcessed += result.subcollectionsProcessed;
        subDocsCopied += result.docsCopied;
        subDocsSkipped += result.docsSkipped;
      }
    }

    return FirebaseLegacyCompanyMigrationResultData(
      tenantId: cleanTenantId,
      sourceDocPath: sourceDocPath,
      targetDocPath: targetDocPath,
      documentCopied: documentCopied,
      documentSkipped: documentSkipped,
      targetAlreadyExists: targetAlreadyExists,
      totalSubcollectionsProcessed: subcollectionsProcessed,
      totalSubcollectionDocsCopied: subDocsCopied,
      totalSubcollectionDocsSkipped: subDocsSkipped,
      rules: rules,
    );
  }

  Future<_SubcollectionCopyResult> _copyLegacyCompanySubcollectionToTenant({
    required String tenantId,
    required FirebaseLegacyCompanySubcollectionRule rule,
    required CollectionReference<Map<String, dynamic>> sourceSubCol,
    required bool merge,
    required bool skipExisting,
    required bool addMigrationMetadata,
    required bool rewriteDocumentPathFields,
    required int current,
    required int total,
    required void Function(
        int current,
        int total,
        String label,
        String? detail,
        )? onProgress,
    int pageSize = 200,
    int batchSize = 100,
  }) async {
    final targetSubCol = _collection(rule.targetCollectionPath);

    int copied = 0;
    int skipped = 0;

    DocumentSnapshot<Map<String, dynamic>>? last;
    final pendingWrites = <_PendingWrite>[];

    while (true) {
      Query<Map<String, dynamic>> query = sourceSubCol
          .orderBy(FieldPath.documentId)
          .limit(pageSize.clamp(1, 200));

      if (last != null) {
        query = query.startAfterDocument(last);
      }

      final snap = await query.get();

      if (snap.docs.isEmpty) break;

      for (final sourceDoc in snap.docs) {
        final docId = sourceDoc.id;
        final data = sourceDoc.data();

        final targetDocRef = targetSubCol.doc(docId);

        if (skipExisting) {
          final targetSnap = await targetDocRef.get();

          if (targetSnap.exists) {
            skipped++;
            continue;
          }
        }

        if (data.isEmpty) {
          skipped++;
          continue;
        }

        final copiedData = _buildCopyData(
          sourcePath: sourceSubCol.path,
          docId: docId,
          data: data,
          selectedFields: null,
          addMigrationMetadata: addMigrationMetadata,
          targetDocPath: targetDocRef.path,
          rewriteDocumentPathFields: rewriteDocumentPathFields,
        );

        final normalized = _normalizeLegacySetupSubcollectionDataForTenant(
          tenantId: tenantId,
          sourceDocId: docId,
          targetDocPath: targetDocRef.path,
          kind: rule.targetKind,
          data: copiedData,
        );

        if (normalized.isEmpty) {
          skipped++;
          continue;
        }

        pendingWrites.add(
          _PendingWrite(
            docId: docId,
            ref: targetDocRef,
            data: normalized,
            merge: merge,
          ),
        );

        if (pendingWrites.length >= batchSize.clamp(1, 100)) {
          copied += await _commitPendingWritesSafely(
            writes: pendingWrites,
            current: current,
            total: total,
            onProgress: onProgress,
          );

          pendingWrites.clear();

          await Future<void>.delayed(const Duration(milliseconds: 80));
        }
      }

      last = snap.docs.last;

      await Future<void>.delayed(const Duration(milliseconds: 40));
    }

    if (pendingWrites.isNotEmpty) {
      copied += await _commitPendingWritesSafely(
        writes: pendingWrites,
        current: current,
        total: total,
        onProgress: onProgress,
      );

      pendingWrites.clear();
    }

    return _SubcollectionCopyResult(
      subcollectionsProcessed: 1,
      docsCopied: copied,
      docsSkipped: skipped,
    );
  }

  Map<String, dynamic> _normalizeLegacyCompanyDataForTenant({
    required String tenantId,
    required String sourceDocId,
    required String targetDocPath,
    required Map<String, dynamic> data,
  }) {
    final out = Map<String, dynamic>.from(data);

    final companyName = _firstNonEmptyString([
      out['companyName'],
      out['name'],
      out['label'],
    ]);

    final fantasyName = _firstNonEmptyString([
      out['fantasyName'],
      out['fantasy_name'],
      out['displayName'],
    ]);

    out['tenantId'] = tenantId;
    out['companyId'] = tenantId;
    out['id'] = tenantId;

    if (companyName != null) {
      out['companyName'] = companyName;
      out['label'] = companyName;
    }

    if (fantasyName != null) {
      out['fantasyName'] = fantasyName;
    }

    if (out.containsKey('logoURL') && !out.containsKey('logoUrl')) {
      out['logoUrl'] = out['logoURL'];
    }

    out['recordPath'] = targetDocPath;
    out['sourceLegacyPath'] = FirebaseAdminSetupTenantPaths.legacyCompanyDocPath;
    out['sourceLegacyDocId'] = sourceDocId;
    out['isMigratedFromLegacySetup'] = true;

    return out;
  }

  Map<String, dynamic> _normalizeLegacySetupSubcollectionDataForTenant({
    required String tenantId,
    required String sourceDocId,
    required String targetDocPath,
    required FirebaseLegacyCompanyTargetKind kind,
    required Map<String, dynamic> data,
  }) {
    final out = Map<String, dynamic>.from(data);

    final label = _labelForLegacySetupData(out);

    out['tenantId'] = tenantId;
    out['companyId'] = tenantId;
    out['parentId'] = tenantId;
    out['recordPath'] = targetDocPath;
    out['sourceLegacyDocId'] = sourceDocId;
    out['sourceLegacyKind'] = kind.name;
    out['isMigratedFromLegacySetup'] = true;

    if (label != null) {
      out['label'] = label;
    }

    switch (kind) {
      case FirebaseLegacyCompanyTargetKind.partner:
        out['partnerId'] = sourceDocId;
        out['id'] = out['id'] ?? sourceDocId;
        out['name'] = _firstNonEmptyString([
          out['name'],
          label,
          sourceDocId,
        ]);
        break;

      case FirebaseLegacyCompanyTargetKind.unit:
        out['unitId'] = _firstNonEmptyString([
          out['unitId'],
          sourceDocId,
        ]);
        out['unitName'] = _firstNonEmptyString([
          out['unitName'],
          label,
          sourceDocId,
        ]);
        break;

      case FirebaseLegacyCompanyTargetKind.road:
        out['roadId'] = _firstNonEmptyString([
          out['roadId'],
          out['id'],
          sourceDocId,
        ]);
        out['id'] = out['id'] ?? sourceDocId;
        out['name'] = _firstNonEmptyString([
          out['name'],
          label,
          sourceDocId,
        ]);
        out['acronym'] = _firstNonEmptyString([
          out['acronym'],
          out['sigla'],
          out['name'],
          sourceDocId,
        ]);
        break;

      case FirebaseLegacyCompanyTargetKind.region:
        out['regionId'] = _firstNonEmptyString([
          out['regionId'],
          sourceDocId,
        ]);
        out['regionName'] = _firstNonEmptyString([
          out['regionName'],
          label,
          sourceDocId,
        ]);
        break;

      case FirebaseLegacyCompanyTargetKind.fundingSource:
        out['fundingSourceId'] = sourceDocId;
        out['id'] = out['id'] ?? sourceDocId;
        out['name'] = _firstNonEmptyString([
          out['name'],
          label,
          sourceDocId,
        ]);
        break;

      case FirebaseLegacyCompanyTargetKind.program:
        out['programId'] = sourceDocId;
        out['id'] = out['id'] ?? sourceDocId;
        out['name'] = _firstNonEmptyString([
          out['name'],
          label,
          sourceDocId,
        ]);
        break;

      case FirebaseLegacyCompanyTargetKind.expenseNature:
        out['expenseNatureId'] = sourceDocId;
        out['id'] = out['id'] ?? sourceDocId;
        out['name'] = _firstNonEmptyString([
          out['name'],
          label,
          sourceDocId,
        ]);
        break;

      case FirebaseLegacyCompanyTargetKind.tenant:
        break;
    }

    return out;
  }

  String? _labelForLegacySetupData(Map<String, dynamic> data) {
    return _firstNonEmptyString([
      data['companyName'],
      data['fantasyName'],
      data['regionName'],
      data['unitName'],
      data['name'],
      data['label'],
      data['acronym'],
      data['id'],
    ]);
  }

  String? _firstNonEmptyString(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim();

      if (text != null && text.isNotEmpty) {
        return text;
      }
    }

    return null;
  }

  Future<FirebaseCopyDocumentResultData> copyDocumentToDocument({
    required FirebaseCopyDocumentParams params,
    void Function(
        int current,
        int total,
        String label,
        String? detail,
        )? onProgress,
  }) async {
    _validateDocumentPath(params.sourceDocPath);
    _validateDocumentPath(params.targetDocPath);

    final sourceDocRef = _document(params.sourceDocPath);
    final targetDocRef = _document(params.targetDocPath);

    onProgress?.call(
      0,
      1,
      'Lendo documento de origem...',
      sourceDocRef.path,
    );

    final sourceSnap = await sourceDocRef.get();

    if (!sourceSnap.exists || sourceSnap.data() == null) {
      throw ArgumentError(
        'Documento de origem não encontrado: ${params.sourceDocPath}',
      );
    }

    final targetSnap = await targetDocRef.get();
    final targetAlreadyExists = targetSnap.exists;

    bool documentCopied = false;
    bool documentSkipped = false;

    int subcollectionsCopied = 0;
    int subDocsCopied = 0;
    int subDocsSkipped = 0;

    if (params.skipExisting && targetAlreadyExists) {
      documentSkipped = true;

      onProgress?.call(
        1,
        1,
        'Documento destino já existe...',
        targetDocRef.path,
      );
    } else {
      final data = sourceSnap.data() ?? <String, dynamic>{};

      final toCopy = _buildCopyData(
        sourcePath: sourceDocRef.path,
        docId: sourceDocRef.id,
        data: data,
        selectedFields: null,
        addMigrationMetadata: params.addMigrationMetadata,
        targetDocPath: targetDocRef.path,
        rewriteDocumentPathFields: params.rewriteDocumentPathFields,
      );

      toCopy['tenantId'] = targetDocRef.id;
      toCopy['companyId'] = targetDocRef.id;

      if (toCopy.containsKey('logoURL') && !toCopy.containsKey('logoUrl')) {
        toCopy['logoUrl'] = toCopy['logoURL'];
      }

      onProgress?.call(
        1,
        1,
        'Gravando documento do tenant...',
        targetDocRef.path,
      );

      if (params.merge) {
        await targetDocRef.set(toCopy, SetOptions(merge: true));
      } else {
        await targetDocRef.set(toCopy);
      }

      documentCopied = true;
    }

    final cleanSubcollections = params.subcollectionsToCopy
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    final shouldCopySubs = cleanSubcollections.isNotEmpty;

    if (shouldCopySubs &&
        (!targetAlreadyExists || params.copySubcollectionsWhenTargetExists)) {
      final subResult = await _copyKnownSubcollectionsForDocument(
        params: FirebaseCopyCollectionParams(
          sourcePath: 'system',
          targetPath: 'tenants',
          merge: params.merge,
          skipExisting: params.skipExisting,
          addMigrationMetadata: params.addMigrationMetadata,
          subcollectionsToCopy: cleanSubcollections,
          copySubcollectionsWhenParentExists:
          params.copySubcollectionsWhenTargetExists,
          rewriteDocumentPathFields: params.rewriteDocumentPathFields,
        ),
        sourceDocRef: sourceDocRef,
        targetDocRef: targetDocRef,
        current: 1,
        total: 1,
        onProgress: onProgress,
      );

      subcollectionsCopied += subResult.subcollectionsProcessed;
      subDocsCopied += subResult.docsCopied;
      subDocsSkipped += subResult.docsSkipped;
    }

    return FirebaseCopyDocumentResultData(
      sourceDocPath: params.sourceDocPath,
      targetDocPath: params.targetDocPath,
      documentCopied: documentCopied,
      documentSkipped: documentSkipped,
      targetAlreadyExists: targetAlreadyExists,
      totalSubcollectionsCopied: subcollectionsCopied,
      totalSubcollectionDocsCopied: subDocsCopied,
      totalSubcollectionDocsSkipped: subDocsSkipped,
      subcollectionsToCopy: cleanSubcollections,
    );
  }

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

  Future<int> deleteCollectionCompletely({
    required String path,
    int batchSize = 450,
  }) async {
    final col = _collection(path);

    int deleted = 0;

    while (true) {
      final snap = await col.limit(batchSize.clamp(1, 500)).get();

      if (snap.docs.isEmpty) break;

      final batch = _db.batch();

      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      deleted += snap.docs.length;

      await Future<void>.delayed(const Duration(milliseconds: 120));
    }

    return deleted;
  }

  Future<FirebaseCopyCollectionResultData> copyCollectionDocuments({
    required FirebaseCopyCollectionParams params,
    void Function(
        int current,
        int total,
        String label,
        String? detail,
        )? onProgress,
  }) async {
    _validateCollectionPath(params.sourcePath);
    _validateCollectionPath(params.targetPath);

    if (params.copyAllDocuments) {
      return _copyAllCollectionDocuments(
        params: params,
        onProgress: onProgress,
      );
    }

    return _copySelectedCollectionDocuments(
      params: params,
      onProgress: onProgress,
    );
  }

  Future<FirebaseCopyCollectionResultData> _copyAllCollectionDocuments({
    required FirebaseCopyCollectionParams params,
    void Function(
        int current,
        int total,
        String label,
        String? detail,
        )? onProgress,
  }) async {
    final sourceCol = _collection(params.sourcePath);
    final targetCol = _collection(params.targetPath);

    onProgress?.call(
      0,
      1,
      'Contando documentos...',
      'Calculando o total da coleção de origem.',
    );

    final total = await countCollectionDocs(params.sourcePath);

    if (total == 0) {
      return FirebaseCopyCollectionResultData(
        sourcePath: params.sourcePath,
        targetPath: params.targetPath,
        totalScanned: 0,
        totalCopied: 0,
        totalSkipped: 0,
        totalAlreadyExists: 0,
        totalEmpty: 0,
        copyAllDocuments: true,
        subcollectionsToCopy: params.subcollectionsToCopy,
      );
    }

    int scanned = 0;
    int committed = 0;
    int skipped = 0;
    int alreadyExists = 0;
    int empty = 0;

    int subcollectionsCopied = 0;
    int subDocsCopied = 0;
    int subDocsSkipped = 0;

    DocumentSnapshot<Map<String, dynamic>>? last;
    final pendingWrites = <_PendingWrite>[];

    final pageSize = params.pageSize.clamp(1, 200);
    final batchSize = params.batchSize.clamp(1, 100);

    while (true) {
      Query<Map<String, dynamic>> query =
      sourceCol.orderBy(FieldPath.documentId).limit(pageSize);

      if (last != null) {
        query = query.startAfterDocument(last);
      }

      onProgress?.call(
        scanned,
        total,
        'Lendo página...',
        'Buscando até $pageSize documento(s) da origem.',
      );

      final snap = await query.get();

      if (snap.docs.isEmpty) break;

      for (final sourceSnap in snap.docs) {
        scanned++;

        final docId = sourceSnap.id;
        final sourceDocRef = sourceSnap.reference;
        final targetDocRef = targetCol.doc(docId);

        onProgress?.call(
          scanned,
          total,
          'Preparando documento principal...',
          'Documento atual: $docId',
        );

        final data = sourceSnap.data();

        if (params.skipExisting) {
          final targetSnap = await targetDocRef.get();

          if (targetSnap.exists) {
            alreadyExists++;
            skipped++;

            onProgress?.call(
              scanned,
              total,
              'Documento principal já existe...',
              'Verificando subcoleções de: $docId',
            );

            if (params.shouldCopySubcollections &&
                params.copySubcollectionsWhenParentExists) {
              final subResult = await _copyKnownSubcollectionsForDocument(
                params: params,
                sourceDocRef: sourceDocRef,
                targetDocRef: targetDocRef,
                current: scanned,
                total: total,
                onProgress: onProgress,
              );

              subcollectionsCopied += subResult.subcollectionsProcessed;
              subDocsCopied += subResult.docsCopied;
              subDocsSkipped += subResult.docsSkipped;
            }

            continue;
          }
        }

        if (data.isEmpty) {
          empty++;
          skipped++;

          if (params.shouldCopySubcollections) {
            final subResult = await _copyKnownSubcollectionsForDocument(
              params: params,
              sourceDocRef: sourceDocRef,
              targetDocRef: targetDocRef,
              current: scanned,
              total: total,
              onProgress: onProgress,
            );

            subcollectionsCopied += subResult.subcollectionsProcessed;
            subDocsCopied += subResult.docsCopied;
            subDocsSkipped += subResult.docsSkipped;
          }

          continue;
        }

        final toCopy = _buildCopyData(
          sourcePath: params.sourcePath,
          docId: docId,
          data: data,
          selectedFields: params.selectedFieldsByDocId[docId],
          addMigrationMetadata: params.addMigrationMetadata,
          targetDocPath: targetDocRef.path,
          rewriteDocumentPathFields: params.rewriteDocumentPathFields,
        );

        if (toCopy.isEmpty) {
          empty++;
          skipped++;
        } else {
          pendingWrites.add(
            _PendingWrite(
              docId: docId,
              ref: targetDocRef,
              data: toCopy,
              merge: params.merge,
            ),
          );

          if (pendingWrites.length >= batchSize) {
            committed += await _commitPendingWritesSafely(
              writes: pendingWrites,
              current: scanned,
              total: total,
              onProgress: onProgress,
            );

            pendingWrites.clear();

            await Future<void>.delayed(const Duration(milliseconds: 80));
          }
        }

        if (params.shouldCopySubcollections) {
          if (pendingWrites.isNotEmpty) {
            committed += await _commitPendingWritesSafely(
              writes: pendingWrites,
              current: scanned,
              total: total,
              onProgress: onProgress,
            );

            pendingWrites.clear();
          }

          final subResult = await _copyKnownSubcollectionsForDocument(
            params: params,
            sourceDocRef: sourceDocRef,
            targetDocRef: targetDocRef,
            current: scanned,
            total: total,
            onProgress: onProgress,
          );

          subcollectionsCopied += subResult.subcollectionsProcessed;
          subDocsCopied += subResult.docsCopied;
          subDocsSkipped += subResult.docsSkipped;
        }
      }

      last = snap.docs.last;

      await Future<void>.delayed(const Duration(milliseconds: 40));
    }

    if (pendingWrites.isNotEmpty) {
      committed += await _commitPendingWritesSafely(
        writes: pendingWrites,
        current: scanned,
        total: total,
        onProgress: onProgress,
      );

      pendingWrites.clear();
    }

    return FirebaseCopyCollectionResultData(
      sourcePath: params.sourcePath,
      targetPath: params.targetPath,
      totalScanned: scanned,
      totalCopied: committed,
      totalSkipped: skipped,
      totalAlreadyExists: alreadyExists,
      totalEmpty: empty,
      copyAllDocuments: true,
      totalSubcollectionsCopied: subcollectionsCopied,
      totalSubcollectionDocsCopied: subDocsCopied,
      totalSubcollectionDocsSkipped: subDocsSkipped,
      subcollectionsToCopy: params.subcollectionsToCopy,
    );
  }

  Future<FirebaseCopyCollectionResultData> _copySelectedCollectionDocuments({
    required FirebaseCopyCollectionParams params,
    void Function(
        int current,
        int total,
        String label,
        String? detail,
        )? onProgress,
  }) async {
    final sourceCol = _collection(params.sourcePath);
    final targetCol = _collection(params.targetPath);

    final cleanIds = params.docIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toList();

    if (cleanIds.isEmpty) {
      throw ArgumentError('Nenhum documento informado para cópia.');
    }

    int scanned = 0;
    int committed = 0;
    int skipped = 0;
    int alreadyExists = 0;
    int empty = 0;

    int subcollectionsCopied = 0;
    int subDocsCopied = 0;
    int subDocsSkipped = 0;

    final pendingWrites = <_PendingWrite>[];
    final batchSize = params.batchSize.clamp(1, 100);

    for (int i = 0; i < cleanIds.length; i++) {
      final docId = cleanIds[i];
      scanned++;

      onProgress?.call(
        i + 1,
        cleanIds.length,
        'Lendo documentos selecionados...',
        'Documento atual: $docId',
      );

      final sourceDocRef = sourceCol.doc(docId);
      final targetDocRef = targetCol.doc(docId);

      final sourceSnap = await sourceDocRef.get();

      if (!sourceSnap.exists) {
        skipped++;
        continue;
      }

      final data = sourceSnap.data();

      if (params.skipExisting) {
        final targetSnap = await targetDocRef.get();

        if (targetSnap.exists) {
          alreadyExists++;
          skipped++;

          if (params.shouldCopySubcollections &&
              params.copySubcollectionsWhenParentExists) {
            final subResult = await _copyKnownSubcollectionsForDocument(
              params: params,
              sourceDocRef: sourceDocRef,
              targetDocRef: targetDocRef,
              current: i + 1,
              total: cleanIds.length,
              onProgress: onProgress,
            );

            subcollectionsCopied += subResult.subcollectionsProcessed;
            subDocsCopied += subResult.docsCopied;
            subDocsSkipped += subResult.docsSkipped;
          }

          continue;
        }
      }

      if (data == null || data.isEmpty) {
        empty++;
        skipped++;
      } else {
        final toCopy = _buildCopyData(
          sourcePath: params.sourcePath,
          docId: docId,
          data: data,
          selectedFields: params.selectedFieldsByDocId[docId],
          addMigrationMetadata: params.addMigrationMetadata,
          targetDocPath: targetDocRef.path,
          rewriteDocumentPathFields: params.rewriteDocumentPathFields,
        );

        if (toCopy.isEmpty) {
          empty++;
          skipped++;
        } else {
          pendingWrites.add(
            _PendingWrite(
              docId: docId,
              ref: targetDocRef,
              data: toCopy,
              merge: params.merge,
            ),
          );

          if (pendingWrites.length >= batchSize) {
            committed += await _commitPendingWritesSafely(
              writes: pendingWrites,
              current: i + 1,
              total: cleanIds.length,
              onProgress: onProgress,
            );

            pendingWrites.clear();

            await Future<void>.delayed(const Duration(milliseconds: 80));
          }
        }
      }

      if (params.shouldCopySubcollections) {
        if (pendingWrites.isNotEmpty) {
          committed += await _commitPendingWritesSafely(
            writes: pendingWrites,
            current: i + 1,
            total: cleanIds.length,
            onProgress: onProgress,
          );

          pendingWrites.clear();
        }

        final subResult = await _copyKnownSubcollectionsForDocument(
          params: params,
          sourceDocRef: sourceDocRef,
          targetDocRef: targetDocRef,
          current: i + 1,
          total: cleanIds.length,
          onProgress: onProgress,
        );

        subcollectionsCopied += subResult.subcollectionsProcessed;
        subDocsCopied += subResult.docsCopied;
        subDocsSkipped += subResult.docsSkipped;
      }
    }

    if (pendingWrites.isNotEmpty) {
      committed += await _commitPendingWritesSafely(
        writes: pendingWrites,
        current: cleanIds.length,
        total: cleanIds.length,
        onProgress: onProgress,
      );

      pendingWrites.clear();
    }

    return FirebaseCopyCollectionResultData(
      sourcePath: params.sourcePath,
      targetPath: params.targetPath,
      totalSelected: cleanIds.length,
      totalScanned: scanned,
      totalCopied: committed,
      totalSkipped: skipped,
      totalAlreadyExists: alreadyExists,
      totalEmpty: empty,
      copyAllDocuments: false,
      totalSubcollectionsCopied: subcollectionsCopied,
      totalSubcollectionDocsCopied: subDocsCopied,
      totalSubcollectionDocsSkipped: subDocsSkipped,
      subcollectionsToCopy: params.subcollectionsToCopy,
    );
  }

  Future<_SubcollectionCopyResult> _copyKnownSubcollectionsForDocument({
    required FirebaseCopyCollectionParams params,
    required DocumentReference<Map<String, dynamic>> sourceDocRef,
    required DocumentReference<Map<String, dynamic>> targetDocRef,
    required int current,
    required int total,
    required void Function(
        int current,
        int total,
        String label,
        String? detail,
        )? onProgress,
  }) async {
    int processed = 0;
    int copied = 0;
    int skipped = 0;

    final cleanSubcollections = params.subcollectionsToCopy
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    for (final subName in cleanSubcollections) {
      processed++;

      onProgress?.call(
        current,
        total,
        'Copiando subcoleção...',
        '${sourceDocRef.path}/$subName',
      );

      final subResult = await _copySubcollection(
        params: params,
        sourceSubCol: sourceDocRef.collection(subName),
        targetSubCol: targetDocRef.collection(subName),
        current: current,
        total: total,
        onProgress: onProgress,
      );

      copied += subResult.docsCopied;
      skipped += subResult.docsSkipped;
    }

    return _SubcollectionCopyResult(
      subcollectionsProcessed: processed,
      docsCopied: copied,
      docsSkipped: skipped,
    );
  }

  Future<_SubcollectionCopyResult> _copySubcollection({
    required FirebaseCopyCollectionParams params,
    required CollectionReference<Map<String, dynamic>> sourceSubCol,
    required CollectionReference<Map<String, dynamic>> targetSubCol,
    required int current,
    required int total,
    required void Function(
        int current,
        int total,
        String label,
        String? detail,
        )? onProgress,
  }) async {
    int copied = 0;
    int skipped = 0;

    DocumentSnapshot<Map<String, dynamic>>? last;
    final pendingWrites = <_PendingWrite>[];

    final pageSize = params.pageSize.clamp(1, 200);
    final batchSize = params.batchSize.clamp(1, 100);

    while (true) {
      Query<Map<String, dynamic>> query =
      sourceSubCol.orderBy(FieldPath.documentId).limit(pageSize);

      if (last != null) {
        query = query.startAfterDocument(last);
      }

      final snap = await query.get();

      if (snap.docs.isEmpty) break;

      for (final sourceSubDoc in snap.docs) {
        final docId = sourceSubDoc.id;
        final data = sourceSubDoc.data();

        final targetSubDocRef = targetSubCol.doc(docId);

        if (params.skipExisting) {
          final targetSnap = await targetSubDocRef.get();

          if (targetSnap.exists) {
            skipped++;
            continue;
          }
        }

        if (data.isEmpty) {
          skipped++;
          continue;
        }

        final toCopy = _buildCopyData(
          sourcePath: sourceSubCol.path,
          docId: docId,
          data: data,
          selectedFields: null,
          addMigrationMetadata: params.addMigrationMetadata,
          targetDocPath: targetSubDocRef.path,
          rewriteDocumentPathFields: params.rewriteDocumentPathFields,
        );

        if (toCopy.isEmpty) {
          skipped++;
          continue;
        }

        pendingWrites.add(
          _PendingWrite(
            docId: docId,
            ref: targetSubDocRef,
            data: toCopy,
            merge: params.merge,
          ),
        );

        if (pendingWrites.length >= batchSize) {
          copied += await _commitPendingWritesSafely(
            writes: pendingWrites,
            current: current,
            total: total,
            onProgress: onProgress,
          );

          pendingWrites.clear();

          await Future<void>.delayed(const Duration(milliseconds: 80));
        }
      }

      last = snap.docs.last;

      await Future<void>.delayed(const Duration(milliseconds: 40));
    }

    if (pendingWrites.isNotEmpty) {
      copied += await _commitPendingWritesSafely(
        writes: pendingWrites,
        current: current,
        total: total,
        onProgress: onProgress,
      );

      pendingWrites.clear();
    }

    return _SubcollectionCopyResult(
      subcollectionsProcessed: 1,
      docsCopied: copied,
      docsSkipped: skipped,
    );
  }

  Map<String, dynamic> _buildCopyData({
    required String sourcePath,
    required String docId,
    required Map<String, dynamic> data,
    required Set<String>? selectedFields,
    required bool addMigrationMetadata,
    required String targetDocPath,
    required bool rewriteDocumentPathFields,
  }) {
    final Map<String, dynamic> toCopy;

    if (selectedFields != null && selectedFields.isNotEmpty) {
      toCopy = {
        for (final key in selectedFields)
          if (data.containsKey(key)) key: data[key],
      };
    } else {
      toCopy = Map<String, dynamic>.from(data);
    }

    if (toCopy.isEmpty) return toCopy;

    if (rewriteDocumentPathFields) {
      if (toCopy.containsKey('recordPath')) {
        toCopy['recordPath'] = targetDocPath;
      }

      if (toCopy.containsKey('sourcePath')) {
        toCopy['sourcePath'] = targetDocPath;
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

  Future<int> _countDocsInCollection(
      CollectionReference<Map<String, dynamic>> col, {
        int pageSize = 300,
      }) async {
    int count = 0;
    DocumentSnapshot<Map<String, dynamic>>? last;

    while (true) {
      Query<Map<String, dynamic>> query =
      col.orderBy(FieldPath.documentId).limit(pageSize);

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

  Future<int> _deleteCollectionBatched(
      CollectionReference<Map<String, dynamic>> col, {
        int batchSize = 250,
      }) async {
    int deleted = 0;

    while (true) {
      final snap = await col.limit(batchSize.clamp(1, 500)).get();

      if (snap.docs.isEmpty) break;

      final batch = _db.batch();

      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      deleted += snap.docs.length;

      await Future<void>.delayed(const Duration(milliseconds: 60));
    }

    return deleted;
  }

  Future<Map<String, Map<String, int>>> cleanupSubcollections({
    required String collectionPath,
    required List<String> subcollections,
    bool dryRun = false,
  }) async {
    final parentCol = _collection(collectionPath);
    final parents = await parentCol.get();

    final result = <String, Map<String, int>>{};

    for (final parent in parents.docs) {
      final subResult = <String, int>{};

      for (final sub in subcollections) {
        final subPath = sub.trim();

        if (subPath.isEmpty) continue;

        final subCol = parent.reference.collection(subPath);
        final existing = await _countDocsInCollection(subCol);

        if (dryRun) {
          subResult[subPath] = existing;
        } else {
          subResult[subPath] =
          existing == 0 ? 0 : await _deleteCollectionBatched(subCol);
        }
      }

      result[parent.reference.path] = subResult;

      await Future<void>.delayed(const Duration(milliseconds: 20));
    }

    return result;
  }

  Future<int> deleteIdsUnderEachParent({
    required String parentCollectionPath,
    required String subcollection,
    required List<String> docIds,
    bool dryRun = false,
    int batchSize = 300,
  }) async {
    final parents = await _collection(parentCollectionPath).get();

    int total = 0;

    for (final parent in parents.docs) {
      WriteBatch? batch;
      int pending = 0;

      for (final docId in docIds) {
        final cleanId = docId.trim();

        if (cleanId.isEmpty) continue;

        final docRef = parent.reference.collection(subcollection).doc(cleanId);
        final snap = await docRef.get();

        if (!snap.exists) continue;

        if (dryRun) {
          total++;
          continue;
        }

        batch ??= _db.batch();
        batch.delete(docRef);
        pending++;

        if (pending >= batchSize.clamp(1, 500)) {
          await batch.commit();
          total += pending;
          pending = 0;
          batch = null;

          await Future<void>.delayed(const Duration(milliseconds: 40));
        }
      }

      if (!dryRun && batch != null && pending > 0) {
        await batch.commit();
        total += pending;

        await Future<void>.delayed(const Duration(milliseconds: 40));
      }
    }

    return total;
  }

  Future<int> deleteWhereInCollectionGroup({
    required String subcollection,
    required List<FirebaseWhereFilterData> filters,
    bool dryRun = false,
    int pageSize = 250,
  }) async {
    final cleanSubcollection = subcollection.trim();

    if (cleanSubcollection.isEmpty) {
      throw ArgumentError('Informe o nome da subcoleção.');
    }

    Query<Map<String, dynamic>> query = _db.collectionGroup(cleanSubcollection);

    for (final filter in filters) {
      query = filter.apply(query);
    }

    int total = 0;
    DocumentSnapshot<Map<String, dynamic>>? last;

    while (true) {
      Query<Map<String, dynamic>> pageQuery =
      query.limit(pageSize.clamp(1, 500));

      if (last != null) {
        pageQuery = pageQuery.startAfterDocument(last);
      }

      final snap = await pageQuery.get();

      if (snap.docs.isEmpty) break;

      if (!dryRun) {
        final batch = _db.batch();

        for (final doc in snap.docs) {
          batch.delete(doc.reference);
        }

        await batch.commit();
      }

      total += snap.docs.length;
      last = snap.docs.last;

      await Future<void>.delayed(const Duration(milliseconds: 50));
    }

    return total;
  }

  Future<int> deleteWhereUnderEachParent({
    required String parentCollectionPath,
    required String subcollection,
    required List<FirebaseWhereFilterData> filters,
    bool dryRun = false,
    int pageSize = 250,
  }) async {
    final cleanSubcollection = subcollection.trim();

    if (cleanSubcollection.isEmpty) {
      throw ArgumentError('Informe o nome da subcoleção.');
    }

    final parents = await _collection(parentCollectionPath).get();

    int total = 0;

    for (final parent in parents.docs) {
      Query<Map<String, dynamic>> query =
      parent.reference.collection(cleanSubcollection);

      for (final filter in filters) {
        query = filter.apply(query);
      }

      DocumentSnapshot<Map<String, dynamic>>? last;

      while (true) {
        Query<Map<String, dynamic>> pageQuery =
        query.limit(pageSize.clamp(1, 500));

        if (last != null) {
          pageQuery = pageQuery.startAfterDocument(last);
        }

        final snap = await pageQuery.get();

        if (snap.docs.isEmpty) break;

        if (!dryRun) {
          final batch = _db.batch();

          for (final doc in snap.docs) {
            batch.delete(doc.reference);
          }

          await batch.commit();
        }

        total += snap.docs.length;
        last = snap.docs.last;

        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    }

    return total;
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

class _SubcollectionCopyResult {
  const _SubcollectionCopyResult({
    required this.subcollectionsProcessed,
    required this.docsCopied,
    required this.docsSkipped,
  });

  final int subcollectionsProcessed;
  final int docsCopied;
  final int docsSkipped;
}