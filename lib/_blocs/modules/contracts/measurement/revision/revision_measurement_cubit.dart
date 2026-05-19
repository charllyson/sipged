import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';
import 'package:sipged/_blocs/system/permission/permission_data.dart';
import 'package:sipged/_widgets/list/files/attachment.dart';

import 'revision_measurement_data.dart';
import 'revision_measurement_repository.dart';
import 'revision_measurement_state.dart';

class RevisionMeasurementCubit extends Cubit<RevisionMeasurementState> {
  RevisionMeasurementCubit({
    RevisionMeasurementRepository? repository,
    UserPermissionData? initialPermissions,
    required String initialTenantId,
    this.moduleId = 'operation_measurements_revisions',
  })  : _tenantId = _cleanRequiredTenantId(
    initialTenantId,
    context: 'RevisionMeasurementCubit.constructor',
  ),
        _repo = repository ??
            RevisionMeasurementRepository(
              tenantId: _cleanRequiredTenantId(
                initialTenantId,
                context: 'RevisionMeasurementCubit.repository',
              ),
            ),
        _currentPermissions = initialPermissions,
        super(RevisionMeasurementState.initial()) {
    _syncRepositoryTenant();
  }

  final RevisionMeasurementRepository _repo;
  final String moduleId;

  UserPermissionData? _currentPermissions;
  String _tenantId;

  static String _cleanRequiredTenantId(
      String value, {
        required String context,
      }) {
    final clean = value.trim();

    if (clean.isEmpty) {
      throw ArgumentError('tenantId é obrigatório em $context.');
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
      context: 'RevisionMeasurementCubit.setTenantId',
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
      context: 'RevisionMeasurementCubit._requireTenantId',
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

    _currentPermissions = permissions ?? _currentPermissions;

    _tenantId = _cleanRequiredTenantId(
      tenantId,
      context: 'RevisionMeasurementCubit.updatePermissions',
    );

    _syncRepositoryTenant();

    final currentContractId = state.contractId?.trim();

    if (previousTenantId != _tenantId &&
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
          status: RevisionMeasurementStatus.loaded,
          revisions: const <RevisionMeasurementData>[],
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
        message: 'Usuário sem permissão para visualizar revisões.',
      );
    }

    final previousSelectedId = state.selected?.id?.trim();

    emit(
      state.copyWith(
        status: RevisionMeasurementStatus.loading,
        errorMessage: null,
        contractId: cleanContractId,
        isSaving: false,
        uploading: false,
        uploadProgress: null,
      ),
    );

    try {
      final list = await _repo.getAllRevisionsOfContract(
        uidContract: cleanContractId,
      );

      RevisionMeasurementData? selected;
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
          status: RevisionMeasurementStatus.loaded,
          revisions: list,
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
          status: RevisionMeasurementStatus.error,
          errorMessage: e.toString(),
          isSaving: false,
          uploading: false,
          uploadProgress: null,
        ),
      );

