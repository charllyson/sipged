// lib/_blocs/system/adm/firebase_admin_cubit.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/system/adm/firebase_admin_data.dart';
import 'package:sipged/_blocs/system/adm/firebase_admin_repository.dart';
import 'package:sipged/_blocs/system/adm/firebase_admin_state.dart';

class FirebaseAdminCubit extends Cubit<FirebaseAdminState> {
  FirebaseAdminCubit({
    FirebaseAdminRepository? repository,
  })  : _repository = repository ?? FirebaseAdminRepository(),
        super(FirebaseAdminState.initial());

  final FirebaseAdminRepository _repository;

  void clearFeedback() {
    emit(
      state.copyWith(
        status: FirebaseAdminStatus.initial,
        clearMessage: true,
        clearResult: true,
        clearProgress: true,
      ),
    );
  }

  Future<FirebaseLegacyCompanyMigrationResultData>
  migrateLegacyCompanyToTenant({
    required String tenantId,
    bool merge = true,
    bool skipExisting = false,
    bool addMigrationMetadata = true,
    bool rewriteDocumentPathFields = true,
    bool copySubcollectionsWhenTargetExists = true,
  }) async {
    emit(
      state.copyWith(
        status: FirebaseAdminStatus.loading,
        clearMessage: true,
        clearResult: true,
        clearProgress: true,
      ),
    );

    try {
      final result = await _repository.migrateLegacyCompanyToTenant(
        tenantId: tenantId,
        merge: merge,
        skipExisting: skipExisting,
        addMigrationMetadata: addMigrationMetadata,
        rewriteDocumentPathFields: rewriteDocumentPathFields,
        copySubcollectionsWhenTargetExists:
        copySubcollectionsWhenTargetExists,
        onProgress: (current, total, label, detail) {
          emit(
            state.copyWith(
              status: FirebaseAdminStatus.loading,
              progressCurrent: current,
              progressTotal: total,
              progressLabel: label,
              progressDetail: detail,
            ),
          );
        },
      );

      emit(
        state.copyWith(
          status: FirebaseAdminStatus.success,
          message: 'Migração concluída: '
              '${result.documentCopied ? 1 : 0} documento principal copiado, '
              '${result.totalSubcollectionDocsCopied} subdocumento(s) copiado(s), '
              '${result.totalSubcollectionDocsSkipped} ignorado(s).',
          result: FirebaseOperationResultData(
            title: 'Migração legacy company para tenant',
            total: result.totalEverythingCopied,
            details: result.toMap(),
          ),
          clearProgress: true,
        ),
      );

      return result;
    } catch (e) {
      emit(
        state.copyWith(
          status: FirebaseAdminStatus.failure,
          message: 'Erro ao migrar company para tenant: $e',
          clearResult: true,
          clearProgress: true,
        ),
      );

      rethrow;
    }
  }

