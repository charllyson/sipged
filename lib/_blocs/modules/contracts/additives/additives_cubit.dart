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
    UserData? initialUser,
    UserPermissionData? initialPermissions,
    String? tenantId,
    this.moduleId = 'contracts_additives',
  })  : _currentUser = initialUser,
        _currentPermissions = initialPermissions,
        _tenantId = tenantId,
        super(AdditivesState.initial()) {
    _init();

    if (initialUser != null || initialPermissions != null) {
      updateUser(
        initialUser,
        permissions: initialPermissions,
        tenantId: tenantId,
      );
    }
  }

  final ContractData contract;
  final AdditivesRepository repository;
  final String moduleId;

  UserData? _currentUser;
  UserPermissionData? _currentPermissions;
  String? _tenantId;

  Future<void> _init() async {
    if (contract.id == null || contract.id!.isEmpty) {
      emit(
        state.copyWith(
          status: AdditivesStatus.loaded,
          additives: const <AdditivesData>[],
          existingOrders: <int>{},
          nextAvailableOrder: 1,
          clearSelected: true,
          clearSelectedIndex: true,
          editingMode: false,
          sideAttachments: <Attachment>[],
          sideLoading: false,
          clearUploadProgress: true,
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
    _currentUser = user ?? _currentUser;
    _currentPermissions = permissions ?? _permissionsFromUser(user) ?? _currentPermissions;
    _tenantId = tenantId ?? _tenantId;

    final editable = _canWrite();

    emit(state.copyWith(isEditable: editable));
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
      'Usuário sem permissão para alterar aditivos. '
          'Módulo: $moduleId | tenantId: ${_tenantId ?? 'não definido'}',
    );
  }

  void _assertCanDelete() {
    if (_canDelete()) return;

    throw Exception(
      'Usuário sem permissão para apagar aditivos. '
          'Módulo: $moduleId | tenantId: ${_tenantId ?? 'não definido'}',
    );
  }

  Future<void> loadAdditives() async {
    if (contract.id == null || contract.id!.isEmpty) {
      emit(
        state.copyWith(
          status: AdditivesStatus.loaded,
          additives: const <AdditivesData>[],
          existingOrders: <int>{},
          nextAvailableOrder: 1,
          clearSelected: true,
          clearSelectedIndex: true,
          editingMode: false,
          sideAttachments: <Attachment>[],
          sideLoading: false,
          clearUploadProgress: true,
        ),
      );
      return;
    }

    emit(state.copyWith(status: AdditivesStatus.loading));

    try {
      final list = await repository.ensureForContract(contract.id!);
      final orders = _extractExistingOrders(list);
      final next = _computeNextOrder(orders);

      emit(
        state.copyWith(
          status: AdditivesStatus.loaded,
          additives: list,
          existingOrders: orders,
          nextAvailableOrder: next,
          isEditable: _canWrite(),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AdditivesStatus.error,
          errorMessage: 'Erro ao carregar aditivos: $e',
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
          sideAttachments: <Attachment>[],
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
        sideAttachments: <Attachment>[],
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
        sideAttachments: <Attachment>[],
        nextAvailableOrder: next,
        formValid: false,
        sideLoading: false,
        clearUploadProgress: true,
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

  String _onlyDigits(String s) {
    return s.replaceAll(RegExp(r'[^\d]'), '');
  }

  AdditivesData? _findByOrder(int order) {
    if (order <= 0) return null;

    try {
      return state.additives.firstWhere(
            (e) => (e.additiveOrder ?? 0) == order,
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

    if (contract.id == null || contract.id!.trim().isEmpty) {
      throw Exception('Contrato não informado para salvar o aditivo.');
    }

    emit(state.copyWith(isSaving: true, clearError: true));

    try {
      final int ord = int.tryParse(orderText.trim()) ?? 0;

      final AdditivesData? byOrder = _findByOrder(ord);
      final String? resolvedId = state.selected?.id ?? byOrder?.id;

      final additive = AdditivesData(
        id: resolvedId,
        additiveNumberProcess: processText.trim(),
        additiveOrder: ord > 0 ? ord : null,
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
      );

      await repository.saveOrUpdateAdditive(
        contractId: contract.id!,
        data: additive,
      );

      final bool created = resolvedId == null;

      await loadAdditives();

      if (ord > 0) {
        selectAdditiveByOrder(ord);
      } else {
        createNewAdditive();
      }

      return AdditiveSaveResult(
        created: created,
        order: ord > 0 ? ord : null,
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

    final selected = state.selected;

    if (contract.id == null || contract.id!.trim().isEmpty) {
      throw Exception('Contrato não informado para excluir o aditivo.');
    }

    if (selected == null || selected.id == null || selected.id!.trim().isEmpty) {
      throw Exception('Nenhum aditivo selecionado para exclusão.');
    }

    emit(state.copyWith(isSaving: true, clearError: true));

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
        contractId: contract.id!,
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
    final selected = state.selected;

    if (selected == null || contract.id == null || selected.id == null) {
      emit(
        state.copyWith(
          sideAttachments: <Attachment>[],
          sideLoading: false,
          clearUploadProgress: true,
        ),
      );
      return;
    }

    emit(state.copyWith(sideLoading: true, clearUploadProgress: true));

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

      if ((selected.pdfUrl ?? '').isNotEmpty) {
        emit(
          state.copyWith(
            sideAttachments: <Attachment>[],
            sideLoading: false,
            clearUploadProgress: true,
          ),
        );
        return;
      }

      final files = await repository.listarArquivosDoAditivo(
        contractId: contract.id!,
        additiveId: selected.id!,
      );

      if (files.isEmpty) {
        emit(
          state.copyWith(
            sideAttachments: <Attachment>[],
            sideLoading: false,
            clearUploadProgress: true,
          ),
        );
        return;
      }

      final List<Attachment> list = files.map((f) {
        return Attachment(
          id: f.name,
          label: f.name.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), ''),
          url: f.url,
          path: 'contracts/${contract.id}/additives/${selected.id}/${f.name}',
          ext: RegExp(r'\.([a-z0-9]+)$', caseSensitive: false)
              .firstMatch(f.name)
              ?.group(0) ??
              '',
          createdAt: DateTime.now(),
          createdBy: _currentUser?.uid,
        );
      }).toList();

      await repository.setAttachments(
        contractId: contract.id!,
        additiveId: selected.id!,
        attachments: list,
      );

      final updatedSelected = selected.copyWith(
        pdfUrl: null,
        attachments: list,
      );

      emit(
        state.copyWith(
          selected: updatedSelected,
          sideAttachments: list,
          sideLoading: false,
          clearUploadProgress: true,
        ),
      );
    } catch (_) {
      emit(state.copyWith(sideLoading: false, clearUploadProgress: true));
      rethrow;
    }
  }

  String _suggestLabelFromName(AdditivesData additive, String original) {
    final base = original
        .split('/')
        .last
        .replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');

    final ord = additive.additiveOrder ?? 0;

    return 'Aditivo $ord - $base';
  }

  Future<AttachmentAddResult> addAttachmentWithPicker(
      BuildContext context,
      ) async {
    _assertCanWrite();

    final cId = contract.id;
    final a = state.selected;

    if (cId == null || cId.trim().isEmpty) {
      throw Exception('Contrato não informado para anexar arquivo.');
    }

    if (a == null || a.id == null || a.id!.trim().isEmpty) {
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

      final label = _suggestLabelFromName(a, originalName);

      final att = await repository.uploadAttachmentBytes(
        contract: contract,
        additive: a,
        bytes: bytes,
        originalName: originalName,
        label: label,
        onProgress: (p) {
          final v = p.isNaN ? 0.0 : p.clamp(0.0, 1.0);
          emit(state.copyWith(uploadProgress: v, sideLoading: true));
        },
      );

      final current = List<Attachment>.from(
        a.attachments ?? const <Attachment>[],
      )..add(att);

      await repository.setAttachments(
        contractId: cId,
        additiveId: a.id!,
        attachments: current,
      );

      final updatedSelected = a.copyWith(
        attachments: current,
      );

      emit(
        state.copyWith(
          selected: updatedSelected,
          sideAttachments: current,
          sideLoading: false,
          clearUploadProgress: true,
        ),
      );

      return AttachmentAddResult(
        additiveId: a.id,
        additiveOrder: a.additiveOrder,
        attachment: att,
      );
    } catch (_) {
      emit(
        state.copyWith(
          sideLoading: false,
          clearUploadProgress: true,
          errorMessage: 'Erro ao anexar',
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

    final a = state.selected;

    if (a == null || a.id == null || a.id!.trim().isEmpty) {
      throw Exception('Nenhum aditivo selecionado.');
    }

    if (a.attachments == null) {
      throw Exception('O aditivo selecionado não possui anexos.');
    }

    if (index < 0 || index >= a.attachments!.length) {
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
      final oldAtt = a.attachments![index];

      final updated = Attachment(
        id: oldAtt.id,
        label: newLabel.trim().isEmpty ? oldAtt.label : newLabel.trim(),
        url: oldAtt.url,
        path: oldAtt.path,
        ext: oldAtt.ext,
        size: oldAtt.size,
        createdAt: oldAtt.createdAt,
        createdBy: oldAtt.createdBy,
        updatedAt: DateTime.now(),
        updatedBy: _currentUser?.uid,
      );

      final list = List<Attachment>.from(a.attachments!)..[index] = updated;

      await repository.setAttachments(
        contractId: contract.id!,
        additiveId: a.id!,
        attachments: list,
      );

      final updatedSelected = a.copyWith(
        attachments: list,
      );

      emit(
        state.copyWith(
          selected: updatedSelected,
          sideAttachments: list,
          sideLoading: false,
          clearUploadProgress: true,
        ),
      );

      return AttachmentRenameResult(
        additiveId: a.id,
        additiveOrder: a.additiveOrder,
        oldAttachment: oldAtt,
        newAttachment: updated,
      );
    } catch (_) {
      emit(
        state.copyWith(
          sideLoading: false,
          clearUploadProgress: true,
          errorMessage: 'Erro ao renomear',
        ),
      );

      rethrow;
    }
  }

  Future<AttachmentDeleteResult> deleteAttachment(int index) async {
    _assertCanWrite();

    final a = state.selected;

    if (a == null || a.id == null || contract.id == null) {
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
      final atts = List<Attachment>.from(
        a.attachments ?? const <Attachment>[],
      );

      if (index < 0 || index >= atts.length) {
        throw Exception('Índice de anexo inválido.');
      }

      final removed = atts.removeAt(index);

      if (removed.path.isNotEmpty) {
        await repository.deleteStorageByPath(removed.path);
      }

      await repository.setAttachments(
        contractId: contract.id!,
        additiveId: a.id!,
        attachments: atts,
      );

      final updatedSelected = a.copyWith(
        attachments: atts,
      );

      emit(
        state.copyWith(
          selected: updatedSelected,
          sideAttachments: atts,
          sideLoading: false,
          clearUploadProgress: true,
        ),
      );

      return AttachmentDeleteResult(
        additiveId: a.id,
        additiveOrder: a.additiveOrder,
        attachment: removed,
      );
    } catch (_) {
      emit(
        state.copyWith(
          sideLoading: false,
          clearUploadProgress: true,
          errorMessage: 'Erro ao remover',
        ),
      );

      rethrow;
    }
  }

  Set<int> _extractExistingOrders(List<AdditivesData> list) {
    return list
        .map((e) => e.additiveOrder ?? 0)
        .where((e) => e > 0)
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