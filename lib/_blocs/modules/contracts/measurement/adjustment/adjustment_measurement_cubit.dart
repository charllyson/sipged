// lib/_blocs/modules/contracts/measurement/adjustment/adjustment_measurement_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';
import 'package:sipged/_blocs/modules/contracts/measurement/adjustment/adjustment_measurement_data.dart';
import 'package:sipged/_blocs/modules/contracts/measurement/adjustment/adjustment_measurement_repository.dart';
import 'package:sipged/_blocs/modules/contracts/measurement/adjustment/adjustment_measurement_state.dart';

import 'package:sipged/_blocs/system/permission/permission_data.dart';

import 'package:sipged/_widgets/list/files/attachment.dart';

class AdjustmentMeasurementCubit extends Cubit<AdjustmentMeasurementState> {
  AdjustmentMeasurementCubit({
    AdjustmentMeasurementRepository? repository,
    UserPermissionData? initialPermissions,
    String? initialTenantId,
    this.moduleId = 'operation_measurements_adjustments',
  })  : _repo = repository ?? AdjustmentMeasurementRepository(),
        _currentPermissions = initialPermissions,
        _tenantId = _resolveInitialTenantId(
          tenantId: initialTenantId,
          permissions: initialPermissions,
        ),
        super(AdjustmentMeasurementState.initial()) {
    _syncRepositoryTenant();
  }

  final AdjustmentMeasurementRepository _repo;
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

