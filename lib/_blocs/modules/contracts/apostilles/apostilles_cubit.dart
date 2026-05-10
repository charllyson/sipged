// lib/_blocs/modules/contracts/apostilles/apostilles_cubit.dart

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';
import 'package:sipged/_blocs/modules/contracts/apostilles/apostilles_data.dart';
import 'package:sipged/_blocs/modules/contracts/apostilles/apostilles_repository.dart';

import 'package:sipged/_blocs/system/permission/permission_data.dart';
import 'package:sipged/_blocs/system/user/user_data.dart';

import 'package:sipged/_utils/formatters/sipged_format_dates.dart';
import 'package:sipged/_utils/formatters/sipged_format_numbers.dart';

import 'package:sipged/_widgets/list/files/attachment.dart';

import 'apostilles_state.dart';

class ApostilleSaveResult {
  const ApostilleSaveResult({
    required this.created,
    required this.order,
    required this.apostilleId,
  });

  final bool created;
  final int? order;
  final String? apostilleId;
}

class ApostilleDeleteResult {
  const ApostilleDeleteResult({
    required this.deleted,
    required this.order,
    required this.apostilleId,
    required this.process,
    required this.value,
    required this.date,
  });

  final bool deleted;
  final int? order;
  final String? apostilleId;
  final String? process;
  final double? value;
  final DateTime? date;
}

class ApostilleAttachmentAddResult {
  const ApostilleAttachmentAddResult({
    required this.apostilleId,
    required this.apostilleOrder,
    required this.attachment,
  });

  final String? apostilleId;
  final int? apostilleOrder;
  final Attachment attachment;
}

class ApostilleAttachmentDeleteResult {
  const ApostilleAttachmentDeleteResult({
    required this.apostilleId,
    required this.apostilleOrder,
    required this.attachment,
  });

  final String? apostilleId;
  final int? apostilleOrder;
  final Attachment? attachment;
}

class ApostilleAttachmentRenameResult {
  const ApostilleAttachmentRenameResult({
    required this.apostilleId,
    required this.apostilleOrder,
    required this.oldAttachment,
    required this.newAttachment,
  });

  final String? apostilleId;
  final int? apostilleOrder;
  final Attachment oldAttachment;
  final Attachment newAttachment;
}

