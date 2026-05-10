// lib/_blocs/modules/contracts/measurement/report/report_executed_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/system/permission/permission_data.dart';
import 'package:sipged/_widgets/list/files/attachment.dart';

import 'report_executed_data.dart';
import 'report_executed_repository.dart';
import 'report_executed_state.dart';

class ReportExecutedCubit extends Cubit<ReportExecutedState> {
  ReportExecutedCubit({
    ReportExecutedRepository? repository,
    UserPermissionData? initialPermissions,
    String? initialTenantId,
    this.moduleId = 'operation_measurements',
  })  : _repo = repository ?? ReportExecutedRepository(),
        _currentPermissions = initialPermissions,
        _tenantId = _resolveInitialTenantId(
          tenantId: initialTenantId,
          permissions: initialPermissions,
        ),
        super(ReportExecutedState.initial()) {
    _syncRepositoryTenant();
  }

  final ReportExecutedRepository _repo;
  final String moduleId;

  UserPermissionData? _currentPermissions;
  String? _tenantId;

  static String? _cleanTenantId(String? value) {
    final clean = value?.trim();
    return clean == null || clean.isEmpty ? null : clean;
  }

  static String? _resolveInitialTenantId({
    required String? tenantId,
    required UserPermissionData? permissions,
  }) {
    final direct = _cleanTenantId(tenantId);

    if (direct != null) {
      return direct;
    }

    final permissionTenant = _cleanTenantId(permissions?.activeTenantId);

    if (permissionTenant != null) {
      return permissionTenant;
    }

    return null;
  }

  void _syncRepositoryTenant() {
    _repo.setActiveTenantId(_tenantId);
  }

  void setTenantId(String? tenantId) {
    final previousTenantId = _tenantId;

    _tenantId = _cleanTenantId(tenantId);
    _syncRepositoryTenant();

    final currentContractId = state.contractId?.trim();

    if (previousTenantId != _tenantId &&
        currentContractId != null &&
        currentContractId.isNotEmpty) {
      Future.microtask(() => loadByContract(currentContractId));
    }
  }

  bool get _hasTenantId {
    final clean = _tenantId?.trim();
    return clean != null && clean.isNotEmpty;
  }

  String _requireTenantId() {
    final clean = _tenantId?.trim();

    if (clean == null || clean.isEmpty) {
      throw Exception(
        'Nenhuma empresa ativa foi selecionada para acessar medições.',
      );
    }

    _repo.setActiveTenantId(clean);

    return clean;
  }

  void updatePermissions({
    UserPermissionData? permissions,
    String? tenantId,
  }) {
    final previousTenantId = _tenantId;

    _currentPermissions = permissions ?? _currentPermissions;

    final resolvedTenantId = _resolveInitialTenantId(
      tenantId: tenantId,
      permissions: _currentPermissions,
    );

    if (resolvedTenantId != null) {
      _tenantId = resolvedTenantId;
    }

    _syncRepositoryTenant();

    final currentContractId = state.contractId?.trim();

    if (previousTenantId != _tenantId &&
        currentContractId != null &&
        currentContractId.isNotEmpty) {
      Future.microtask(() => loadByContract(currentContractId));
    }
  }

  bool get isEditable => _canWrite();

  bool _canWrite() {
    final permissions = _currentPermissions;

    if (permissions == null) return false;

    if (permissions.isGlobalSuperUser ||
        permissions.isSuperUserForTenant(_tenantId)) {
      return true;
    }

    return permissions.canModuleString(
      module: moduleId,
      action: 'create',
      tenantId: _tenantId,
    ) ||
        permissions.canModuleString(
          module: moduleId,
          action: 'edit',
          tenantId: _tenantId,
        ) ||
        permissions.canModuleString(
          module: moduleId,
          action: 'delete',
          tenantId: _tenantId,
        );
  }

  bool _canDelete() {
    final permissions = _currentPermissions;

    if (permissions == null) return false;

    if (permissions.isGlobalSuperUser ||
        permissions.isSuperUserForTenant(_tenantId)) {
      return true;
    }

    return permissions.canModuleString(
      module: moduleId,
      action: 'delete',
      tenantId: _tenantId,
    );
  }

  void _assertCanWrite() {
    _requireTenantId();

    if (_canWrite()) return;

    throw Exception(
      'Usuário sem permissão para alterar medições. '
          'Módulo: $moduleId | tenantId: ${_tenantId ?? 'não definido'}',
    );
  }

  void _assertCanDelete() {
    _requireTenantId();

    if (_canDelete()) return;

    throw Exception(
      'Usuário sem permissão para apagar medições. '
          'Módulo: $moduleId | tenantId: ${_tenantId ?? 'não definido'}',
    );
  }

  Future<void> loadByContract(String contractId) async {
    _syncRepositoryTenant();

    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) {
      emit(
        state.copyWith(
          status: ReportExecutedStatus.success,
          measurements: const <ReportExecutedData>[],
          error: null,
          contractId: null,
          uploading: false,
          uploadProgress: null,
        ),
      );
      return;
    }

