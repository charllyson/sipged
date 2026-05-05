import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';
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
        _tenantId = initialTenantId,
        super(RevisionMeasurementState.initial());

  final RevisionMeasurementRepository _repo;

  final String moduleId;

  UserPermissionData? _currentPermissions;
  String? _tenantId;

  void updatePermissions({
    UserPermissionData? permissions,
    String? tenantId,
  }) {
    _currentPermissions = permissions;
    _tenantId = tenantId;
  }

  bool get isEditable => _canWrite();

  bool _canWrite() {
    final permissions = _currentPermissions;

    if (permissions == null) return false;

    if (permissions.isSuperUserForTenant(_tenantId)) {
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

    if (permissions.isSuperUserForTenant(_tenantId)) {
      return true;
    }

    return permissions.canModuleString(
      module: moduleId,
      action: 'delete',
      tenantId: _tenantId,
    );
  }

  void _assertCanWrite() {
    if (_canWrite()) return;

    throw Exception(
      'Usuário sem permissão para alterar revisões. '
          'Módulo: $moduleId | tenantId: ${_tenantId ?? 'não definido'}',
    );
  }

  void _assertCanDelete() {
    if (_canDelete()) return;

    throw Exception(
      'Usuário sem permissão para apagar revisões. '
          'Módulo: $moduleId | tenantId: ${_tenantId ?? 'não definido'}',
    );
  }

  Future<void> loadByContract(String contractId) async {
    emit(
      state.copyWith(
        status: RevisionMeasurementStatus.loading,
        errorMessage: null,
        contractId: contractId,
        selected: null,
        selectedIndex: null,
        attachments: const [],
        selectedAttachmentIndex: null,
        isSaving: false,
      ),
    );

    try {
      final list = await _repo.getAllRevisionsOfContract(
        uidContract: contractId,
      );

      emit(
        state.copyWith(
          status: RevisionMeasurementStatus.loaded,
          revisions: list,
          errorMessage: null,
          contractId: contractId,
          isSaving: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: RevisionMeasurementStatus.error,
          errorMessage: e.toString(),
          isSaving: false,
        ),
      );
    }
  }

  Future<List<RevisionMeasurementData>> getAllRevisionsCollectionGroup() {
    return _repo.getAllRevisionsCollectionGroup();
  }

  double sum(List<RevisionMeasurementData> list) {
    return _repo.sumRevisions(list);
  }

  Future<void> saveOrUpdate({
    required String contractId,
    required String revisionMeasurementId,
    required RevisionMeasurementData data,
  }) async {
    _assertCanWrite();

    emit(
      state.copyWith(
        status: RevisionMeasurementStatus.saving,
        isSaving: true,
        errorMessage: null,
      ),
    );

    try {
      await _repo.saveOrUpdateRevision(
        contractId: contractId,
        revisionMeasurementId: revisionMeasurementId,
        rev: data.copyWith(
          id: revisionMeasurementId,
          contractId: contractId,
        ),
      );

      if (state.contractId == null || state.contractId == contractId) {
        await loadByContract(contractId);
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

  Future<void> delete({
    required String contractId,
    required String revisionId,
  }) async {
    _assertCanDelete();

    emit(
      state.copyWith(
        status: RevisionMeasurementStatus.saving,
        isSaving: true,
        errorMessage: null,
      ),
    );

    try {
      await _repo.deleteRevision(
        contractId: contractId,
        revisionId: revisionId,
      );

      if (state.contractId == null || state.contractId == contractId) {
        await loadByContract(contractId);
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

    final sel = state.revisions[index];
    final atts = sel.attachments ?? const <Attachment>[];

    emit(
      state.copyWith(
        selected: sel,
        selectedIndex: index,
        attachments: atts,
        selectedAttachmentIndex: null,
      ),
    );
  }

  void clearSelection() {
    emit(
      state.copyWith(
        selected: null,
        selectedIndex: null,
        attachments: const [],
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
    final contractId = state.contractId;

    if (contractId == null || selected?.id == null) return;

    emit(
      state.copyWith(
        isSaving: true,
        errorMessage: null,
      ),
    );

    try {
      await _repo.setAttachments(
        contractId: contractId,
        revisionId: selected!.id!,
        attachments: attachments,
      );

      final updatedSelected = selected.copyWith(attachments: attachments);

      final updatedList = state.revisions.map((e) {
        if (e.id == updatedSelected.id) return updatedSelected;
        return e;
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

  Future<void> addAttachmentWithPicker({
    required ProcessData contract,
    String label = '',
    void Function(double progress)? onProgress,
  }) async {
    _assertCanWrite();

    final selected = state.selected;
    final contractId = state.contractId;

    if (contractId == null || selected?.id == null) {
      throw Exception('Selecione uma revisão antes de anexar arquivos.');
    }

    emit(
      state.copyWith(
        isSaving: true,
        errorMessage: null,
      ),
    );

    try {
      final (bytes, originalName) = await _repo.pickFileBytes();

      final att = await _repo.uploadAttachmentBytes(
        contract: contract,
        revision: selected!,
        bytes: bytes,
        originalName: originalName,
        label: label,
        onProgress: onProgress,
      );

      final next = List<Attachment>.from(state.attachments)..add(att);

      await _repo.setAttachments(
        contractId: contractId,
        revisionId: selected.id!,
        attachments: next,
      );

      final updatedSelected = selected.copyWith(attachments: next);

      final updatedList = state.revisions.map((e) {
        if (e.id == updatedSelected.id) return updatedSelected;
        return e;
      }).toList();

      emit(
        state.copyWith(
          isSaving: false,
          attachments: next,
          revisions: updatedList,
          selected: updatedSelected,
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

  Future<void> deleteAttachmentAt(int index) async {
    _assertCanWrite();

    final selected = state.selected;
    final contractId = state.contractId;

    if (contractId == null || selected?.id == null) return;
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

      final storagePath = removed.path;

      if (storagePath.trim().isNotEmpty) {
        await _repo.deleteStorageByPath(storagePath);
      }

      await _repo.setAttachments(
        contractId: contractId,
        revisionId: selected!.id!,
        attachments: next,
      );

      final updatedSelected = selected.copyWith(attachments: next);

      final updatedList = state.revisions.map((e) {
        if (e.id == updatedSelected.id) return updatedSelected;
        return e;
      }).toList();

      emit(
        state.copyWith(
          isSaving: false,
          attachments: next,
          revisions: updatedList,
          selected: updatedSelected,
          selectedAttachmentIndex: null,
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
    final contractId = state.contractId;

    if (contractId == null || selected?.id == null) return;

    emit(
      state.copyWith(
        isSaving: true,
        errorMessage: null,
      ),
    );

    try {
      await _repo.salvarUrlPdfDaRevisionMeasurement(
        contractId: contractId,
        revisionMeasurementId: selected!.id!,
        url: '',
      );

      final updatedSelected = selected.copyWith(pdfUrl: null);

      final updatedList = state.revisions.map((e) {
        if (e.id == updatedSelected.id) return updatedSelected;
        return e;
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