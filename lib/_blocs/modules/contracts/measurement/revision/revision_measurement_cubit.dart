// lib/_blocs/modules/contracts/measurement/revision/revision_measurement_cubit.dart

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
    String? initialTenantId,
    this.moduleId = 'operation_measurements_revisions',
  })  : _repo = repository ?? RevisionMeasurementRepository(),
        _currentPermissions = initialPermissions,
        _tenantId = _resolveInitialTenantId(
          tenantId: initialTenantId,
          permissions: initialPermissions,
        ),
        super(RevisionMeasurementState.initial()) {
    _syncRepositoryTenant();
  }

  final RevisionMeasurementRepository _repo;
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

    if (direct != null) return direct;

    final permissionTenant = _cleanTenantId(permissions?.activeTenantId);

    if (permissionTenant != null) return permissionTenant;

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
        'Nenhuma empresa ativa foi selecionada para acessar revisões.',
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
      'Usuário sem permissão para alterar revisões. '
          'Módulo: $moduleId | tenantId: ${_tenantId ?? 'não definido'}',
    );
  }

  void _assertCanDelete() {
    _requireTenantId();

    if (_canDelete()) return;

    throw Exception(
      'Usuário sem permissão para apagar revisões. '
          'Módulo: $moduleId | tenantId: ${_tenantId ?? 'não definido'}',
    );
  }

  Future<void> loadByContract(String contractId) async {
    _syncRepositoryTenant();

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

    if (!_hasTenantId) {
      emit(
        state.copyWith(
          status: RevisionMeasurementStatus.error,
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
        status: RevisionMeasurementStatus.loading,
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
      final list = await _repo.getAllRevisionsOfContract(
        uidContract: cleanContractId,
      );

      emit(
        state.copyWith(
          status: RevisionMeasurementStatus.loaded,
          revisions: list,
          errorMessage: null,
          contractId: cleanContractId,
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
    }
  }

  Future<List<RevisionMeasurementData>> getAllRevisionsCollectionGroup() {
    _syncRepositoryTenant();
    return _repo.getAllRevisionsCollectionGroup();
  }

  double sum(List<RevisionMeasurementData> list) {
    return _repo.sumRevisions(list);
  }

  Future<String> saveOrUpdate({
    required RevisionMeasurementData data,
  }) async {
    _assertCanWrite();

    final cleanContractId = (data.contractId ?? state.contractId)?.trim();

    if (cleanContractId == null || cleanContractId.isEmpty) {
      throw Exception('contractId é obrigatório para salvar revisão.');
    }

    final cleanRevisionId = data.id?.trim();

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
          contractId: cleanContractId,
        ),
      );

      if (state.contractId == null || state.contractId == cleanContractId) {
        await loadByContract(cleanContractId);
      } else {
        emit(
          state.copyWith(
            status: RevisionMeasurementStatus.loaded,
            isSaving: false,
          ),
        );
      }

      return revisionId;
    } catch (e) {
      emit(
        state.copyWith(
          status: RevisionMeasurementStatus.error,
          isSaving: false,
          errorMessage: e.toString(),
        ),
      );

      rethrow;
    }
  }

  Future<void> delete({
    required String contractId,
    required String revisionId,
  }) async {
    _assertCanDelete();

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

      if (state.contractId == null || state.contractId == cleanContractId) {
        await loadByContract(cleanContractId);
      } else {
        emit(
          state.copyWith(
            status: RevisionMeasurementStatus.loaded,
            isSaving: false,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: RevisionMeasurementStatus.error,
          isSaving: false,
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
      emit(state.copyWith(selectedAttachmentIndex: null));
      return;
    }

    emit(state.copyWith(selectedAttachmentIndex: index));
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
        revisionId: selected.id!,
        attachments: attachments,
      );

      final updatedSelected = selected.copyWith(attachments: attachments);

      final updatedList = state.revisions.map((item) {
        if (item.id == updatedSelected.id) return updatedSelected;
        return item;
      }).toList();

      emit(
        state.copyWith(
          isSaving: false,
          attachments: attachments,
          revisions: updatedList,
          selected: updatedSelected,
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

  Future<Attachment> addAttachmentWithPicker({
    required ContractData contract,
    String label = '',
    void Function(double progress)? onProgress,
  }) async {
    _assertCanWrite();

    final selected = state.selected;
    final contractId = state.contractId?.trim();

    if (contractId == null || contractId.isEmpty) {
      throw Exception('Contrato não informado para anexar arquivo.');
    }

    if (selected == null || selected.id == null || selected.id!.isEmpty) {
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

      final updatedSelected = selected.copyWith(attachments: next);

      final updatedList = state.revisions.map((item) {
        if (item.id == updatedSelected.id) return updatedSelected;
        return item;
      }).toList();

      emit(
        state.copyWith(
          isSaving: false,
          uploading: false,
          uploadProgress: null,
          attachments: next,
          revisions: updatedList,
          selected: updatedSelected,
          errorMessage: null,
        ),
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

  Future<void> deleteAttachmentAt(int index) async {
    _assertCanWrite();

    final selected = state.selected;
    final contractId = state.contractId?.trim();

    if (contractId == null || contractId.isEmpty) return;
    if (selected?.id == null || selected!.id!.trim().isEmpty) return;
    if (index < 0 || index >= state.attachments.length) return;

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

      final updatedSelected = selected.copyWith(attachments: next);

      final updatedList = state.revisions.map((item) {
        if (item.id == updatedSelected.id) return updatedSelected;
        return item;
      }).toList();

      emit(
        state.copyWith(
          isSaving: false,
          attachments: next,
          revisions: updatedList,
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
      await _repo.salvarUrlPdfDaRevisionMeasurement(
        contractId: contractId,
        revisionMeasurementId: selected.id!,
        url: '',
      );

      final updatedSelected = selected.copyWith(clearPdfUrl: true);

      final updatedList = state.revisions.map((item) {
        if (item.id == updatedSelected.id) return updatedSelected;
        return item;
      }).toList();

      emit(
        state.copyWith(
          isSaving: false,
          selected: updatedSelected,
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
}