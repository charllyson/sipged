// lib/_blocs/modules/contracts/additives/additives_cubit.dart

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';
import 'package:sipged/_blocs/modules/contracts/additives/additives_data.dart';
import 'package:sipged/_blocs/modules/contracts/additives/additives_repository.dart';

import 'package:sipged/_blocs/system/permission/permission_data.dart';
import 'package:sipged/_blocs/system/user/user_data.dart';

import 'package:sipged/_utils/formatters/sipged_format_dates.dart';
import 'package:sipged/_utils/formatters/sipged_format_numbers.dart';
import 'package:sipged/_widgets/list/files/attachment.dart';

import 'additives_state.dart';

class AdditiveSaveResult {
  const AdditiveSaveResult({
    required this.created,
    required this.order,
    required this.additiveId,
  });

  final bool created;
  final int? order;
  final String? additiveId;
}

class AdditiveDeleteResult {
  const AdditiveDeleteResult({
    required this.deleted,
    required this.order,
    required this.additiveId,
    required this.process,
    required this.type,
    required this.value,
    required this.date,
    required this.validityExecutionDays,
    required this.validityContractDays,
  });

  final bool deleted;
  final int? order;
  final String? additiveId;
  final String? process;
  final String? type;
  final double? value;
  final DateTime? date;
  final int? validityExecutionDays;
  final int? validityContractDays;
}

class AttachmentAddResult {
  const AttachmentAddResult({
    required this.additiveId,
    required this.additiveOrder,
    required this.attachment,
  });

  final String? additiveId;
  final int? additiveOrder;
  final Attachment attachment;
}

class AttachmentDeleteResult {
  const AttachmentDeleteResult({
    required this.additiveId,
    required this.additiveOrder,
    required this.attachment,
  });

  final String? additiveId;
  final int? additiveOrder;
  final Attachment? attachment;
}

class AttachmentRenameResult {
  const AttachmentRenameResult({
    required this.additiveId,
    required this.additiveOrder,
    required this.oldAttachment,
    required this.newAttachment,
  });

  final String? additiveId;
  final int? additiveOrder;
  final Attachment oldAttachment;
  final Attachment newAttachment;
}

class AdditivesCubit extends Cubit<AdditivesState> {
  AdditivesCubit({
    required this.contract,
    required this.repository,
    required String tenantId,
    UserData? initialUser,
    UserPermissionData? initialPermissions,
    this.moduleId = 'contracts_additives',
  })  : _currentUser = initialUser,
        _currentPermissions = initialPermissions,
        _tenantId = _cleanRequiredTenantId(tenantId),
        super(AdditivesState.initial()) {
    _syncRepositoryTenant();

    if (initialUser != null || initialPermissions != null) {
      updateUser(
        initialUser,
        permissions: initialPermissions,
        tenantId: _tenantId,
      );
    } else {
      emit(
        state.copyWith(
          isEditable: false,
        ),
      );
    }

    unawaited(_init());
  }

  final ContractData contract;
  final AdditivesRepository repository;
  final String moduleId;

  UserData? _currentUser;
  UserPermissionData? _currentPermissions;
  String _tenantId;

  static String _cleanRequiredTenantId(String tenantId) {
    final clean = tenantId.trim();

    if (clean.isEmpty) {
      throw ArgumentError(
        'tenantId é obrigatório para criar AdditivesCubit.',
      );
    }

    return clean;
  }

  static String? _cleanOptionalTenantId(String? tenantId) {
    final clean = tenantId?.trim();

    if (clean == null || clean.isEmpty) return null;

    return clean;
  }

  void _syncRepositoryTenant() {
    repository.setActiveTenantId(_tenantId);
  }

  String _requireTenantId() {
    final id = _tenantId.trim();

    if (id.isEmpty) {
      throw StateError(
        'Nenhuma empresa ativa foi selecionada para acessar aditivos.',
      );
    }

    repository.setActiveTenantId(id);

    return id;
  }

  Future<void> _init() async {
    _requireTenantId();

    final contractId = contract.id?.trim();

    if (contractId == null || contractId.isEmpty) {
      emit(
        state.copyWith(
          status: AdditivesStatus.loaded,
          additives: const <AdditivesData>[],
          existingOrders: <int>{},
          nextAvailableOrder: 1,
          clearSelected: true,
          clearSelectedIndex: true,
          editingMode: false,
          sideAttachments: const <Attachment>[],
          sideLoading: false,
          clearUploadProgress: true,
          clearError: true,
          isEditable: _canWrite(),
        ),
      );
      return;
    }

    await loadAdditives();
  }

