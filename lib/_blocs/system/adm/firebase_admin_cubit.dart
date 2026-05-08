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

  // ---------------------------------------------------------------------------
  // Migrações oficiais para:
  //
  // tenants/{tenantId}/contracts/{contractId}/{collectionId}/{docId}
  // ---------------------------------------------------------------------------

  Future<FirebaseCopyCollectionGroupResultData>
  migrateLegacyOrdersToFixedTenant() async {
    return copyCollectionGroupToFixedTenantContracts(
      collectionId: 'orders',
      successLabel: 'vigências / ordens',
      successTitle: 'Migração collectionGroup(orders)',
    );
  }

  Future<FirebaseCopyCollectionGroupResultData>
  migrateLegacyValiditiesToFixedTenant() async {
    return migrateLegacyOrdersToFixedTenant();
  }

  Future<FirebaseCopyCollectionGroupResultData>
  migrateLegacyReportsMeasurementToFixedTenant() async {
    return copyCollectionGroupToFixedTenantContracts(
      collectionId: 'reportsMeasurement',
      successLabel: 'medições executadas',
      successTitle: 'Migração collectionGroup(reportsMeasurement)',
    );
  }

  Future<FirebaseCopyCollectionGroupResultData>
  migrateLegacyAdjustmentsMeasurementToFixedTenant() async {
    return copyCollectionGroupToFixedTenantContracts(
      collectionId: 'adjustmentsMeasurement',
      successLabel: 'reajustes de medições',
      successTitle: 'Migração collectionGroup(adjustmentsMeasurement)',
    );
  }

  Future<FirebaseCopyCollectionGroupResultData>
  migrateLegacyRevisionsMeasurementToFixedTenant() async {
    return copyCollectionGroupToFixedTenantContracts(
      collectionId: 'revisionsMeasurement',
      successLabel: 'revisões de medições',
      successTitle: 'Migração collectionGroup(revisionsMeasurement)',
    );
  }

  Future<List<FirebaseCopyCollectionGroupResultData>>
  migrateAllMeasurementCollectionsToFixedTenant() async {
    final results = <FirebaseCopyCollectionGroupResultData>[];

    results.add(await migrateLegacyReportsMeasurementToFixedTenant());
    results.add(await migrateLegacyAdjustmentsMeasurementToFixedTenant());
    results.add(await migrateLegacyRevisionsMeasurementToFixedTenant());

    return results;
  }

  Future<List<FirebaseCopyCollectionGroupResultData>>
  migrateAllContractOperationalCollectionsToFixedTenant() async {
    final results = <FirebaseCopyCollectionGroupResultData>[];

    results.add(await migrateLegacyOrdersToFixedTenant());
    results.add(await migrateLegacyReportsMeasurementToFixedTenant());
    results.add(await migrateLegacyAdjustmentsMeasurementToFixedTenant());
    results.add(await migrateLegacyRevisionsMeasurementToFixedTenant());

    return results;
  }

  Future<FirebaseCopyCollectionGroupResultData>
  copyCollectionGroupToFixedTenantContracts({
    required String collectionId,
    String? successTitle,
    String? successLabel,
  }) async {
    final cleanCollectionId = collectionId.trim();

    if (cleanCollectionId.isEmpty) {
      throw ArgumentError('Informe o nome da collectionGroup.');
    }

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
      final targetPath = FirebaseAdminTenantPaths.contractsRootPath(tenantId);

      final result = await _repository.copyCollectionGroupToCollection(
        params: FirebaseCopyCollectionGroupParams(
          collectionId: cleanCollectionId,
          targetPath: targetPath,
          tenantId: tenantId,
          merge: true,
          skipExisting: true,
          addMigrationMetadata: true,
          rewriteDocumentPathFields: true,
          pageSize: 100,
          batchSize: 50,
          targetPlacementMode:
          FirebaseCollectionGroupTargetPlacementMode
              .tenantContractSubcollection,
          targetDocIdMode: FirebaseCollectionGroupTargetDocIdMode.originalId,
          excludePathPrefixes: const <String>[
            'tenants/',
          ],
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

      final label = successLabel ?? cleanCollectionId;

      emit(
        state.copyWith(
          status: FirebaseAdminStatus.success,
          message: 'Migração de $label concluída: '
              '${result.totalCopied} copiado(s), '
              '${result.totalAlreadyExists} já existente(s), '
              '${result.totalExcludedByPath} ignorado(s) por já estarem em tenants/, '
              '${result.totalMissingContractId} sem contractId, '
              '${result.totalSkipped} ignorado(s) no total.',
          result: FirebaseOperationResultData(
            title: successTitle ??
                'Migração collectionGroup($cleanCollectionId) para contratos do tenant',
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
          message:
          'Erro ao migrar collectionGroup($cleanCollectionId) para contratos do tenant: $e',
          clearResult: true,
          clearProgress: true,
        ),
      );

      rethrow;
    }
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