      rethrow;
    }
  }

  Future<List<RevisionMeasurementData>> getAllRevisionsCollectionGroup() {
    _requireTenantId();

    return _repo.getAllRevisionsCollectionGroup();
  }

  double sum(List<RevisionMeasurementData> list) {
    return _repo.sumRevisions(list);
  }

  Future<String> saveOrUpdate({
    required ContractData contract,
    required RevisionMeasurementData data,
  }) async {
    final cleanContractId =
    (data.contractId ?? contract.id ?? state.contractId)?.trim();

    if (cleanContractId == null || cleanContractId.isEmpty) {
      throw Exception('contractId é obrigatório para salvar revisão.');
    }

    final cleanRevisionId = data.id?.trim();
    final isNew = cleanRevisionId == null || cleanRevisionId.isEmpty;
    final action = isNew ? 'create' : 'edit';

    _assertCanContractAction(
      contract: contract,
      action: action,
      message: isNew
          ? 'Usuário sem permissão para criar revisões.'
          : 'Usuário sem permissão para editar revisões.',
    );

    emit(
      state.copyWith(
        status: RevisionMeasurementStatus.saving,
        isSaving: true,
        errorMessage: null,
      ),
    );

    try {
      final revisionId = await _repo.saveOrUpdateRevision(
        contractId: cleanContractId,
        revisionMeasurementId: cleanRevisionId,
        rev: data.copyWith(
          id: isNew ? null : cleanRevisionId,
          contractId: cleanContractId,
        ),
      );

      await loadByContract(
        cleanContractId,
        contract: contract,
      );

      final index = state.revisions.indexWhere((item) {
        return item.id?.trim() == revisionId.trim();
      });

      if (index >= 0) {
        selectByIndex(index);
      }

      return revisionId;
    } catch (e) {
      emit(
        state.copyWith(
          status: RevisionMeasurementStatus.error,
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
    required String revisionId,
  }) async {
    _assertCanContractAction(
      contract: contract,
      action: 'delete',
      message: 'Usuário sem permissão para apagar revisões.',
    );

    final cleanContractId = contractId.trim();
    final cleanRevisionId = revisionId.trim();

    if (cleanContractId.isEmpty || cleanRevisionId.isEmpty) {
      throw Exception('contractId e revisionId são obrigatórios.');
    }

    emit(
      state.copyWith(
        status: RevisionMeasurementStatus.saving,
        isSaving: true,
        errorMessage: null,
      ),
    );

    try {
      await _repo.deleteRevision(
        contractId: cleanContractId,
        revisionId: cleanRevisionId,
      );

      await loadByContract(
        cleanContractId,
        contract: contract,
      );

      clearSelection();
    } catch (e) {
      emit(
        state.copyWith(
          status: RevisionMeasurementStatus.error,
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
    if (index < 0 || index >= state.revisions.length) {
      clearSelection();
      return;
    }

    final selected = state.revisions[index];
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
      message: 'Usuário sem permissão para atualizar anexos de revisão.',
    );

    final selected = state.selected;
    final contractId = state.contractId?.trim();

    if (contractId == null || contractId.isEmpty) {
      throw Exception('contractId é obrigatório para atualizar anexos.');
    }

    if (selected == null || selected.id == null || selected.id!.trim().isEmpty) {
      throw Exception('revisionId é obrigatório para atualizar anexos.');
    }

    emit(
      state.copyWith(
        isSaving: true,
        errorMessage: null,
      ),
    );

    try {
      final next = List<Attachment>.from(attachments);

      await _repo.setAttachments(
        contractId: contractId,
        revisionId: selected.id!,
        attachments: next,
      );

      _applyUpdatedAttachmentsToState(
        selected: selected,
        attachments: next,
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

  Future<Attachment> addAttachmentWithPicker({
    required ContractData contract,
    String label = '',
    void Function(double progress)? onProgress,
  }) async {
    _assertCanContractAction(
      contract: contract,
      action: 'edit',
      message: 'Usuário sem permissão para anexar arquivos em revisões.',
    );

    final selected = state.selected;
    final contractId = state.contractId?.trim();

    if (contractId == null || contractId.isEmpty) {
      throw Exception('Contrato não informado para anexar arquivo.');
    }

    if (selected == null || selected.id == null || selected.id!.trim().isEmpty) {
      throw Exception('Selecione ou salve uma revisão antes de anexar arquivos.');
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
      final (bytes, originalName) = await _repo.pickFileBytes();

      final attachment = await _repo.uploadAttachmentBytes(
        contract: contract,
        revision: selected.copyWith(
          contractId: contractId,
        ),
        bytes: bytes,
        originalName: originalName,
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

      final next = List<Attachment>.from(state.attachments)..add(attachment);

      await _repo.setAttachments(
        contractId: contractId,
        revisionId: selected.id!,
        attachments: next,
      );

      _applyUpdatedAttachmentsToState(
        selected: selected,
        attachments: next,
        selectedAttachmentIndex: next.length - 1,
      );

      return attachment;
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
    required String revisionId,
    String label = '',
    void Function(double progress)? onProgress,
  }) async {
    _assertCanContractAction(
      contract: contract,
      action: 'edit',
      message: 'Usuário sem permissão para anexar arquivos em revisões.',
    );

    final cleanContractId = contractId.trim();
    final cleanRevisionId = revisionId.trim();

    if (cleanContractId.isEmpty || cleanRevisionId.isEmpty) {
      throw Exception('contractId e revisionId são obrigatórios.');
    }

    final selected = state.selected;

    if (selected == null || selected.id?.trim() != cleanRevisionId) {
      final index = state.revisions.indexWhere((item) {
        return item.id?.trim() == cleanRevisionId;
      });

      if (index >= 0) {
        selectByIndex(index);
      }
    }

    return addAttachmentWithPicker(
      contract: contract,
      label: label,
      onProgress: onProgress,
    );
  }

  Future<void> deleteAttachmentAt({
    required ContractData contract,
    required int index,
  }) async {
    _assertCanContractAction(
      contract: contract,
      action: 'edit',
      message: 'Usuário sem permissão para excluir anexos de revisão.',
    );

    final selected = state.selected;
    final contractId = state.contractId?.trim();

    if (contractId == null || contractId.isEmpty) {
      throw Exception('contractId é obrigatório para excluir anexo.');
    }

    if (selected == null || selected.id == null || selected.id!.trim().isEmpty) {
      throw Exception('revisionId é obrigatório para excluir anexo.');
    }

    if (index < 0 || index >= state.attachments.length) {
      throw Exception('Índice de anexo inválido.');
    }

    emit(
      state.copyWith(
        isSaving: true,
        errorMessage: null,
      ),
    );

    try {
      final next = List<Attachment>.from(state.attachments);
      final removed = next.removeAt(index);

      final storagePath = removed.path.trim();

      if (storagePath.isNotEmpty) {
        await _repo.deleteStorageByPath(storagePath);
      }

      await _repo.setAttachments(
        contractId: contractId,
        revisionId: selected.id!,
        attachments: next,
      );

      _applyUpdatedAttachmentsToState(
        selected: selected,
        attachments: next,
        selectedAttachmentIndex:
        next.isEmpty ? null : index.clamp(0, next.length - 1).toInt(),
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

  Future<void> deleteAttachment({
    required ContractData contract,
    required String contractId,
    required String revisionId,
    required Attachment attachment,
  }) async {
    _assertCanContractAction(
      contract: contract,
      action: 'edit',
      message: 'Usuário sem permissão para excluir anexos de revisão.',
    );

    final cleanContractId = contractId.trim();
    final cleanRevisionId = revisionId.trim();

    if (cleanContractId.isEmpty || cleanRevisionId.isEmpty) {
      throw Exception(
        'contractId e revisionId são obrigatórios para excluir anexo.',
      );
    }

    final selected = state.selected;

    if (selected == null || selected.id?.trim() != cleanRevisionId) {
      final index = state.revisions.indexWhere((item) {
        return item.id?.trim() == cleanRevisionId;
      });

      if (index >= 0) {
        selectByIndex(index);
      }
    }

    final index = state.attachments.indexWhere((item) {
      final sameId =
          item.id.trim().isNotEmpty && item.id.trim() == attachment.id.trim();

      final samePath = item.path.trim().isNotEmpty &&
          item.path.trim() == attachment.path.trim();

      final sameUrl =
          item.url.trim().isNotEmpty && item.url.trim() == attachment.url.trim();

      return sameId || samePath || sameUrl;
    });

    if (index < 0) {
      throw Exception('Anexo não encontrado para exclusão.');
    }

    await deleteAttachmentAt(
      contract: contract,
      index: index,
    );
  }

  Future<bool> renameAttachmentLabel({
    required ContractData contract,
    required String contractId,
    required String revisionId,
    required Attachment oldItem,
    required Attachment newItem,
  }) async {
    _assertCanContractAction(
      contract: contract,
      action: 'edit',
      message: 'Usuário sem permissão para renomear anexos de revisão.',
    );

    final cleanContractId = contractId.trim();
    final cleanRevisionId = revisionId.trim();

    if (cleanContractId.isEmpty || cleanRevisionId.isEmpty) {
      throw Exception(
        'contractId e revisionId são obrigatórios para renomear anexo.',
      );
    }

    final selected = state.selected;

    if (selected == null || selected.id?.trim() != cleanRevisionId) {
      final index = state.revisions.indexWhere((item) {
        return item.id?.trim() == cleanRevisionId;
      });

      if (index >= 0) {
        selectByIndex(index);
      }
    }

    final currentSelected = state.selected;

    if (currentSelected == null ||
        currentSelected.id == null ||
        currentSelected.id!.trim().isEmpty) {
      throw Exception('Selecione uma revisão para renomear o anexo.');
    }

    final next = List<Attachment>.from(state.attachments);

    final index = next.indexWhere((item) {
      final sameId =
          item.id.trim().isNotEmpty && item.id.trim() == oldItem.id.trim();

      final samePath =
          item.path.trim().isNotEmpty && item.path.trim() == oldItem.path.trim();

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
      await _repo.setAttachments(
        contractId: cleanContractId,
        revisionId: cleanRevisionId,
        attachments: next,
      );

      _applyUpdatedAttachmentsToState(
        selected: currentSelected,
        attachments: next,
        selectedAttachmentIndex: index,
      );

      return true;
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

  Future<void> clearLegacyPdfUrl({
    required ContractData contract,
  }) async {
    _assertCanContractAction(
      contract: contract,
      action: 'edit',
      message: 'Usuário sem permissão para limpar PDF legado de revisão.',
    );

    final selected = state.selected;
    final contractId = state.contractId?.trim();

    if (contractId == null || contractId.isEmpty) {
      throw Exception('contractId é obrigatório para limpar PDF legado.');
    }

    if (selected == null || selected.id == null || selected.id!.trim().isEmpty) {
      throw Exception('revisionId é obrigatório para limpar PDF legado.');
    }

    emit(
      state.copyWith(
        isSaving: true,
        errorMessage: null,
      ),
    );

    try {
      await _repo.salvarUrlPdfDaRevisionMeasurement(
        contractId: contractId,
        revisionMeasurementId: selected.id!,
        url: '',
      );

      final updatedSelected = selected.copyWith(clearPdfUrl: true);

      final updatedList = state.revisions.map((item) {
        if (_cleanId(item.id) == _cleanId(updatedSelected.id)) {
          return updatedSelected;
        }

        return item;
      }).toList();

      final resolvedSelectedIndex = updatedList.indexWhere((item) {
        return _cleanId(item.id) == _cleanId(updatedSelected.id);
      });

      emit(
        state.copyWith(
          status: RevisionMeasurementStatus.loaded,
          isSaving: false,
          selected: updatedSelected,
          selectedIndex: resolvedSelectedIndex >= 0 ? resolvedSelectedIndex : null,
          revisions: updatedList,
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

  void _applyUpdatedAttachmentsToState({
    required RevisionMeasurementData selected,
    required List<Attachment> attachments,
    int? selectedAttachmentIndex,
  }) {
    final nextAttachments = List<Attachment>.from(attachments);

    final updatedSelected = selected.copyWith(
      attachments: nextAttachments,
    );

    final updatedList = state.revisions.map((item) {
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
        status: RevisionMeasurementStatus.loaded,
        isSaving: false,
        uploading: false,
        uploadProgress: null,
        attachments: nextAttachments,
        revisions: updatedList,
        selected: updatedSelected,
        selectedIndex: resolvedSelectedIndex >= 0 ? resolvedSelectedIndex : null,
        selectedAttachmentIndex: resolvedSelectedAttachmentIndex,
        errorMessage: null,
      ),
    );
  }
}