  void updateUser(
      UserData? user, {
        UserPermissionData? permissions,
        String? tenantId,
      }) {
    final previousTenantId = _tenantId;

    _currentUser = user ?? _currentUser;
    _currentPermissions =
        permissions ?? _permissionsFromUser(user) ?? _currentPermissions;

    final resolvedTenantId = _cleanOptionalTenantId(tenantId);

    if (resolvedTenantId != null) {
      _tenantId = resolvedTenantId;
    }

    _syncRepositoryTenant();

    emit(
      state.copyWith(
        isEditable: _canWrite(),
        clearError: true,
      ),
    );

    final contractId = contract.id?.trim();

    if (previousTenantId != _tenantId &&
        contractId != null &&
        contractId.isNotEmpty) {
      unawaited(loadAdditives());
    }
  }

  UserPermissionData? _permissionsFromUser(UserData? user) {
    if (user == null) return null;

    final uid = (user.uid ?? '').trim();

    if (uid.isEmpty) return null;

    final raw = user.userSnap?.data();

    if (raw is Map<String, dynamic>) {
      return UserPermissionData.fromMap(
        uid: uid,
        map: raw,
      );
    }

    return UserPermissionData(uid: uid);
  }

  bool get isEditable => _canWrite();

  bool _canWrite() {
    final permissions = _currentPermissions;

    if (permissions == null) return false;

    final tenantId = _requireTenantId();

    if (permissions.isGlobalSuperUser ||
        permissions.isSuperUserForTenant(tenantId)) {
      return true;
    }

    return permissions.canModuleString(
      module: moduleId,
      action: 'create',
      tenantId: tenantId,
    ) ||
        permissions.canModuleString(
          module: moduleId,
          action: 'edit',
          tenantId: tenantId,
        ) ||
        permissions.canModuleString(
          module: moduleId,
          action: 'delete',
          tenantId: tenantId,
        );
  }

  bool _canDelete() {
    final permissions = _currentPermissions;

    if (permissions == null) return false;

    final tenantId = _requireTenantId();

    if (permissions.isGlobalSuperUser ||
        permissions.isSuperUserForTenant(tenantId)) {
      return true;
    }

    return permissions.canModuleString(
      module: moduleId,
      action: 'delete',
      tenantId: tenantId,
    );
  }

  void _assertCanWrite() {
    _requireTenantId();

    if (_canWrite()) return;

    throw Exception(
      'Usuário sem permissão para alterar aditivos. '
          'Módulo: $moduleId | tenantId: $_tenantId',
    );
  }

  void _assertCanDelete() {
    _requireTenantId();

    if (_canDelete()) return;

    throw Exception(
      'Usuário sem permissão para apagar aditivos. '
          'Módulo: $moduleId | tenantId: $_tenantId',
    );
  }

