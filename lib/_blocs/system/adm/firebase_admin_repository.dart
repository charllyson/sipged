// lib/_blocs/system/adm/firebase_admin_repository.dart

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

  // ===========================================================================
  // CollectionGroup -> Collection / Contract Subcollection
  // ===========================================================================

  Future<FirebaseCopyCollectionGroupResultData> copyCollectionGroupToCollection({
    required FirebaseCopyCollectionGroupParams params,
    void Function(
        int current,
        int total,
        String label,
        String? detail,
        )? onProgress,
  }) async {
    final cleanCollectionId = params.collectionId.trim();
    final cleanTargetPath = params.targetPath.trim();
    final cleanTenantId = params.tenantId.trim().isEmpty
        ? FirebaseAdminTenantPaths.fixedMigrationTenantId
        : params.tenantId.trim();

    if (cleanCollectionId.isEmpty) {
      throw ArgumentError('Informe o ID da collectionGroup.');
    }

    _validateCollectionPath(cleanTargetPath);

    final targetRootCol = _collection(cleanTargetPath);

    int scanned = 0;
    int copied = 0;
    int skipped = 0;
    int alreadyExists = 0;
    int empty = 0;
    int excludedByPath = 0;
    int missingContractId = 0;

    final pageSize = params.pageSize.clamp(1, 200);
    final batchSize = params.batchSize.clamp(1, 100);

    DocumentSnapshot<Map<String, dynamic>>? last;
    final pendingWrites = <_PendingWrite>[];

    onProgress?.call(
      0,
      1,
      'Iniciando collectionGroup...',
      params.targetPlacementMode ==
          FirebaseCollectionGroupTargetPlacementMode
              .tenantContractSubcollection
          ? 'Origem: collectionGroup("$cleanCollectionId") → Destino: $cleanTargetPath/{contractId}/$cleanCollectionId/{docId}'
          : 'Origem: collectionGroup("$cleanCollectionId") → Destino: $cleanTargetPath',
    );

    while (true) {
      Query<Map<String, dynamic>> query = _db
          .collectionGroup(cleanCollectionId)
          .orderBy(FieldPath.documentId)
          .limit(pageSize);

      if (last != null) {
        query = query.startAfterDocument(last);
      }

      final snap = await query.get();

      if (snap.docs.isEmpty) break;

      for (final sourceDoc in snap.docs) {
        scanned++;

        final sourcePath = sourceDoc.reference.path;

        final shouldExclude = params.excludePathPrefixes.any((prefix) {
          final cleanPrefix = prefix.trim();

          if (cleanPrefix.isEmpty) return false;

          return sourcePath.startsWith(cleanPrefix);
        });

        if (shouldExclude) {
          excludedByPath++;
          skipped++;
          continue;
        }

        final data = sourceDoc.data();

        if (data.isEmpty) {
          empty++;
          skipped++;
          continue;
        }

        final parentId = _resolveContractIdForCollectionGroupDoc(
          sourceDoc.reference,
          collectionId: cleanCollectionId,
          data: data,
        );

        final DocumentReference<Map<String, dynamic>> targetDocRef;
        final String targetDocId;

        switch (params.targetPlacementMode) {
          case FirebaseCollectionGroupTargetPlacementMode.singleTargetCollection:
            targetDocId = _targetDocIdForCollectionGroupDoc(
              sourceDoc: sourceDoc,
              parentId: parentId,
              mode: params.targetDocIdMode,
            );

            targetDocRef = targetRootCol.doc(targetDocId);
            break;

          case FirebaseCollectionGroupTargetPlacementMode
              .tenantContractSubcollection:
            final cleanParentId = parentId?.trim();

            if (cleanParentId == null || cleanParentId.isEmpty) {
              missingContractId++;
              skipped++;

              onProgress?.call(
                scanned,
                1,
                'Documento ignorado...',
                'Não foi possível identificar contractId em: $sourcePath',
              );

              continue;
            }

            targetDocId = _safeDocId(sourceDoc.id);

            targetDocRef = targetRootCol
                .doc(_safeDocId(cleanParentId))
                .collection(cleanCollectionId)
                .doc(targetDocId);

            break;
        }

        if (params.skipExisting) {
          final targetSnap = await targetDocRef.get();

          if (targetSnap.exists) {
            alreadyExists++;
            skipped++;
            continue;
          }
        }

        final toCopy = _buildCopyData(
          sourcePath: sourcePath,
          docId: sourceDoc.id,
          data: data,
          addMigrationMetadata: params.addMigrationMetadata,
          targetDocPath: targetDocRef.path,
          rewriteDocumentPathFields: params.rewriteDocumentPathFields,
        );

        if (toCopy.isEmpty) {
          empty++;
          skipped++;
          continue;
        }

        toCopy['id'] = targetDocId;
        toCopy['tenantId'] = cleanTenantId;
        toCopy['companyId'] = cleanTenantId;
        toCopy['legacySourceId'] = sourceDoc.id;
        toCopy['legacySourcePath'] = sourcePath;
        toCopy['recordPath'] = targetDocRef.path;
        toCopy['sourceCollectionModel'] =
        'tenant_contract_${cleanCollectionId.trim()}';

        if (parentId != null && parentId.trim().isNotEmpty) {
          toCopy['contractId'] = parentId.trim();
          toCopy['uidContract'] = parentId.trim();
          toCopy['uidcontract'] = parentId.trim();
          toCopy['legacyContractId'] = parentId.trim();
        }

        pendingWrites.add(
          _PendingWrite(
            docId: targetDocId,
            ref: targetDocRef,
            data: toCopy,
            merge: params.merge,
          ),
        );

        onProgress?.call(
          scanned,
          1,
          'Preparando documentos...',
          'Documento: $sourcePath → ${targetDocRef.path}',
        );

        if (pendingWrites.length >= batchSize) {
          copied += await _commitPendingWritesSafely(
            writes: pendingWrites,
            current: scanned,
            total: 1,
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
        current: scanned,
        total: 1,
        onProgress: onProgress,
      );

      pendingWrites.clear();
    }

    return FirebaseCopyCollectionGroupResultData(
      collectionId: cleanCollectionId,
      targetPath: cleanTargetPath,
      totalScanned: scanned,
      totalCopied: copied,
      totalSkipped: skipped,
      totalAlreadyExists: alreadyExists,
      totalEmpty: empty,
      totalExcludedByPath: excludedByPath,
      totalMissingContractId: missingContractId,
    );
  }

  String _targetDocIdForCollectionGroupDoc({
    required QueryDocumentSnapshot<Map<String, dynamic>> sourceDoc,
    required String? parentId,
    required FirebaseCollectionGroupTargetDocIdMode mode,
  }) {
    switch (mode) {
      case FirebaseCollectionGroupTargetDocIdMode.originalId:
        return _safeDocId(sourceDoc.id);

      case FirebaseCollectionGroupTargetDocIdMode.parentIdAndOriginalId:
        final cleanParent = parentId?.trim();

        if (cleanParent == null || cleanParent.isEmpty) {
          return _safeDocId(sourceDoc.id);
        }

        return '${_safeDocId(cleanParent)}_${_safeDocId(sourceDoc.id)}';
    }
  }

  String? _resolveContractIdForCollectionGroupDoc(
      DocumentReference<Map<String, dynamic>> ref, {
        required String collectionId,
        required Map<String, dynamic> data,
      }) {
    final fromData = _stringFromAny(
      data['contractId'] ??
          data['uidContract'] ??
          data['uidcontract'] ??
          data['uidContrato'] ??
          data['idContract'] ??
          data['contract'],
    );

    if (fromData != null &&
        fromData.trim().isNotEmpty &&
        !_isKnownNonContractSegment(fromData, collectionId)) {
      return fromData.trim();
    }

    final parts = ref.path
        .split('/')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();

    for (int i = 0; i < parts.length - 1; i++) {
      if (parts[i] != 'contracts') continue;

      final candidate = parts[i + 1].trim();

      if (candidate.isEmpty) continue;

      if (_isKnownNonContractSegment(candidate, collectionId)) {
        continue;
      }

      return candidate;
    }

    final parentParentId = ref.parent.parent?.id;

    if (parentParentId != null && parentParentId.trim().isNotEmpty) {
      final clean = parentParentId.trim();

      if (!_isKnownNonContractSegment(clean, collectionId)) {
        return clean;
      }
    }

    return null;
  }

  String? _stringFromAny(dynamic value) {
    if (value == null) return null;

    final text = value.toString().trim();

    if (text.isEmpty || text.toLowerCase() == 'null') return null;

    return text;
  }

  bool _isKnownNonContractSegment(String value, String collectionId) {
    final clean = value.trim();

    if (clean.isEmpty) return true;

    return clean == collectionId ||
        clean == 'items' ||
        clean == 'orders' ||
        clean == 'validities' ||
        clean == 'validity' ||
        clean == 'additives' ||
        clean == 'apostilles' ||
        clean == 'measurements' ||
        clean == 'reports' ||
        clean == 'reportsMeasurement' ||
        clean == 'adjustmentsMeasurement' ||
        clean == 'revisionsMeasurement' ||
        clean == 'payments' ||
        clean == 'breakdownMeta' ||
        clean == 'rows' ||
        clean == 'rows_v' ||
        clean == 'groups';
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