    if (!_hasTenantId) {
      emit(
        state.copyWith(
          status: ReportExecutedStatus.failure,
          measurements: const <ReportExecutedData>[],
          error: 'Nenhuma empresa ativa foi selecionada.',
          contractId: cleanContractId,
          uploading: false,
          uploadProgress: null,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: ReportExecutedStatus.loading,
        error: null,
        contractId: cleanContractId,
        uploading: false,
        uploadProgress: null,
      ),
    );

    try {
      final list = await _repo.getAllMeasurementsOfContract(
        uidContract: cleanContractId,
      );

      emit(
        state.copyWith(
          status: ReportExecutedStatus.success,
          measurements: list,
          error: null,
          contractId: cleanContractId,
          uploading: false,
          uploadProgress: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ReportExecutedStatus.failure,
          error: e.toString(),
          uploading: false,
          uploadProgress: null,
        ),
      );
    }
  }

  Future<List<ReportExecutedData>> getAllMeasurementsCollectionGroup() {
    _syncRepositoryTenant();
    return _repo.getAllMeasurementsCollectionGroup();
  }

  Future<void> saveOrUpdate(ReportExecutedData data) async {
    _assertCanWrite();

    final contractId = (data.contractId ?? state.contractId)?.trim();

    if (contractId == null || contractId.isEmpty) {
      throw Exception('contractId é obrigatório para salvar a medição.');
    }

    try {
      await _repo.saveOrUpdateReport(
        data.copyWith(contractId: contractId),
      );

      if (state.contractId == null || state.contractId == contractId) {
        await loadByContract(contractId);
      }
    } catch (_) {
      rethrow;
    }
  }

  Future<void> delete({
    required String contractId,
    required String measurementId,
  }) async {
    _assertCanDelete();

    final cleanContractId = contractId.trim();
    final cleanMeasurementId = measurementId.trim();

    if (cleanContractId.isEmpty || cleanMeasurementId.isEmpty) {
      throw Exception('contractId e measurementId são obrigatórios.');
    }

    try {
      await _repo.deleteMeasurement(
        contractId: cleanContractId,
        measurementId: cleanMeasurementId,
      );

      if (state.contractId == cleanContractId) {
        await loadByContract(cleanContractId);
      }
    } catch (_) {
      rethrow;
    }
  }

  double sum(List<ReportExecutedData> list) {
    return _repo.somarValorMedicoes(list);
  }

  Future<Attachment> pickAndUploadAttachment({
    required String contractId,
    required String measurementId,
  }) async {
    _assertCanWrite();

    final cleanContractId = contractId.trim();
    final cleanMeasurementId = measurementId.trim();

    if (cleanContractId.isEmpty || cleanMeasurementId.isEmpty) {
      throw Exception('contractId e measurementId são obrigatórios.');
    }

    emit(
      state.copyWith(
        uploading: true,
        uploadProgress: 0.0,
        error: null,
      ),
    );

    try {
      final att = await _repo.pickAndUploadAttachment(
        contractId: cleanContractId,
        measurementId: cleanMeasurementId,
        onProgress: (progress) {
          final value = progress.isNaN ? 0.0 : progress.clamp(0.0, 1.0);

          emit(
            state.copyWith(
              uploading: true,
              uploadProgress: value.toDouble(),
            ),
          );
        },
      );

      if (state.contractId == cleanContractId) {
        await loadByContract(cleanContractId);
      }

      emit(
        state.copyWith(
          uploading: false,
          uploadProgress: null,
          error: null,
        ),
      );

      return att;
    } catch (e) {
      emit(
        state.copyWith(
          uploading: false,
          uploadProgress: null,
          error: e.toString(),
        ),
      );

      rethrow;
    }
  }

  Future<void> deleteAttachment({
    required String contractId,
    required String measurementId,
    required Attachment attachment,
  }) async {
    _assertCanWrite();

    final cleanContractId = contractId.trim();
    final cleanMeasurementId = measurementId.trim();

    if (cleanContractId.isEmpty || cleanMeasurementId.isEmpty) return;

    await _repo.deleteAttachment(
      contractId: cleanContractId,
      measurementId: cleanMeasurementId,
      attachment: attachment,
    );

    if (state.contractId == cleanContractId) {
      await loadByContract(cleanContractId);
    }
  }

  Future<void> renameAttachmentLabel({
    required String contractId,
    required String measurementId,
    required Attachment oldItem,
    required Attachment newItem,
  }) async {
    _assertCanWrite();

    final cleanContractId = contractId.trim();
    final cleanMeasurementId = measurementId.trim();

    if (cleanContractId.isEmpty || cleanMeasurementId.isEmpty) return;

    await _repo.renameAttachmentLabel(
      contractId: cleanContractId,
      measurementId: cleanMeasurementId,
      oldItem: oldItem,
      newItem: newItem,
    );

    if (state.contractId == cleanContractId) {
      await loadByContract(cleanContractId);
    }
  }
}