  Future<void> loadAdditives() async {
    _requireTenantId();

    final contractId = contract.id?.trim();

    if (contractId == null || contractId.isEmpty) {
      emit(
        state.copyWith(
          status: AdditivesStatus.loaded,
          additives: const <AdditivesData>[],
          existingOrders: <int>{},
          nextAvailableOrder: 1,
          clearSelected: true,
          clearSelectedIndex: true,
          editingMode: false,
          sideAttachments: const <Attachment>[],
          sideLoading: false,
          clearUploadProgress: true,
          clearError: true,
          isEditable: _canWrite(),
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: AdditivesStatus.loading,
        clearError: true,
        isEditable: _canWrite(),
      ),
    );

    try {
      final list = await repository.ensureForContract(contractId);
      final orders = _extractExistingOrders(list);
      final next = _computeNextOrder(orders);

      emit(
        state.copyWith(
          status: AdditivesStatus.loaded,
          additives: list,
          existingOrders: orders,
          nextAvailableOrder: next,
          isEditable: _canWrite(),
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AdditivesStatus.error,
          errorMessage: 'Erro ao carregar aditivos: $e',
          isEditable: _canWrite(),
        ),
      );
    }
  }

  void selectAdditiveByIndex(int index) {
    if (index < 0 || index >= state.additives.length) {
      _clearSelection();
      return;
    }

    if (state.selectedIndex == index) {
      _clearSelection();
      return;
    }

    final data = state.additives[index];
    _selectAdditive(data, index);
  }

  void selectAdditive(AdditivesData data) {
    final index = state.additives.indexWhere((e) => e.id == data.id);

    if (index == -1) {
      _clearSelection();
      return;
    }

    if (state.selected?.id == data.id) {
      _clearSelection();
      return;
    }

    _selectAdditive(data, index);
  }

  void selectAdditiveByOrder(int order) {
    if (order <= 0) {
      _clearSelection();
      return;
    }

    final index = state.additives.indexWhere(
          (e) => (e.additiveOrder ?? 0) == order,
    );

    if (index == -1) {
      emit(
        state.copyWith(
          clearSelected: true,
          clearSelectedIndex: true,
          editingMode: false,
          sideAttachments: const <Attachment>[],
          sideLoading: false,
          clearUploadProgress: true,
        ),
      );
      return;
    }

    final data = state.additives[index];

    if (state.selected?.id == data.id) {
      emit(
        state.copyWith(
          selectedIndex: index,
          editingMode: true,
          sideAttachments: data.attachments ?? const <Attachment>[],
        ),
      );
      return;
    }

    _selectAdditive(data, index);
  }

  void _selectAdditive(AdditivesData data, int? index) {
    emit(
      state.copyWith(
        selected: data,
        selectedIndex: index,
        editingMode: true,
        sideAttachments: data.attachments ?? const <Attachment>[],
        clearSelected: false,
        sideLoading: false,
        clearUploadProgress: true,
      ),
    );
  }

  void _clearSelection() {
    emit(
      state.copyWith(
        clearSelected: true,
        clearSelectedIndex: true,
        editingMode: false,
        sideAttachments: const <Attachment>[],
        sideLoading: false,
        clearUploadProgress: true,
      ),
    );
  }

  void createNewAdditive() {
    final next = _computeNextOrder(state.existingOrders);

    emit(
      state.copyWith(
        editingMode: false,
        clearSelected: true,
        clearSelectedIndex: true,
        sideAttachments: const <Attachment>[],
        nextAvailableOrder: next,
        formValid: false,
        sideLoading: false,
        clearUploadProgress: true,
        clearError: true,
      ),
    );
  }

  void updateFormValidity({
    required String typeText,
    required String dateText,
    required String processText,
    required String valueText,
    required String addExecText,
    required String addContractText,
  }) {
    final tipo = typeText.toUpperCase();
    final obrig = <String>[dateText, processText, typeText];

    if (tipo == 'VALOR' || tipo == 'REEQUÍLIBRIO') {
      obrig.add(valueText);
    } else if (tipo == 'PRAZO') {
      obrig.addAll([addExecText, addContractText]);
    } else if (tipo == 'RATIFICAÇÃO' || tipo == 'RENOVAÇÃO') {
      obrig.addAll([valueText, addExecText, addContractText]);
    }

    final valid = obrig.every((s) => s.trim().isNotEmpty);

    if (valid != state.formValid) {
      emit(state.copyWith(formValid: valid));
    }
  }

  String _onlyDigits(String value) {
    return value.replaceAll(RegExp(r'[^\d]'), '');
  }

  AdditivesData? _findByOrder(int order) {
    if (order <= 0) return null;

    try {
      return state.additives.firstWhere(
            (item) => (item.additiveOrder ?? 0) == order,
      );
    } catch (_) {
      return null;
    }
  }

  String? _resolveSelectedIdFallback({
    required String? selectedId,
    required String? fallbackId,
  }) {
    final cleanSelected = selectedId?.trim();

    if (cleanSelected != null && cleanSelected.isNotEmpty) {
      return cleanSelected;
    }

    final cleanFallback = fallbackId?.trim();

    if (cleanFallback != null && cleanFallback.isNotEmpty) {
      return cleanFallback;
    }

    return null;
  }

  Future<AdditiveSaveResult> saveOrUpdate({
    required String orderText,
    required String dateText,
    required String valueText,
    required String addDaysExecText,
    required String addDaysContractText,
    required String processText,
    required String typeText,
  }) async {
    _assertCanWrite();

    final contractId = contract.id?.trim();

    if (contractId == null || contractId.isEmpty) {
      throw Exception('Contrato não informado para salvar o aditivo.');
    }

    emit(
      state.copyWith(
        isSaving: true,
        clearError: true,
      ),
    );

    try {
      final int order = int.tryParse(orderText.trim()) ?? 0;

      final AdditivesData? byOrder = _findByOrder(order);
      final String? resolvedId = state.selected?.id ?? byOrder?.id;

      final additive = AdditivesData(
        id: resolvedId,
        contractId: contractId,
        additiveNumberProcess: processText.trim(),
        additiveOrder: order > 0 ? order : null,
        additiveDate: SipGedFormatDates.ddMMyyyyToDate(dateText),
        additiveValue: SipGedFormatNumbers.toDouble(valueText),
        additiveValidityContractDays: int.tryParse(
          _onlyDigits(addDaysContractText),
        ),
        additiveValidityExecutionDays: int.tryParse(
          _onlyDigits(addDaysExecText),
        ),
        typeOfAdditive: typeText.trim(),
        pdfUrl: state.selected?.pdfUrl ?? byOrder?.pdfUrl,
        attachments: state.selected?.attachments ?? byOrder?.attachments,
        createdAt: state.selected?.createdAt ?? byOrder?.createdAt,
        createdBy: state.selected?.createdBy ?? byOrder?.createdBy,
        updatedAt: DateTime.now(),
        updatedBy: _currentUser?.uid ?? _currentPermissions?.uid,
      );

      await repository.saveOrUpdateAdditive(
        contractId: contractId,
        data: additive,
      );

      final bool created = resolvedId == null;

      await loadAdditives();

      if (order > 0) {
        selectAdditiveByOrder(order);
      } else {
        createNewAdditive();
      }

      return AdditiveSaveResult(
        created: created,
        order: order > 0 ? order : null,
        additiveId: _resolveSelectedIdFallback(
          selectedId: state.selected?.id,
          fallbackId: resolvedId,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isSaving: false,
          errorMessage: 'Erro ao salvar: $e',
        ),
      );

      rethrow;
    } finally {
      emit(state.copyWith(isSaving: false));
    }
  }

  Future<AdditiveDeleteResult> deleteSelectedAdditive() async {
    _assertCanDelete();

    final contractId = contract.id?.trim();
    final selected = state.selected;

    if (contractId == null || contractId.isEmpty) {
      throw Exception('Contrato não informado para excluir o aditivo.');
    }

    if (selected == null || selected.id == null || selected.id!.trim().isEmpty) {
      throw Exception('Nenhum aditivo selecionado para exclusão.');
    }

    emit(
      state.copyWith(
        isSaving: true,
        clearError: true,
      ),
    );

    try {
      final result = AdditiveDeleteResult(
        deleted: true,
        order: selected.additiveOrder,
        additiveId: selected.id,
        process: selected.additiveNumberProcess,
        type: selected.typeOfAdditive,
        value: selected.additiveValue,
        date: selected.additiveDate,
        validityExecutionDays: selected.additiveValidityExecutionDays,
        validityContractDays: selected.additiveValidityContractDays,
      );

      await repository.deleteAdditive(
        contractId: contractId,
        additiveId: selected.id!,
      );

      await loadAdditives();
      createNewAdditive();

      return result;
    } catch (e) {
      emit(
        state.copyWith(
          isSaving: false,
          errorMessage: 'Erro ao deletar: $e',
        ),
      );

      rethrow;
    } finally {
      emit(state.copyWith(isSaving: false));
    }
  }

  Future<void> reloadAttachments() async {
    _requireTenantId();

    final selected = state.selected;
    final contractId = contract.id?.trim();

    if (selected == null ||
        contractId == null ||
        contractId.isEmpty ||
        selected.id == null ||
        selected.id!.trim().isEmpty) {
      emit(
        state.copyWith(
          sideAttachments: const <Attachment>[],
          sideLoading: false,
          clearUploadProgress: true,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        sideLoading: true,
        clearUploadProgress: true,
        clearError: true,
      ),
    );

    try {
      if ((selected.attachments ?? const <Attachment>[]).isNotEmpty) {
        emit(
          state.copyWith(
            sideAttachments: selected.attachments!,
            sideLoading: false,
            clearUploadProgress: true,
          ),
        );
        return;
      }

      if ((selected.pdfUrl ?? '').trim().isNotEmpty) {
        emit(
          state.copyWith(
            sideAttachments: const <Attachment>[],
            sideLoading: false,
            clearUploadProgress: true,
          ),
        );
        return;
      }

      final files = await repository.listarArquivosDoAditivo(
        contractId: contractId,
        additiveId: selected.id!,
      );

      if (files.isEmpty) {
        emit(
          state.copyWith(
            sideAttachments: const <Attachment>[],
            sideLoading: false,
            clearUploadProgress: true,
          ),
        );
        return;
      }

      final tenantId = _requireTenantId();

      final List<Attachment> list = files.map((file) {
        final ext = RegExp(
          r'\.([a-z0-9]+)$',
          caseSensitive: false,
        ).firstMatch(file.name)?.group(0) ??
            '';

        return Attachment(
          id: file.name,
          label: file.name.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), ''),
          url: file.url,
          path:
          'tenants/$tenantId/contracts/$contractId/additives/${selected.id}/${file.name}',
          ext: ext,
          createdAt: DateTime.now(),
          createdBy: _currentUser?.uid ?? _currentPermissions?.uid,
        );
      }).toList();

      await repository.setAttachments(
        contractId: contractId,
        additiveId: selected.id!,
        attachments: list,
      );

      emit(
        state.copyWith(
          selected: selected.copyWith(
            pdfUrl: null,
            attachments: list,
          ),
          sideAttachments: list,
          sideLoading: false,
          clearUploadProgress: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          sideLoading: false,
          clearUploadProgress: true,
          errorMessage: 'Erro ao carregar anexos: $e',
        ),
      );

      rethrow;
    }
  }

