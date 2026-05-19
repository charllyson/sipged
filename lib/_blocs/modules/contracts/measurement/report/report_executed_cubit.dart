import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';
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
        tenantId: _cleanRequiredTenantId(
          initialTenantId,
          context: 'ReportExecutedCubit.repository',
        ),
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
    final clean = _cleanRequiredTenantId(
      _tenantId,
      context: 'ReportExecutedCubit._requireTenantId',
    );

    _tenantId = clean;
    _repo.setActiveTenantId(clean);

    return clean;
  }

  void updatePermissions({
    UserPermissionData? permissions,
    required String tenantId,
  }) {
    final previousTenantId = _tenantId;
    final previousPermissions = _currentPermissions;

    if (permissions != null) {
      _currentPermissions = permissions;
    }

    _tenantId = _cleanRequiredTenantId(
      tenantId,
      context: 'ReportExecutedCubit.updatePermissions',
    );

    _syncRepositoryTenant();

    final currentContractId = state.contractId?.trim();

    final tenantChanged = previousTenantId != _tenantId;
    final permissionsChanged =
        permissions != null && previousPermissions != _currentPermissions;

    if ((tenantChanged || permissionsChanged) &&
        currentContractId != null &&
        currentContractId.isNotEmpty) {
      Future.microtask(() => loadByContract(currentContractId));
    }
  }

  bool canReadContract(ContractData contract) {
    return _canContractAction(
      contract: contract,
      action: 'read',
    );
  }

  bool canCreateContract(ContractData contract) {
    return _canContractAction(
      contract: contract,
      action: 'create',
    );
  }

  bool canEditContract(ContractData contract) {
    return _canContractAction(
      contract: contract,
      action: 'edit',
    );
  }

  bool canDeleteContract(ContractData contract) {
    return _canContractAction(
      contract: contract,
      action: 'delete',
    );
  }

  bool canApproveContract(ContractData contract) {
    return _canContractAction(
      contract: contract,
      action: 'approve',
    );
  }

  bool _canContractAction({
    required ContractData contract,
    required String action,
  }) {
    final permissions = _currentPermissions;
    final cleanAction = action.trim().toLowerCase();

    if (permissions == null || cleanAction.isEmpty) {
      return false;
    }

    _requireTenantId();

    return SystemPermission.canContract(
      permissions: permissions,
      contract: contract,
      action: cleanAction,
      module: moduleId,
      tenantId: _tenantId,
    );
  }

  void _assertCanContractAction({
    required ContractData contract,
    required String action,
    required String message,
  }) {
    _requireTenantId();

    if (_canContractAction(contract: contract, action: action)) {
      return;
    }

    throw Exception(
      '$message '
          'Ação: $action | Módulo: $moduleId | tenantId: $_tenantId',
    );
  }

  Future<void> loadByContract(
      String contractId, {
        ContractData? contract,
      }) async {
    _requireTenantId();

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

    if (contract != null) {
      _assertCanContractAction(
        contract: contract,
        action: 'read',
        message: 'Usuário sem permissão para visualizar medições.',
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

  Future<void> saveOrUpdate({
    required ContractData contract,
    required ReportExecutedData data,
  }) async {
    final contractId =
    (data.contractId ?? contract.id ?? state.contractId)?.trim();

    if (contractId == null || contractId.isEmpty) {
      throw Exception('contractId é obrigatório para salvar a medição.');
    }

    final measurementId = data.id?.trim();
    final isNew = measurementId == null || measurementId.isEmpty;
    final action = isNew ? 'create' : 'edit';

    _assertCanContractAction(
      contract: contract,
      action: action,
      message: isNew
          ? 'Usuário sem permissão para criar medições.'
          : 'Usuário sem permissão para editar medições.',
    );

    emit(
      state.copyWith(
        status: ReportExecutedStatus.loading,
        error: null,
      ),
    );

    try {
      await _repo.saveOrUpdateReport(
        data.copyWith(
          id: isNew ? null : measurementId,
          contractId: contractId,
        ),
      );

      await loadByContract(
        contractId,
        contract: contract,
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

  Future<void> delete({
    required ContractData contract,
    required String contractId,
    required String measurementId,
  }) async {
    _assertCanContractAction(
      contract: contract,
      action: 'delete',
      message: 'Usuário sem permissão para apagar medições.',
    );

    final cleanContractId = contractId.trim();
    final cleanMeasurementId = measurementId.trim();

    if (cleanContractId.isEmpty || cleanMeasurementId.isEmpty) {
      throw Exception('contractId e measurementId são obrigatórios.');
    }

    emit(
      state.copyWith(
        status: ReportExecutedStatus.loading,
        error: null,
      ),
    );

    try {
      await _repo.deleteMeasurement(
        contractId: cleanContractId,
        measurementId: cleanMeasurementId,
      );

      await loadByContract(
        cleanContractId,
        contract: contract,
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

  double sum(List<ReportExecutedData> list) {
    return _repo.somarValorMedicoes(list);
  }

  Future<Attachment> pickAndUploadAttachment({
    required ContractData contract,
    required String contractId,
    required String measurementId,
  }) async {
    _assertCanContractAction(
      contract: contract,
      action: 'edit',
      message: 'Usuário sem permissão para anexar arquivos em medições.',
    );

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
      final attachment = await _repo.pickAndUploadAttachment(
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

      await loadByContract(
        cleanContractId,
        contract: contract,
      );

      emit(
        state.copyWith(
          uploading: false,
          uploadProgress: null,
          error: null,
        ),
      );

      return attachment;
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
    required ContractData contract,
    required String contractId,
    required String measurementId,
    required Attachment attachment,
  }) async {
    _assertCanContractAction(
      contract: contract,
      action: 'edit',
      message: 'Usuário sem permissão para remover anexos de medição.',
    );

    final cleanContractId = contractId.trim();
    final cleanMeasurementId = measurementId.trim();

    if (cleanContractId.isEmpty || cleanMeasurementId.isEmpty) {
      throw Exception('contractId e measurementId são obrigatórios.');
    }

    emit(
      state.copyWith(
        uploading: true,
        uploadProgress: null,
        error: null,
      ),
    );

    try {
      await _repo.deleteAttachment(
        contractId: cleanContractId,
        measurementId: cleanMeasurementId,
        attachment: attachment,
      );

      await loadByContract(
        cleanContractId,
        contract: contract,
      );

      emit(
        state.copyWith(
          uploading: false,
          uploadProgress: null,
          error: null,
        ),
      );
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

  Future<void> renameAttachmentLabel({
    required ContractData contract,
    required String contractId,
    required String measurementId,
    required Attachment oldItem,
    required Attachment newItem,
  }) async {
    _assertCanContractAction(
      contract: contract,
      action: 'edit',
      message: 'Usuário sem permissão para renomear anexos de medição.',
    );

    final cleanContractId = contractId.trim();
    final cleanMeasurementId = measurementId.trim();

    if (cleanContractId.isEmpty || cleanMeasurementId.isEmpty) {
      throw Exception('contractId e measurementId são obrigatórios.');
    }

    emit(
      state.copyWith(
        uploading: true,
        uploadProgress: null,
        error: null,
      ),
    );

    try {
      await _repo.renameAttachmentLabel(
        contractId: cleanContractId,
        measurementId: cleanMeasurementId,
        oldItem: oldItem,
        newItem: newItem,
      );

      await loadByContract(
        cleanContractId,
        contract: contract,
      );

      emit(
        state.copyWith(
          uploading: false,
          uploadProgress: null,
          error: null,
        ),
      );
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
}