  /// Use este método quando a empresa ativa mudar fora do Cubit.
  /// Exemplo: PermissionCubit / TenantCubit / troca de tenant na UI.
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
        'Nenhuma empresa ativa foi selecionada para acessar reajustes.',
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
      'Usuário sem permissão para alterar reajustes. '
          'Módulo: $moduleId | tenantId: ${_tenantId ?? 'não definido'}',
    );
  }

  void _assertCanDelete() {
    _requireTenantId();

    if (_canDelete()) return;

    throw Exception(
      'Usuário sem permissão para apagar reajustes. '
          'Módulo: $moduleId | tenantId: ${_tenantId ?? 'não definido'}',
    );
  }

  Future<void> loadByContract(String contractId) async {
    _syncRepositoryTenant();

    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) {
      emit(
        state.copyWith(
          status: AdjustmentMeasurementStatus.loaded,
          adjustments: const <AdjustmentMeasurementData>[],
          errorMessage: null,
          contractId: null,
          selected: null,
          selectedIndex: null,
          attachments: const <Attachment>[],
          selectedAttachmentIndex: null,
          isSaving: false,
          uploading: false,
          uploadProgress: null,
        ),
      );
      return;
    }

    if (!_hasTenantId) {
      emit(
        state.copyWith(
          status: AdjustmentMeasurementStatus.error,
          adjustments: const <AdjustmentMeasurementData>[],
          errorMessage: 'Nenhuma empresa ativa foi selecionada.',
          contractId: cleanContractId,
          selected: null,
          selectedIndex: null,
          attachments: const <Attachment>[],
          selectedAttachmentIndex: null,
          isSaving: false,
          uploading: false,
          uploadProgress: null,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: AdjustmentMeasurementStatus.loading,
        errorMessage: null,
        contractId: cleanContractId,
        selected: null,
        selectedIndex: null,
        attachments: const <Attachment>[],
        selectedAttachmentIndex: null,
        isSaving: false,
        uploading: false,
        uploadProgress: null,
      ),
    );

    try {
      final list = await _repo.getAllAdjustmentsOfContract(
        uidContract: cleanContractId,
      );

      emit(
        state.copyWith(
          status: AdjustmentMeasurementStatus.loaded,
          adjustments: list,
          errorMessage: null,
          contractId: cleanContractId,
          selected: null,
          selectedIndex: null,
          attachments: const <Attachment>[],
          selectedAttachmentIndex: null,
          isSaving: false,
          uploading: false,
          uploadProgress: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AdjustmentMeasurementStatus.error,
          errorMessage: e.toString(),
          isSaving: false,
          uploading: false,
          uploadProgress: null,
        ),
      );
    }
  }

  Future<List<AdjustmentMeasurementData>> getAllAdjustmentsCollectionGroup() {
    _syncRepositoryTenant();
    return _repo.getAllAdjustmentsCollectionGroup();
  }

  double sum(List<AdjustmentMeasurementData> list) {
    return _repo.sumAdjustments(list);
  }

  Future<void> saveOrUpdate(AdjustmentMeasurementData data) async {
    _assertCanWrite();

    final contractId = (data.contractId ?? state.contractId)?.trim();

    if (contractId == null || contractId.isEmpty) {
      throw Exception('contractId é obrigatório em AdjustmentMeasurementData.');
    }

    emit(
      state.copyWith(
        status: AdjustmentMeasurementStatus.saving,
        isSaving: true,
        errorMessage: null,
      ),
    );

    try {
      await _repo.saveOrUpdateAdjustment(
        contractId: contractId,
        adj: data.copyWith(contractId: contractId),
      );

      if (state.contractId == null || state.contractId == contractId) {
        await loadByContract(contractId);
      } else {
        emit(
          state.copyWith(
            status: AdjustmentMeasurementStatus.loaded,
            isSaving: false,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: AdjustmentMeasurementStatus.error,
          isSaving: false,
          errorMessage: e.toString(),
        ),
      );

      rethrow;
    }
  }

  Future<void> delete({
    required String contractId,
    required String adjustmentId,
  }) async {
    _assertCanDelete();

    final cleanContractId = contractId.trim();
    final cleanAdjustmentId = adjustmentId.trim();

    if (cleanContractId.isEmpty || cleanAdjustmentId.isEmpty) {
      throw Exception('contractId e adjustmentId são obrigatórios.');
    }

    emit(
      state.copyWith(
        status: AdjustmentMeasurementStatus.saving,
        isSaving: true,
        errorMessage: null,
      ),
    );

    try {
      await _repo.deleteAdjustment(
        contractId: cleanContractId,
        adjustmentId: cleanAdjustmentId,
      );

      if (state.contractId == null || state.contractId == cleanContractId) {
        await loadByContract(cleanContractId);
      } else {
        emit(
          state.copyWith(
            status: AdjustmentMeasurementStatus.loaded,
            isSaving: false,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: AdjustmentMeasurementStatus.error,
          isSaving: false,
          errorMessage: e.toString(),
        ),
      );

      rethrow;
    }
  }

  void selectByIndex(int index) {
    if (index < 0 || index >= state.adjustments.length) {
      clearSelection();
      return;
    }

    final selected = state.adjustments[index];
    final attachments = selected.attachments ?? const <Attachment>[];

    emit(
      state.copyWith(
        selected: selected,
        selectedIndex: index,
        attachments: attachments,
        selectedAttachmentIndex: null,
      ),
    );
  }

  void clearSelection() {
    emit(
      state.copyWith(
        selected: null,
        selectedIndex: null,
        attachments: const <Attachment>[],
        selectedAttachmentIndex: null,
      ),
    );
  }

  void selectAttachmentIndex(int index) {
    if (index < 0 || index >= state.attachments.length) {
      emit(
        state.copyWith(
          selectedAttachmentIndex: null,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        selectedAttachmentIndex: index,
      ),
    );
  }

  Future<void> updateAttachments(List<Attachment> attachments) async {
    _assertCanWrite();

    final selected = state.selected;
    final contractId = state.contractId?.trim();

    if (contractId == null || contractId.isEmpty) return;
    if (selected?.id == null || selected!.id!.trim().isEmpty) return;

    emit(
      state.copyWith(
        isSaving: true,
        errorMessage: null,
      ),
    );

    try {
      await _repo.setAttachments(
        contractId: contractId,
        adjustmentId: selected.id!,
        attachments: attachments,
      );

      final updatedSelected = selected.copyWith(
        attachments: attachments,
      );

      final updatedList = state.adjustments.map((item) {
        if (item.id == updatedSelected.id) return updatedSelected;
        return item;
      }).toList();

      emit(
        state.copyWith(
          isSaving: false,
          attachments: attachments,
          adjustments: updatedList,
          selected: updatedSelected,
          selectedAttachmentIndex: null,
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isSaving: false,
          errorMessage: e.toString(),
        ),
      );

      rethrow;
    }
  }

  Future<Attachment> pickAndUploadAttachment({
    required ContractData contract,
    required String contractId,
    required String adjustmentId,
  }) async {
    _assertCanWrite();

    final cleanContractId = contractId.trim();
    final cleanAdjustmentId = adjustmentId.trim();

    if (cleanContractId.isEmpty) {
      throw Exception('contractId é obrigatório para anexar arquivo.');
    }

    if (cleanAdjustmentId.isEmpty) {
      throw Exception('adjustmentId é obrigatório para anexar arquivo.');
    }

    final selected = state.selected;

    if (selected == null || selected.id == null || selected.id!.trim().isEmpty) {
      throw Exception('Selecione/salve o reajuste antes de anexar arquivos.');
    }

    emit(
      state.copyWith(
        uploading: true,
        uploadProgress: 0.0,
        errorMessage: null,
      ),
    );

    try {
      final (bytes, name) = await _repo.pickFileBytes();

      final att = await _repo.uploadAttachmentBytes(
        contract: contract,
        adjustment: selected.copyWith(
          id: cleanAdjustmentId,
          contractId: cleanContractId,
        ),
        bytes: bytes,
        originalName: name,
        label: '',
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

      final next = <Attachment>[
        ...state.attachments,
        att,
      ];

      await _repo.setAttachments(
        contractId: cleanContractId,
        adjustmentId: cleanAdjustmentId,
        attachments: next,
      );

      final updatedSelected = selected.copyWith(
        attachments: next,
      );

      final updatedList = state.adjustments.map((item) {
        if (item.id == updatedSelected.id) return updatedSelected;
        return item;
      }).toList();

      emit(
        state.copyWith(
          uploading: false,
          uploadProgress: null,
          attachments: next,
          selectedAttachmentIndex: next.isEmpty ? null : next.length - 1,
          selected: updatedSelected,
          adjustments: updatedList,
          errorMessage: null,
        ),
      );

      return att;
    } catch (e) {
      emit(
        state.copyWith(
          uploading: false,
          uploadProgress: null,
          errorMessage: e.toString(),
        ),
      );

      rethrow;
    }
  }

  Future<void> deleteAttachment({
    required String contractId,
    required String adjustmentId,
    required Attachment attachment,
  }) async {
    _assertCanWrite();

    final selected = state.selected;

    if (selected == null) return;

    final cleanContractId = contractId.trim();
    final cleanAdjustmentId = adjustmentId.trim();

    if (cleanContractId.isEmpty || cleanAdjustmentId.isEmpty) return;

    final next = List<Attachment>.from(state.attachments)
      ..removeWhere(
            (item) => item.id == attachment.id && item.url == attachment.url,
      );

    emit(
      state.copyWith(
        isSaving: true,
        errorMessage: null,
      ),
    );

    try {
      await _repo.deleteAttachment(
        contractId: cleanContractId,
        adjustmentId: cleanAdjustmentId,
        attachment: attachment,
        nextAttachments: next,
      );

      final updatedSelected = selected.copyWith(
        attachments: next,
      );

      final updatedList = state.adjustments.map((item) {
        if (item.id == updatedSelected.id) return updatedSelected;
        return item;
      }).toList();

      emit(
        state.copyWith(
          isSaving: false,
          attachments: next,
          selectedAttachmentIndex: null,
          selected: updatedSelected,
          adjustments: updatedList,
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isSaving: false,
          errorMessage: e.toString(),
        ),
      );

      rethrow;
    }
  }

  Future<void> renameAttachmentLabel({
    required String contractId,
    required String adjustmentId,
    required Attachment oldItem,
    required Attachment newItem,
  }) async {
    _assertCanWrite();

    final selected = state.selected;

    if (selected == null) return;

    final cleanContractId = contractId.trim();
    final cleanAdjustmentId = adjustmentId.trim();

    if (cleanContractId.isEmpty || cleanAdjustmentId.isEmpty) return;

    final next = List<Attachment>.from(state.attachments);

    final index = next.indexWhere(
          (item) => item.id == oldItem.id && item.url == oldItem.url,
    );

    if (index < 0) return;

    next[index] = newItem;

    emit(
      state.copyWith(
        isSaving: true,
        errorMessage: null,
      ),
    );

    try {
      await _repo.renameAttachmentLabel(
        contractId: cleanContractId,
        adjustmentId: cleanAdjustmentId,
        attachments: next,
      );

      final updatedSelected = selected.copyWith(
        attachments: next,
      );

      final updatedList = state.adjustments.map((item) {
        if (item.id == updatedSelected.id) return updatedSelected;
        return item;
      }).toList();

      emit(
        state.copyWith(
          isSaving: false,
          attachments: next,
          selected: updatedSelected,
          adjustments: updatedList,
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isSaving: false,
          errorMessage: e.toString(),
        ),
      );

      rethrow;
    }
  }

  Future<void> clearLegacyPdfUrl() async {
    _assertCanWrite();

    final selected = state.selected;
    final contractId = state.contractId?.trim();

    if (contractId == null || contractId.isEmpty) return;
    if (selected?.id == null || selected!.id!.trim().isEmpty) return;

    emit(
      state.copyWith(
        isSaving: true,
        errorMessage: null,
      ),
    );

    try {
      await _repo.salvarUrlPdfDaAdjustmentMeasurement(
        contractId: contractId,
        adjustmentId: selected.id!,
        url: '',
      );

      final updatedSelected = selected.copyWith(
        clearPdfUrl: true,
      );

      final updatedList = state.adjustments.map((item) {
        if (item.id == updatedSelected.id) return updatedSelected;
        return item;
      }).toList();

      emit(
        state.copyWith(
          isSaving: false,
          selected: updatedSelected,
          adjustments: updatedList,
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isSaving: false,
          errorMessage: e.toString(),
        ),
      );

      rethrow;
    }
  }
}