  String _suggestLabelFromName(AdditivesData additive, String original) {
    final base = original
        .split('/')
        .last
        .replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');

    final order = additive.additiveOrder ?? 0;

    return 'Aditivo $order - $base';
  }

  Future<AttachmentAddResult> addAttachmentWithPicker(
      BuildContext context,
      ) async {
    _assertCanWrite();

    final contractId = contract.id?.trim();
    final additive = state.selected;

    if (contractId == null || contractId.isEmpty) {
      throw Exception('Contrato não informado para anexar arquivo.');
    }

    if (additive == null ||
        additive.id == null ||
        additive.id!.trim().isEmpty) {
      throw Exception('Selecione ou salve um aditivo antes de anexar arquivos.');
    }

    if (!state.canAddFile) {
      throw Exception('Não é possível adicionar arquivo neste momento.');
    }

    emit(
      state.copyWith(
        sideLoading: true,
        uploadProgress: 0.0,
        clearError: true,
      ),
    );

    try {
      final (Uint8List bytes, String originalName) =
      await repository.pickFileBytes();

      final label = _suggestLabelFromName(additive, originalName);

      final attachment = await repository.uploadAttachmentBytes(
        contract: contract,
        additive: additive,
        bytes: bytes,
        originalName: originalName,
        label: label,
        onProgress: (progress) {
          final value = (progress.isNaN ? 0.0 : progress.clamp(0.0, 1.0))
              .toDouble();

          emit(
            state.copyWith(
              uploadProgress: value,
              sideLoading: true,
            ),
          );
        },
      );

      final current = List<Attachment>.from(
        additive.attachments ?? const <Attachment>[],
      )..add(attachment);

      await repository.setAttachments(
        contractId: contractId,
        additiveId: additive.id!,
        attachments: current,
      );

      emit(
        state.copyWith(
          selected: additive.copyWith(
            attachments: current,
          ),
          sideAttachments: current,
          sideLoading: false,
          clearUploadProgress: true,
        ),
      );

      return AttachmentAddResult(
        additiveId: additive.id,
        additiveOrder: additive.additiveOrder,
        attachment: attachment,
      );
    } catch (e) {
      emit(
        state.copyWith(
          sideLoading: false,
          clearUploadProgress: true,
          errorMessage: 'Erro ao anexar: $e',
        ),
      );

      rethrow;
    }
  }

