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

  Future<FirebaseCopyContractModulesResultData>
  migrateLegacyPublicationAndArchiveToFixedTenant() async {
    emit(
      state.copyWith(
        status: FirebaseAdminStatus.loading,
        clearMessage: true,
        clearResult: true,
        clearProgress: true,
      ),
    );

    try {
      final tenantId = FirebaseAdminTenantPaths.fixedMigrationTenantId;

      final result =
      await _repository.copyLegacyContractModulesToTenantHiringMain(
        params: FirebaseCopyContractModulesParams(
          tenantId: tenantId,
          sourceContractsPath: FirebaseAdminTenantPaths.legacyContractsRootPath,
          targetContractsPath: FirebaseAdminTenantPaths.contractsRootPath(
            tenantId,
          ),
          modules: FirebaseAdminContractModulePaths.officialModules,
          merge: true,
          skipExisting: true,
          addMigrationMetadata: true,
          rewriteDocumentPathFields: true,
          pageSize: 100,
          batchSize: 50,
        ),
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
          message: 'Migração de Publicação/Arquivamento concluída: '
              '${result.totalCopied} documento(s) copiado(s), '
              '${result.totalAlreadyExists} já existente(s), '
              '${result.totalEmpty} vazio(s), '
              '${result.totalSkipped} ignorado(s), '
              '${result.totalContractsWithoutModules} contrato(s) sem '
              'Publicação/Arquivamento.',
          result: FirebaseOperationResultData(
            title:
            'Migração Publicação/Arquivamento para hiring/main do tenant',
            total: result.totalCopied,
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
          message: 'Erro ao migrar Publicação/Arquivamento: $e',
          clearResult: true,
          clearProgress: true,
        ),
      );

      rethrow;
    }
  }

  /// Mantido apenas para não quebrar chamadas antigas da tela enquanto ela
  /// estiver sendo ajustada.
  Future<FirebaseCopyContractModulesResultData>
  migrateLegacyHiringStagesToFixedTenant() {
    return migrateLegacyPublicationAndArchiveToFixedTenant();
  }

  /// Alias semântico.
  Future<FirebaseCopyContractModulesResultData>
  migrateLegacyFinalHiringStagesToFixedTenant() {
    return migrateLegacyPublicationAndArchiveToFixedTenant();
  }

  // ---------------------------------------------------------------------------
  // Prévia / contagem
  // ---------------------------------------------------------------------------

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
}