class ApostillesCubit extends Cubit<ApostillesState> {
  ApostillesCubit({
    required this.contract,
    required this.repository,
    UserData? initialUser,
    UserPermissionData? initialPermissions,
    String? tenantId,
    this.moduleId = 'contracts_apostilles',
    this.enforcePermissions = false,
  })  : _currentUser = initialUser,
        _currentPermissions = initialPermissions,
        _tenantId = _resolveInitialTenantId(
          tenantId: tenantId,
          permissions: initialPermissions,
          user: initialUser,
        ),
        super(ApostillesState.initial()) {
    _syncRepositoryTenant();

    if (initialUser != null || initialPermissions != null) {
      updateUser(
        initialUser,
        permissions: initialPermissions,
        tenantId: _tenantId,
        reload: false,
      );
    } else {
      emit(state.copyWith(isEditable: !enforcePermissions));
    }

    final contractId = contract.id?.trim();

    if (contractId == null || contractId.isEmpty) {
      _emitEmptyLoaded();
      return;
    }

    if (_hasTenantId) {
      unawaited(loadApostilles());
    } else {
      emit(
        state.copyWith(
          status: ApostillesStatus.initial,
          apostilles: const <ApostillesData>[],
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
    }
  }

  final ContractData contract;
  final ApostillesRepository repository;

  final String moduleId;

  /// Quando false, não bloqueia gravação se a permissão ainda não foi injetada.
  final bool enforcePermissions;

  UserData? _currentUser;
  UserPermissionData? _currentPermissions;
  String? _tenantId;

  bool get _hasTenantId {
    final value = _tenantId?.trim();
    return value != null && value.isNotEmpty;
  }

  bool get isEditable => _canWrite();

  static String? _resolveInitialTenantId({
    required String? tenantId,
    required UserPermissionData? permissions,
    required UserData? user,
  }) {
    final direct = tenantId?.trim();

    if (direct != null && direct.isNotEmpty) {
      return direct;
    }

    final permissionTenant = permissions?.activeTenantId?.trim();

    if (permissionTenant != null && permissionTenant.isNotEmpty) {
      return permissionTenant;
    }

    final userTenant = user?.effectiveTenantId?.trim();

    if (userTenant != null && userTenant.isNotEmpty) {
      return userTenant;
    }

    return null;
  }

  void _syncRepositoryTenant() {
    repository.setActiveTenantId(_tenantId);
  }

  String _requireTenantId() {
    final id = _tenantId?.trim();

    if (id == null || id.isEmpty) {
      throw Exception(
        'Nenhuma empresa ativa foi selecionada para acessar apostilamentos.',
      );
    }

    repository.setActiveTenantId(id);

    return id;
  }

  void _emitEmptyLoaded() {
    emit(
      state.copyWith(
        status: ApostillesStatus.loaded,
        apostilles: const <ApostillesData>[],
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
  }

  void updateUser(
      UserData? user, {
        UserPermissionData? permissions,
        String? tenantId,
        bool reload = true,
      }) {
    final previousTenantId = _tenantId;

    _currentUser = user ?? _currentUser;
    _currentPermissions =
        permissions ?? _permissionsFromUser(user) ?? _currentPermissions;

    final resolvedTenantId = _resolveInitialTenantId(
      tenantId: tenantId,
      permissions: _currentPermissions,
      user: _currentUser,
    );

    if (resolvedTenantId != null && resolvedTenantId.trim().isNotEmpty) {
      _tenantId = resolvedTenantId.trim();
    }

    _syncRepositoryTenant();

    emit(
      state.copyWith(
        isEditable: _canWrite(),
        clearError: true,
      ),
    );

    final contractId = contract.id?.trim();

    final shouldReload = reload &&
        contractId != null &&
        contractId.isNotEmpty &&
        _hasTenantId &&
        (previousTenantId != _tenantId ||
            state.status == ApostillesStatus.initial ||
            state.status == ApostillesStatus.error);

    if (shouldReload) {
      unawaited(loadApostilles());
    }
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
      user: _currentUser,
    );

    if (resolvedTenantId != null && resolvedTenantId.trim().isNotEmpty) {
      _tenantId = resolvedTenantId.trim();
    }

    _syncRepositoryTenant();

    emit(
      state.copyWith(
        isEditable: _canWrite(),
        clearError: true,
      ),
    );

    final contractId = contract.id?.trim();

    final shouldReload = contractId != null &&
        contractId.isNotEmpty &&
        _hasTenantId &&
        (previousTenantId != _tenantId ||
            state.status == ApostillesStatus.initial ||
            state.status == ApostillesStatus.error);

    if (shouldReload) {
      unawaited(loadApostilles());
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

  bool _canWrite() {
    final permissions = _currentPermissions;

    if (permissions == null) {
      return !enforcePermissions;
    }

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
        ) ||
        permissions.canModuleString(
          module: 'apostilles',
          action: 'create',
          tenantId: _tenantId,
        ) ||
        permissions.canModuleString(
          module: 'apostilles',
          action: 'edit',
          tenantId: _tenantId,
        ) ||
        permissions.canModuleString(
          module: 'apostilles',
          action: 'delete',
          tenantId: _tenantId,
        );
  }

  bool _canDelete() {
    final permissions = _currentPermissions;

    if (permissions == null) {
      return !enforcePermissions;
    }

    if (permissions.isGlobalSuperUser ||
        permissions.isSuperUserForTenant(_tenantId)) {
      return true;
    }

    return permissions.canModuleString(
      module: moduleId,
      action: 'delete',
      tenantId: _tenantId,
    ) ||
        permissions.canModuleString(
          module: 'apostilles',
          action: 'delete',
          tenantId: _tenantId,
        );
  }

  void _assertCanWrite() {
    _requireTenantId();

    if (_canWrite()) return;

    throw Exception(
      'Usuário sem permissão para alterar apostilamentos. '
          'Módulo: $moduleId | tenantId: ${_tenantId ?? 'não definido'}',
    );
  }

  void _assertCanDelete() {
    _requireTenantId();

    if (_canDelete()) return;

    throw Exception(
      'Usuário sem permissão para apagar apostilamentos. '
          'Módulo: $moduleId | tenantId: ${_tenantId ?? 'não definido'}',
    );
  }

  Future<void> loadApostilles() async {
    _syncRepositoryTenant();

    final cId = contract.id?.trim();

    if (!_hasTenantId) {
      emit(
        state.copyWith(
          status: ApostillesStatus.error,
          apostilles: const <ApostillesData>[],
          existingOrders: <int>{},
          nextAvailableOrder: 1,
          clearSelected: true,
          clearSelectedIndex: true,
          editingMode: false,
          sideAttachments: const <Attachment>[],
          sideLoading: false,
          clearUploadProgress: true,
          errorMessage: 'Nenhuma empresa ativa foi selecionada.',
          isEditable: _canWrite(),
        ),
      );
      return;
    }

    if (cId == null || cId.isEmpty) {
      _emitEmptyLoaded();
      return;
    }

    emit(
      state.copyWith(
        status: ApostillesStatus.loading,
        clearError: true,
        isEditable: _canWrite(),
      ),
    );

    try {
      final list = await repository.ensureForContract(cId);
      final orders = _extractExistingOrders(list);
      final next = _computeNextOrder(orders);

      emit(
        state.copyWith(
          status: ApostillesStatus.loaded,
          apostilles: list,
          existingOrders: orders,
          nextAvailableOrder: next,
          isEditable: _canWrite(),
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ApostillesStatus.error,
          errorMessage: 'Erro ao carregar apostilamentos: $e',
          isEditable: _canWrite(),
        ),
      );
    }
  }

  void selectApostilleByIndex(int index) {
    if (index < 0 || index >= state.apostilles.length) {
      _clearSelection();
      return;
    }

    if (state.selectedIndex == index) {
      _clearSelection();
      return;
    }

    final data = state.apostilles[index];
    _selectApostille(data, index);
  }

  void selectApostille(ApostillesData data) {
    final index = state.apostilles.indexWhere((item) => item.id == data.id);

    if (index == -1) {
      _clearSelection();
      return;
    }

    if (state.selected?.id == data.id) {
      _clearSelection();
      return;
    }

    _selectApostille(data, index);
  }

  void selectApostilleByOrder(int order) {
    if (order <= 0) {
      _clearSelection();
      return;
    }

    final index = state.apostilles.indexWhere(
          (item) => (item.apostilleOrder ?? 0) == order,
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
          nextAvailableOrder: order,
        ),
      );
      return;
    }

    final data = state.apostilles[index];

    if (state.selected?.id == data.id) {
      emit(
        state.copyWith(
          selectedIndex: index,
          editingMode: true,
          sideAttachments: data.attachments ?? const <Attachment>[],
          sideLoading: false,
          clearUploadProgress: true,
        ),
      );
      return;
    }

    _selectApostille(data, index);
  }

  void _selectApostille(ApostillesData data, int? index) {
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

  void createNewApostille({int? keepOrder}) {
    if (enforcePermissions) {
      _assertCanWrite();
    }

    final next = keepOrder ?? _computeNextOrder(state.existingOrders);

    emit(
      state.copyWith(
        editingMode: false,
        clearSelected: true,
        clearSelectedIndex: true,
        sideAttachments: const <Attachment>[],
        nextAvailableOrder: next,
        formValid: false,
        clearError: true,
        sideLoading: false,
        clearUploadProgress: true,
      ),
    );
  }

  void updateFormValidity({
    required String orderText,
    required String dateText,
    required String processText,
    required String valueText,
  }) {
    final order = int.tryParse(orderText.trim()) ?? 0;

    final valid = order > 0 &&
        dateText.trim().isNotEmpty &&
        processText.trim().isNotEmpty &&
        valueText.trim().isNotEmpty;

    if (valid != state.formValid) {
      emit(state.copyWith(formValid: valid));
    }
  }

  ApostillesData? _findByOrder(int order) {
    if (order <= 0) return null;

    try {
      return state.apostilles.firstWhere(
            (item) => (item.apostilleOrder ?? 0) == order,
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

  Future<ApostilleSaveResult> saveOrUpdate({
    required String orderText,
    required String dateText,
    required String valueText,
    required String processText,
  }) async {
    _assertCanWrite();

    final cId = contract.id?.trim();

    if (cId == null || cId.isEmpty) {
      throw Exception('Contrato não informado para salvar o apostilamento.');
    }

    emit(state.copyWith(isSaving: true, clearError: true));

    try {
      final order = int.tryParse(orderText.trim()) ?? 0;

      if (order <= 0) {
        throw Exception('Informe uma ordem válida para o apostilamento.');
      }

      final byOrder = _findByOrder(order);
      final resolvedId = state.selected?.id ?? byOrder?.id;

      final apostille = ApostillesData(
        id: resolvedId,
        contractId: cId,
        apostilleOrder: order,
        apostilleData: SipGedFormatDates.ddMMyyyyToDate(dateText),
        apostilleValue: SipGedFormatNumbers.toDouble(valueText),
        apostilleNumberProcess: processText.trim(),
        pdfUrl: state.selected?.pdfUrl ?? byOrder?.pdfUrl,
        attachments: state.selected?.attachments ?? byOrder?.attachments,
        createdAt: state.selected?.createdAt ?? byOrder?.createdAt,
        createdBy: state.selected?.createdBy ?? byOrder?.createdBy,
        updatedAt: DateTime.now(),
        updatedBy: _currentUser?.uid ?? _currentPermissions?.uid,
      );

      await repository.saveOrUpdateApostille(
        contractId: cId,
        data: apostille,
      );

      final created = resolvedId == null;

      await loadApostilles();

      selectApostilleByOrder(order);

      return ApostilleSaveResult(
        created: created,
        order: order,
        apostilleId: _resolveSelectedIdFallback(
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

  Future<ApostilleDeleteResult> deleteSelectedApostille() async {
    _assertCanDelete();

    final cId = contract.id?.trim();
    final selected = state.selected;

    if (cId == null || cId.isEmpty) {
      throw Exception('Contrato não informado para excluir o apostilamento.');
    }

    if (selected == null || selected.id == null || selected.id!.trim().isEmpty) {
      throw Exception('Nenhum apostilamento selecionado para exclusão.');
    }

    emit(state.copyWith(isSaving: true, clearError: true));

    try {
      final result = ApostilleDeleteResult(
        deleted: true,
        order: selected.apostilleOrder,
        apostilleId: selected.id,
        process: selected.apostilleNumberProcess,
        value: selected.apostilleValue,
        date: selected.apostilleData,
      );

      await repository.deleteApostille(
        contractId: cId,
        apostilleId: selected.id!,
      );

      await loadApostilles();

      emit(
        state.copyWith(
          clearSelected: true,
          clearSelectedIndex: true,
          editingMode: false,
          sideAttachments: const <Attachment>[],
          sideLoading: false,
          clearUploadProgress: true,
          nextAvailableOrder: _computeNextOrder(state.existingOrders),
        ),
      );

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
    _syncRepositoryTenant();

    final cId = contract.id?.trim();
    final selected = state.selected;

    if (selected == null || cId == null || cId.isEmpty || selected.id == null) {
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

      final files = await repository.listarArquivosDaApostila(
        contractId: cId,
        apostilleId: selected.id!,
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

      final list = files.map((file) {
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
          'tenants/$tenantId/contracts/$cId/apostilles/${selected.id}/${file.name}',
          ext: ext,
          createdAt: DateTime.now(),
          createdBy: _currentUser?.uid ?? _currentPermissions?.uid,
        );
      }).toList();

      await repository.setAttachments(
        contractId: cId,
        apostilleId: selected.id!,
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

  String _suggestLabelFromName(ApostillesData apostille, String original) {
    final base = original
        .split('/')
        .last
        .replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');

    final order = apostille.apostilleOrder ?? 0;

    return 'Apostilamento $order - $base';
  }

  Future<ApostilleAttachmentAddResult> addAttachmentWithPicker(
      BuildContext context,
      ) async {
    _assertCanWrite();

    final cId = contract.id?.trim();
    final apostille = state.selected;

    if (cId == null || cId.isEmpty) {
      throw Exception('Contrato não informado para anexar arquivo.');
    }

    if (apostille == null ||
        apostille.id == null ||
        apostille.id!.trim().isEmpty) {
      throw Exception(
        'Selecione ou salve um apostilamento antes de anexar arquivos.',
      );
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

      final label = _suggestLabelFromName(apostille, originalName);

      final attachment = await repository.uploadAttachmentBytes(
        contract: contract,
        apostille: apostille,
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
        apostille.attachments ?? const <Attachment>[],
      )..add(attachment);

      await repository.setAttachments(
        contractId: cId,
        apostilleId: apostille.id!,
        attachments: current,
      );

      final updatedSelected = apostille.copyWith(
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

      return ApostilleAttachmentAddResult(
        apostilleId: apostille.id,
        apostilleOrder: apostille.apostilleOrder,
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

  Future<ApostilleAttachmentRenameResult> renameAttachment({
    required int index,
    required String newLabel,
  }) async {
    _assertCanWrite();

    final cId = contract.id?.trim();
    final apostille = state.selected;

    if (cId == null || cId.isEmpty) {
      throw Exception('Contrato não informado para renomear anexo.');
    }

    if (apostille == null ||
        apostille.id == null ||
        apostille.id!.trim().isEmpty) {
      throw Exception('Nenhum apostilamento selecionado.');
    }

    final attachments = apostille.attachments ?? const <Attachment>[];

    if (attachments.isEmpty) {
      throw Exception('O apostilamento selecionado não possui anexos.');
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
        contractId: cId,
        apostilleId: apostille.id!,
        attachments: list,
      );

      emit(
        state.copyWith(
          selected: apostille.copyWith(attachments: list),
          sideAttachments: list,
          sideLoading: false,
          clearUploadProgress: true,
        ),
      );

      return ApostilleAttachmentRenameResult(
        apostilleId: apostille.id,
        apostilleOrder: apostille.apostilleOrder,
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

  Future<ApostilleAttachmentDeleteResult> deleteAttachment(int index) async {
    _assertCanWrite();

    final cId = contract.id?.trim();
    final apostille = state.selected;

    if (cId == null || cId.isEmpty) {
      throw Exception('Contrato não informado para remover anexo.');
    }

    if (apostille == null ||
        apostille.id == null ||
        apostille.id!.trim().isEmpty) {
      throw Exception('Nenhum apostilamento selecionado.');
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
        apostille.attachments ?? const <Attachment>[],
      );

      if (index < 0 || index >= attachments.length) {
        throw Exception('Índice de anexo inválido.');
      }

      final removed = attachments.removeAt(index);

      if (removed.path.trim().isNotEmpty) {
        await repository.deleteStorageByPath(removed.path);
      }

      await repository.setAttachments(
        contractId: cId,
        apostilleId: apostille.id!,
        attachments: attachments,
      );

      emit(
        state.copyWith(
          selected: apostille.copyWith(
            attachments: attachments,
            clearAttachments: attachments.isEmpty,
          ),
          sideAttachments: attachments,
          sideLoading: false,
          clearUploadProgress: true,
        ),
      );

      return ApostilleAttachmentDeleteResult(
        apostilleId: apostille.id,
        apostilleOrder: apostille.apostilleOrder,
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

  Set<int> _extractExistingOrders(List<ApostillesData> list) {
    return list
        .map((item) => item.apostilleOrder ?? 0)
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