  Future<FirebaseCopyDocumentResultData> copyDocumentToDocument(
      FirebaseCopyDocumentParams params,
      ) async {
    emit(
      state.copyWith(
        status: FirebaseAdminStatus.loading,
        clearMessage: true,
        clearResult: true,
        clearProgress: true,
      ),
    );

    try {
      final result = await _repository.copyDocumentToDocument(
        params: params,
        onProgress: (current, total, label, detail) {
          emit(
            state.copyWith(
              status: FirebaseAdminStatus.loading,
              progressCurrent: current,
              progressTotal: total,
              progressLabel: label,
              progressDetail: detail,
            ),
          );
        },
      );

      emit(
        state.copyWith(
          status: FirebaseAdminStatus.success,
          message: 'Migração concluída: '
              '${result.documentCopied ? 1 : 0} documento principal copiado, '
              '${result.totalSubcollectionDocsCopied} subdocumento(s) copiado(s), '
              '${result.totalSubcollectionDocsSkipped} ignorado(s).',
          result: FirebaseOperationResultData(
            title: 'Cópia de documento para tenant',
            total: result.totalEverythingCopied,
            details: result.toMap(),
          ),
          clearProgress: true,
        ),
      );

      return result;
    } catch (e) {
      emit(
        state.copyWith(
          status: FirebaseAdminStatus.failure,
          message: 'Erro ao copiar documento: $e',
          clearResult: true,
          clearProgress: true,
        ),
      );

      rethrow;
    }
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> previewCollection({
    required String path,
    int limit = 50,
  }) async {
    emit(
      state.copyWith(
        status: FirebaseAdminStatus.loading,
        clearMessage: true,
        clearResult: true,
        clearProgress: true,
      ),
    );

    try {
      final docs = await _repository.previewCollection(
        path: path,
        limit: limit,
      );

      emit(
        state.copyWith(
          status: FirebaseAdminStatus.success,
          message: 'Prévia carregada: ${docs.length} documento(s).',
          result: FirebaseOperationResultData(
            title: 'Prévia da coleção',
            total: docs.length,
            details: {
              'path': path,
              'limit': limit,
            },
          ),
          clearProgress: true,
        ),
      );

      return docs;
    } catch (e) {
      emit(
        state.copyWith(
          status: FirebaseAdminStatus.failure,
          message: 'Erro ao carregar prévia: $e',
          clearResult: true,
          clearProgress: true,
        ),
      );

      rethrow;
    }
  }

  Future<int> previewCollectionCount(String path) async {
    emit(
      state.copyWith(
        status: FirebaseAdminStatus.loading,
        clearMessage: true,
        clearResult: true,
        clearProgress: true,
      ),
    );

    try {
      final count = await _repository.countCollectionDocs(path);

      emit(
        state.copyWith(
          status: FirebaseAdminStatus.success,
          message: 'Prévia concluída: $count documento(s) encontrado(s).',
          result: FirebaseOperationResultData(
            title: 'Prévia da coleção',
            total: count,
            details: {
              'path': path,
              'count': count,
            },
          ),
          clearProgress: true,
        ),
      );

      return count;
    } catch (e) {
      emit(
        state.copyWith(
          status: FirebaseAdminStatus.failure,
          message: 'Erro ao contar documentos: $e',
          clearResult: true,
          clearProgress: true,
        ),
      );

      rethrow;
    }
  }

  Future<FirebaseCopyCollectionResultData> copyCollectionDocuments(
      FirebaseCopyCollectionParams params,
      ) async {
    emit(
      state.copyWith(
        status: FirebaseAdminStatus.loading,
        clearMessage: true,
        clearResult: true,
        clearProgress: true,
      ),
    );

    try {
      final result = await _repository.copyCollectionDocuments(
        params: params,
        onProgress: (current, total, label, detail) {
          emit(
            state.copyWith(
              status: FirebaseAdminStatus.loading,
              progressCurrent: current,
              progressTotal: total,
              progressLabel: label,
              progressDetail: detail,
            ),
          );
        },
      );

      emit(
        state.copyWith(
          status: FirebaseAdminStatus.success,
          message: 'Cópia concluída: '
              '${result.totalCopied} documento(s) principal(is) copiado(s), '
              '${result.totalSubcollectionDocsCopied} subdocumento(s) copiado(s), '
              '${result.totalAlreadyExists} já existente(s), '
              '${result.totalSkipped + result.totalSubcollectionDocsSkipped} ignorado(s).',
          result: FirebaseOperationResultData(
            title: 'Cópia de coleção',
            total: result.totalEverythingCopied,
            details: result.toMap(),
          ),
          clearProgress: true,
        ),
      );

      return result;
    } catch (e) {
      emit(
        state.copyWith(
          status: FirebaseAdminStatus.failure,
          message: 'Erro ao copiar documentos: $e',
          clearResult: true,
          clearProgress: true,
        ),
      );

      rethrow;
    }
  }

  Future<void> deleteCollectionCompletely(String path) async {
    emit(
      state.copyWith(
        status: FirebaseAdminStatus.loading,
        clearMessage: true,
        clearResult: true,
        clearProgress: true,
      ),
    );

    try {
      final deleted = await _repository.deleteCollectionCompletely(path: path);

      emit(
        state.copyWith(
          status: FirebaseAdminStatus.success,
          message: 'Coleção apagada: $deleted documento(s).',
          result: FirebaseOperationResultData(
            title: 'Coleção apagada',
            total: deleted,
            details: {
              'path': path,
              'deleted': deleted,
            },
          ),
          clearProgress: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: FirebaseAdminStatus.failure,
          message: 'Erro ao apagar coleção: $e',
          clearResult: true,
          clearProgress: true,
        ),
      );
    }
  }

  Future<Map<String, Map<String, int>>> previewCleanupSubcollections(
      FirebaseCleanupSubcollectionsParams params,
      ) async {
    emit(
      state.copyWith(
        status: FirebaseAdminStatus.loading,
        clearMessage: true,
        clearResult: true,
        clearProgress: true,
      ),
    );

    try {
      final result = await _repository.cleanupSubcollections(
        collectionPath: params.collectionPath,
        subcollections: params.subcollections,
        dryRun: true,
      );

      final total = _sumNested(result);

      emit(
        state.copyWith(
          status: FirebaseAdminStatus.success,
          message: 'Prévia concluída: $total subdocumento(s) encontrado(s).',
          result: FirebaseOperationResultData(
            title: 'Prévia de limpeza',
            total: total,
            details: {
              'collectionPath': params.collectionPath,
              'subcollections': params.subcollections,
              'items': result,
            },
          ),
          clearProgress: true,
        ),
      );

      return result;
    } catch (e) {
      emit(
        state.copyWith(
          status: FirebaseAdminStatus.failure,
          message: 'Erro na prévia da limpeza: $e',
          clearResult: true,
          clearProgress: true,
        ),
      );

      rethrow;
    }
  }

  Future<void> cleanupSubcollections(
      FirebaseCleanupSubcollectionsParams params,
      ) async {
    emit(
      state.copyWith(
        status: FirebaseAdminStatus.loading,
        clearMessage: true,
        clearResult: true,
        clearProgress: true,
      ),
    );

    try {
      final result = await _repository.cleanupSubcollections(
        collectionPath: params.collectionPath,
        subcollections: params.subcollections,
        dryRun: false,
      );

      final total = _sumNested(result);

      emit(
        state.copyWith(
          status: FirebaseAdminStatus.success,
          message: 'Limpeza concluída: $total subdocumento(s) apagado(s).',
          result: FirebaseOperationResultData(
            title: 'Limpeza concluída',
            total: total,
            details: {
              'collectionPath': params.collectionPath,
              'subcollections': params.subcollections,
              'items': result,
            },
          ),
          clearProgress: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: FirebaseAdminStatus.failure,
          message: 'Erro ao limpar subcoleções: $e',
          clearResult: true,
          clearProgress: true,
        ),
      );
    }
  }

  Future<int> previewSelectiveDeleteByIds(
      FirebaseSelectiveDeleteByIdsParams params,
      ) async {
    emit(
      state.copyWith(
        status: FirebaseAdminStatus.loading,
        clearMessage: true,
        clearResult: true,
        clearProgress: true,
      ),
    );

    try {
      final total = await _repository.deleteIdsUnderEachParent(
        parentCollectionPath: params.parentCollectionPath,
        subcollection: params.subcollection,
        docIds: params.docIds,
        dryRun: true,
      );

      emit(
        state.copyWith(
          status: FirebaseAdminStatus.success,
          message: 'Prévia concluída: $total documento(s) encontrado(s).',
          result: FirebaseOperationResultData(
            title: 'Prévia de deleção seletiva',
            total: total,
            details: {
              'parentCollectionPath': params.parentCollectionPath,
              'subcollection': params.subcollection,
              'docIds': params.docIds,
            },
          ),
          clearProgress: true,
        ),
      );

      return total;
    } catch (e) {
      emit(
        state.copyWith(
          status: FirebaseAdminStatus.failure,
          message: 'Erro na prévia por IDs: $e',
          clearResult: true,
          clearProgress: true,
        ),
      );

      rethrow;
    }
  }

  Future<void> selectiveDeleteByIds(
      FirebaseSelectiveDeleteByIdsParams params,
      ) async {
    emit(
      state.copyWith(
        status: FirebaseAdminStatus.loading,
        clearMessage: true,
        clearResult: true,
        clearProgress: true,
      ),
    );

    try {
      final total = await _repository.deleteIdsUnderEachParent(
        parentCollectionPath: params.parentCollectionPath,
        subcollection: params.subcollection,
        docIds: params.docIds,
        dryRun: false,
      );

      emit(
        state.copyWith(
          status: FirebaseAdminStatus.success,
          message: 'Deleção concluída: $total documento(s) apagado(s).',
          result: FirebaseOperationResultData(
            title: 'Deleção seletiva por IDs',
            total: total,
            details: {
              'parentCollectionPath': params.parentCollectionPath,
              'subcollection': params.subcollection,
              'docIds': params.docIds,
            },
          ),
          clearProgress: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: FirebaseAdminStatus.failure,
          message: 'Erro ao apagar por IDs: $e',
          clearResult: true,
          clearProgress: true,
        ),
      );
    }
  }

  Future<int> previewSelectiveDeleteByFilter(
      FirebaseSelectiveDeleteByFilterParams params,
      ) async {
    emit(
      state.copyWith(
        status: FirebaseAdminStatus.loading,
        clearMessage: true,
        clearResult: true,
        clearProgress: true,
      ),
    );

    try {
      final total = params.useParents
          ? await _repository.deleteWhereUnderEachParent(
        parentCollectionPath: params.parentCollectionPath,
        subcollection: params.subcollection,
        filters: params.filters,
        dryRun: true,
      )
          : await _repository.deleteWhereInCollectionGroup(
        subcollection: params.subcollection,
        filters: params.filters,
        dryRun: true,
      );

      emit(
        state.copyWith(
          status: FirebaseAdminStatus.success,
          message: 'Prévia concluída: $total documento(s) encontrado(s).',
          result: FirebaseOperationResultData(
            title: 'Prévia de deleção por filtro',
            total: total,
            details: {
              'parentCollectionPath': params.parentCollectionPath,
              'subcollection': params.subcollection,
              'useParents': params.useParents,
            },
          ),
          clearProgress: true,
        ),
      );

      return total;
    } catch (e) {
      emit(
        state.copyWith(
          status: FirebaseAdminStatus.failure,
          message: 'Erro na prévia por filtro: $e',
          clearResult: true,
          clearProgress: true,
        ),
      );

      rethrow;
    }
  }

  Future<void> selectiveDeleteByFilter(
      FirebaseSelectiveDeleteByFilterParams params,
      ) async {
    emit(
      state.copyWith(
        status: FirebaseAdminStatus.loading,
        clearMessage: true,
        clearResult: true,
        clearProgress: true,
      ),
    );

    try {
      final total = params.useParents
          ? await _repository.deleteWhereUnderEachParent(
        parentCollectionPath: params.parentCollectionPath,
        subcollection: params.subcollection,
        filters: params.filters,
        dryRun: false,
      )
          : await _repository.deleteWhereInCollectionGroup(
        subcollection: params.subcollection,
        filters: params.filters,
        dryRun: false,
      );

      emit(
        state.copyWith(
          status: FirebaseAdminStatus.success,
          message: 'Deleção concluída: $total documento(s) apagado(s).',
          result: FirebaseOperationResultData(
            title: 'Deleção seletiva por filtro',
            total: total,
            details: {
              'parentCollectionPath': params.parentCollectionPath,
              'subcollection': params.subcollection,
              'useParents': params.useParents,
            },
          ),
          clearProgress: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: FirebaseAdminStatus.failure,
          message: 'Erro ao apagar por filtro: $e',
          clearResult: true,
          clearProgress: true,
        ),
      );
    }
  }

  int _sumNested(Map<String, Map<String, int>> data) {
    int total = 0;

    for (final docEntry in data.values) {
      for (final value in docEntry.values) {
        total += value;
      }
    }

    return total;
  }
}