  Future<AttachmentRenameResult> renameAttachment({
    required int index,
    required String newLabel,
  }) async {
    _assertCanWrite();

    final contractId = contract.id?.trim();
    final additive = state.selected;

    if (contractId == null || contractId.isEmpty) {
      throw Exception('Contrato não informado para renomear anexo.');
    }

    if (additive == null ||
        additive.id == null ||
        additive.id!.trim().isEmpty) {
      throw Exception('Nenhum aditivo selecionado.');
    }

    final attachments = additive.attachments ?? const <Attachment>[];

    if (attachments.isEmpty) {
      throw Exception('O aditivo selecionado não possui anexos.');
    }

    if (index < 0 || index >= attachments.length) {
      throw Exception('Índice de anexo inválido.');
    }

    emit(
      state.copyWith(
        sideLoading: true,
        clearUploadProgress: true,
        clearError: true,
      ),
    );

    try {
      final oldAttachment = attachments[index];

      final updated = Attachment(
        id: oldAttachment.id,
        label: newLabel.trim().isEmpty ? oldAttachment.label : newLabel.trim(),
        url: oldAttachment.url,
        path: oldAttachment.path,
        ext: oldAttachment.ext,
        size: oldAttachment.size,
        createdAt: oldAttachment.createdAt,
        createdBy: oldAttachment.createdBy,
        updatedAt: DateTime.now(),
        updatedBy: _currentUser?.uid ?? _currentPermissions?.uid,
      );

      final list = List<Attachment>.from(attachments);
      list[index] = updated;

      await repository.setAttachments(
        contractId: contractId,
        additiveId: additive.id!,
        attachments: list,
      );

      emit(
        state.copyWith(
          selected: additive.copyWith(
            attachments: list,
          ),
          sideAttachments: list,
          sideLoading: false,
          clearUploadProgress: true,
        ),
      );

      return AttachmentRenameResult(
        additiveId: additive.id,
        additiveOrder: additive.additiveOrder,
        oldAttachment: oldAttachment,
        newAttachment: updated,
      );
    } catch (e) {
      emit(
        state.copyWith(
          sideLoading: false,
          clearUploadProgress: true,
          errorMessage: 'Erro ao renomear: $e',
        ),
      );

      rethrow;
    }
  }

