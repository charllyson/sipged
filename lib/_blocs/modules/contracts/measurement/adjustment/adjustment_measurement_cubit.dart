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
    required String initialTenantId,
    this.moduleId = 'operation_measurements_adjustments',
  })  : _repo = repository ??
      AdjustmentMeasurementRepository(
        tenantId: _cleanRequiredTenantId(
          initialTenantId,
          context: 'AdjustmentMeasurementCubit.repository',
        ),
      ),
        _currentPermissions = initialPermissions,
        _tenantId = _cleanRequiredTenantId(
          initialTenantId,
          context: 'AdjustmentMeasurementCubit.initialTenantId',
        ),
        super(AdjustmentMeasurementState.initial()) {
    _syncRepositoryTenant();
  }

  final AdjustmentMeasurementRepository _repo;
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

  String _cleanId(String? value) {
    return (value ?? '').trim();
  }

  void _syncRepositoryTenant() {
    _repo.setActiveTenantId(_tenantId);
  }

  void setTenantId(String tenantId) {
    final previousTenantId = _tenantId;

    _tenantId = _cleanRequiredTenantId(
      tenantId,
      context: 'AdjustmentMeasurementCubit.setTenantId',
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
      context: 'AdjustmentMeasurementCubit._requireTenantId',
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
      context: 'AdjustmentMeasurementCubit.updatePermissions',
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

    if (contract != null) {
      _assertCanContractAction(
        contract: contract,
        action: 'read',
        message: 'Usuário sem permissão para visualizar reajustes.',
      );
    }

    final previousSelectedId = state.selected?.id?.trim();

    emit(
      state.copyWith(
        status: AdjustmentMeasurementStatus.loading,
        errorMessage: null,
        contractId: cleanContractId,
        isSaving: false,
        uploading: false,
        uploadProgress: null,
      ),
    );

    try {
      final list = await _repo.getAllAdjustmentsOfContract(
        uidContract: cleanContractId,
      );

      AdjustmentMeasurementData? selected;
      int? selectedIndex;

      if (previousSelectedId != null && previousSelectedId.isNotEmpty) {
        final index = list.indexWhere((item) {
          return item.id?.trim() == previousSelectedId;
        });

        if (index >= 0) {
          selected = list[index];
          selectedIndex = index;
        }
      }

      emit(
        state.copyWith(
          status: AdjustmentMeasurementStatus.loaded,
          adjustments: list,
          errorMessage: null,
          contractId: cleanContractId,
          selected: selected,
          selectedIndex: selectedIndex,
          attachments: selected?.attachments ?? const <Attachment>[],
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

      rethrow;
    }
  }

  Future<List<AdjustmentMeasurementData>> getAllAdjustmentsCollectionGroup() {
    _requireTenantId();

    return _repo.getAllAdjustmentsCollectionGroup();
  }

  double sum(List<AdjustmentMeasurementData> list) {
    return _repo.sumAdjustments(list);
  }

  Future<void> saveOrUpdate({
    required ContractData contract,
    required AdjustmentMeasurementData data,
  }) async {
    final contractId = (data.contractId ?? contract.id ?? state.contractId)?.trim();

    if (contractId == null || contractId.isEmpty) {
      throw Exception('contractId é obrigatório em AdjustmentMeasurementData.');
    }

    final isNew = data.id == null || data.id!.trim().isEmpty;
    final action = isNew ? 'create' : 'edit';

    _assertCanContractAction(
      contract: contract,
      action: action,
      message: isNew
          ? 'Usuário sem permissão para criar reajustes.'
          : 'Usuário sem permissão para editar reajustes.',
    );

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

      await loadByContract(
        contractId,
        contract: contract,
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AdjustmentMeasurementStatus.error,
          isSaving: false,
          uploading: false,
          uploadProgress: null,
          errorMessage: e.toString(),
        ),
      );

      rethrow;
    }
  }

  Future<void> delete({
    required ContractData contract,
    required String contractId,
    required String adjustmentId,
  }) async {
    _assertCanContractAction(
      contract: contract,
      action: 'delete',
      message: 'Usuário sem permissão para apagar reajustes.',
    );

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

      await loadByContract(
        cleanContractId,
        contract: contract,
      );

      clearSelection();
    } catch (e) {
      emit(
        state.copyWith(
          status: AdjustmentMeasurementStatus.error,
          isSaving: false,
          uploading: false,
          uploadProgress: null,
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
        attachments: List<Attachment>.from(attachments),
        selectedAttachmentIndex: attachments.isNotEmpty ? 0 : null,
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

  Future<void> updateAttachments({
    required ContractData contract,
    required List<Attachment> attachments,
  }) async {
    _assertCanContractAction(
      contract: contract,
      action: 'edit',
      message: 'Usuário sem permissão para atualizar anexos de reajuste.',
    );

    final selected = state.selected;
    final contractId = state.contractId?.trim();

    if (contractId == null || contractId.isEmpty) {
      throw Exception('contractId é obrigatório para atualizar anexos.');
    }

    if (selected == null || selected.id == null || selected.id!.trim().isEmpty) {
      throw Exception('Selecione/salve o reajuste antes de atualizar anexos.');
    }

    emit(
      state.copyWith(
        isSaving: true,
        errorMessage: null,
      ),
    );

    try {
      final nextAttachments = List<Attachment>.from(attachments);

      await _repo.setAttachments(
        contractId: contractId,
        adjustmentId: selected.id!,
        attachments: nextAttachments,
      );

      _applyUpdatedAttachmentsToState(
        selected: selected,
        attachments: nextAttachments,
      );
    } catch (e) {
      emit(
        state.copyWith(
          isSaving: false,
          uploading: false,
          uploadProgress: null,
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
    String label = '',
    void Function(double progress)? onProgress,
  }) async {
    _assertCanContractAction(
      contract: contract,
      action: 'edit',
      message: 'Usuário sem permissão para anexar arquivos em reajustes.',
    );

    final cleanContractId = contractId.trim();
    final cleanAdjustmentId = adjustmentId.trim();

    if (cleanContractId.isEmpty || cleanAdjustmentId.isEmpty) {
      throw Exception('contractId e adjustmentId são obrigatórios.');
    }

    final selected = state.selected;

    if (selected == null || selected.id?.trim() != cleanAdjustmentId) {
      final index = state.adjustments.indexWhere((item) {
        return item.id?.trim() == cleanAdjustmentId;
      });

      if (index >= 0) {
        selectByIndex(index);
      }
    }

    final currentSelected = state.selected;

    if (currentSelected == null ||
        currentSelected.id == null ||
        currentSelected.id!.trim().isEmpty) {
      throw Exception('Selecione/salve o reajuste antes de anexar arquivos.');
    }

    emit(
      state.copyWith(
        isSaving: true,
        uploading: true,
        uploadProgress: 0.0,
        errorMessage: null,
      ),
    );

    try {
      final (bytes, name) = await _repo.pickFileBytes();

      final att = await _repo.uploadAttachmentBytes(
        contract: contract,
        adjustment: currentSelected.copyWith(
          id: cleanAdjustmentId,
          contractId: cleanContractId,
        ),
        bytes: bytes,
        originalName: name,
        label: label,
        onProgress: (progress) {
          final value = progress.isNaN ? 0.0 : progress.clamp(0.0, 1.0);

          emit(
            state.copyWith(
              uploading: true,
              uploadProgress: value.toDouble(),
            ),
          );

          onProgress?.call(value.toDouble());
        },
      );

      final next = List<Attachment>.from(state.attachments)..add(att);

      await _repo.setAttachments(
        contractId: cleanContractId,
        adjustmentId: cleanAdjustmentId,
        attachments: next,
      );

      _applyUpdatedAttachmentsToState(
        selected: currentSelected,
        attachments: next,
        selectedAttachmentIndex: next.length - 1,
      );

      return att;
    } catch (e) {
      emit(
        state.copyWith(
          isSaving: false,
          uploading: false,
          uploadProgress: null,
          errorMessage: e.toString(),
        ),
      );

      rethrow;
    }
  }

  Future<void> deleteAttachment({
    required ContractData contract,
    required String contractId,
    required String adjustmentId,
    required Attachment attachment,
  }) async {
    _assertCanContractAction(
      contract: contract,
      action: 'edit',
      message: 'Usuário sem permissão para remover anexos de reajuste.',
    );

    final cleanContractId = contractId.trim();
    final cleanAdjustmentId = adjustmentId.trim();

    if (cleanContractId.isEmpty || cleanAdjustmentId.isEmpty) {
      throw Exception('contractId e adjustmentId são obrigatórios.');
    }

    final selected = state.selected;

    if (selected == null || selected.id?.trim() != cleanAdjustmentId) {
      final index = state.adjustments.indexWhere((item) {
        return item.id?.trim() == cleanAdjustmentId;
      });

      if (index >= 0) {
        selectByIndex(index);
      }
    }

    final currentSelected = state.selected;

    if (currentSelected == null) {
      throw Exception('Nenhum reajuste selecionado para remover anexo.');
    }

    final next = List<Attachment>.from(state.attachments)
      ..removeWhere((item) {
        final sameId =
            item.id.trim().isNotEmpty && item.id.trim() == attachment.id.trim();

        final samePath = item.path.trim().isNotEmpty &&
            item.path.trim() == attachment.path.trim();

        final sameUrl = item.url.trim().isNotEmpty &&
            item.url.trim() == attachment.url.trim();

        return sameId || samePath || sameUrl;
      });

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

      _applyUpdatedAttachmentsToState(
        selected: currentSelected,
        attachments: next,
      );
    } catch (e) {
      emit(
        state.copyWith(
          isSaving: false,
          uploading: false,
          uploadProgress: null,
          errorMessage: e.toString(),
        ),
      );

      rethrow;
    }
  }

  Future<void> renameAttachmentLabel({
    required ContractData contract,
    required String contractId,
    required String adjustmentId,
    required Attachment oldItem,
    required Attachment newItem,
  }) async {
    _assertCanContractAction(
      contract: contract,
      action: 'edit',
      message: 'Usuário sem permissão para renomear anexos de reajuste.',
    );

    final cleanContractId = contractId.trim();
    final cleanAdjustmentId = adjustmentId.trim();

    if (cleanContractId.isEmpty || cleanAdjustmentId.isEmpty) {
      throw Exception('contractId e adjustmentId são obrigatórios.');
    }

    final selected = state.selected;

    if (selected == null || selected.id?.trim() != cleanAdjustmentId) {
      final index = state.adjustments.indexWhere((item) {
        return item.id?.trim() == cleanAdjustmentId;
      });

      if (index >= 0) {
        selectByIndex(index);
      }
    }

    final currentSelected = state.selected;

    if (currentSelected == null) {
      throw Exception('Nenhum reajuste selecionado para renomear anexo.');
    }

    final next = List<Attachment>.from(state.attachments);

    final index = next.indexWhere((item) {
      final sameId =
          item.id.trim().isNotEmpty && item.id.trim() == oldItem.id.trim();

      final samePath = item.path.trim().isNotEmpty &&
          item.path.trim() == oldItem.path.trim();

      final sameUrl =
          item.url.trim().isNotEmpty && item.url.trim() == oldItem.url.trim();

      return sameId || samePath || sameUrl;
    });

    if (index < 0) {
      throw Exception('Anexo não encontrado para renomear.');
    }

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

      _applyUpdatedAttachmentsToState(
        selected: currentSelected,
        attachments: next,
        selectedAttachmentIndex: index,
      );
    } catch (e) {
      emit(
        state.copyWith(
          isSaving: false,
          uploading: false,
          uploadProgress: null,
          errorMessage: e.toString(),
        ),
      );

      rethrow;
    }
  }

  Future<void> clearLegacyPdfUrl({
    required ContractData contract,
  }) async {
    _assertCanContractAction(
      contract: contract,
      action: 'edit',
      message: 'Usuário sem permissão para limpar PDF legado de reajuste.',
    );

    final selected = state.selected;
    final contractId = state.contractId?.trim();

    if (contractId == null || contractId.isEmpty) {
      throw Exception('contractId é obrigatório para limpar PDF legado.');
    }

    if (selected == null || selected.id == null || selected.id!.trim().isEmpty) {
      throw Exception('Selecione/salve o reajuste antes de limpar PDF legado.');
    }

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
        if (_cleanId(item.id) == _cleanId(updatedSelected.id)) {
          return updatedSelected;
        }

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
          uploading: false,
          uploadProgress: null,
          errorMessage: e.toString(),
        ),
      );

      rethrow;
    }
  }

  void _applyUpdatedAttachmentsToState({
    required AdjustmentMeasurementData selected,
    required List<Attachment> attachments,
    int? selectedAttachmentIndex,
  }) {
    final nextAttachments = List<Attachment>.from(attachments);

    final updatedSelected = selected.copyWith(
      attachments: nextAttachments,
    );

    final updatedList = state.adjustments.map((item) {
      if (_cleanId(item.id) == _cleanId(updatedSelected.id)) {
        return updatedSelected;
      }

      return item;
    }).toList();

    final resolvedSelectedAttachmentIndex = nextAttachments.isEmpty
        ? null
        : (selectedAttachmentIndex ?? state.selectedAttachmentIndex ?? 0)
        .clamp(0, nextAttachments.length - 1)
        .toInt();

    final resolvedSelectedIndex = updatedList.indexWhere((item) {
      return _cleanId(item.id) == _cleanId(updatedSelected.id);
    });

    emit(
      state.copyWith(
        status: AdjustmentMeasurementStatus.loaded,
        isSaving: false,
        uploading: false,
        uploadProgress: null,
        attachments: nextAttachments,
        adjustments: updatedList,
        selected: updatedSelected,
        selectedIndex: resolvedSelectedIndex >= 0 ? resolvedSelectedIndex : null,
        selectedAttachmentIndex: resolvedSelectedAttachmentIndex,
        errorMessage: null,
      ),
    );
  }
}