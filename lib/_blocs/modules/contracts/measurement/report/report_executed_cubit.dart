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
    required String initialTenantId,
    this.moduleId = 'operation_measurements',
  })  : _repo = repository ??
      ReportExecutedRepository(
        tenantId: initialTenantId,
      ),
        _currentPermissions = initialPermissions,
        _tenantId = _cleanRequiredTenantId(
          initialTenantId,
          context: 'ReportExecutedCubit.initialTenantId',
        ),
        super(ReportExecutedState.initial()) {
    _syncRepositoryTenant();
  }

  final ReportExecutedRepository _repo;
  final String moduleId;

  UserPermissionData? _currentPermissions;
  String _tenantId;

  static String _cleanRequiredTenantId(
      String value, {
        required String context,
      }) {
    final clean = value.trim();

    if (clean.isEmpty) {
      throw ArgumentError(
        'tenantId é obrigatório em $context.',
      );
    }

    return clean;
  }

  void _syncRepositoryTenant() {
    _repo.setActiveTenantId(_tenantId);
  }

  void setTenantId(String tenantId) {
    final previousTenantId = _tenantId;

    _tenantId = _cleanRequiredTenantId(
      tenantId,
      context: 'ReportExecutedCubit.setTenantId',
    );

    _syncRepositoryTenant();

    final currentContractId = state.contractId?.trim();

    if (previousTenantId != _tenantId &&
        currentContractId != null &&
        currentContractId.isNotEmpty) {
      Future.microtask(() => loadByContract(currentContractId));
    }
  }

  String _requireTenantId() {
    final clean = _tenantId.trim();

    if (clean.isEmpty) {
      throw Exception(
        'tenantId é obrigatório para acessar medições.',
      );
    }

    _repo.setActiveTenantId(clean);

    return clean;
  }

  void updatePermissions({
    UserPermissionData? permissions,
    required String tenantId,
  }) {
    final previousTenantId = _tenantId;

    _currentPermissions = permissions ?? _currentPermissions;

    _tenantId = _cleanRequiredTenantId(
      tenantId,
      context: 'ReportExecutedCubit.updatePermissions',
    );

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
          'Módulo: $moduleId | tenantId: $_tenantId',
    );
  }

  void _assertCanDelete() {
    _requireTenantId();

    if (_canDelete()) return;

    throw Exception(
      'Usuário sem permissão para apagar medições. '
          'Módulo: $moduleId | tenantId: $_tenantId',
    );
  }

  Future<void> loadByContract(String contractId) async {
    _requireTenantId();

    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) {
      throw Exception(
        'contractId é obrigatório para carregar medições.',
      );
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

      rethrow;
    }
  }

  Future<List<ReportExecutedData>> getAllMeasurementsCollectionGroup() {
    _requireTenantId();
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

    if (cleanContractId.isEmpty || cleanMeasurementId.isEmpty) {
      throw Exception('contractId e measurementId são obrigatórios.');
    }

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

    if (cleanContractId.isEmpty || cleanMeasurementId.isEmpty) {
      throw Exception('contractId e measurementId são obrigatórios.');
    }

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