  Future<AttachmentDeleteResult> deleteAttachment(int index) async {
    _assertCanWrite();

    final contractId = contract.id?.trim();
    final additive = state.selected;

    if (contractId == null || contractId.isEmpty) {
      throw Exception('Contrato não informado para remover anexo.');
    }

    if (additive == null ||
        additive.id == null ||
        additive.id!.trim().isEmpty) {
      throw Exception('Nenhum aditivo selecionado para remover anexo.');
    }

    emit(
      state.copyWith(
        sideLoading: true,
        clearUploadProgress: true,
        clearError: true,
      ),
    );

    try {
      final attachments = List<Attachment>.from(
        additive.attachments ?? const <Attachment>[],
      );

      if (index < 0 || index >= attachments.length) {
        throw Exception('Índice de anexo inválido.');
      }

      final removed = attachments.removeAt(index);

      if (removed.path.trim().isNotEmpty) {
        await repository.deleteStorageByPath(removed.path);
      }

      await repository.setAttachments(
        contractId: contractId,
        additiveId: additive.id!,
        attachments: attachments,
      );

      emit(
        state.copyWith(
          selected: additive.copyWith(
            attachments: attachments,
            clearAttachments: attachments.isEmpty,
          ),
          sideAttachments: attachments,
          sideLoading: false,
          clearUploadProgress: true,
        ),
      );

      return AttachmentDeleteResult(
        additiveId: additive.id,
        additiveOrder: additive.additiveOrder,
        attachment: removed,
      );
    } catch (e) {
      emit(
        state.copyWith(
          sideLoading: false,
          clearUploadProgress: true,
          errorMessage: 'Erro ao remover: $e',
        ),
      );

      rethrow;
    }
  }

  Set<int> _extractExistingOrders(List<AdditivesData> list) {
    return list
        .map((item) => item.additiveOrder ?? 0)
        .where((order) => order > 0)
        .toSet();
  }

  int _computeNextOrder(Set<int> existing) {
    if (existing.isEmpty) return 1;

    for (int i = 1; i <= existing.length + 1; i++) {
      if (!existing.contains(i)) return i;
    }

    final max = existing.reduce((a, b) => a > b ? a : b);

    return max + 1;
  }
}