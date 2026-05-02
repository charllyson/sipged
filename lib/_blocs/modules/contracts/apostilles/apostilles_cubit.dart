import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';
import 'package:sipged/_blocs/modules/contracts/apostilles/apostilles_data.dart';
import 'package:sipged/_blocs/modules/contracts/apostilles/apostilles_repository.dart';

import 'package:sipged/_blocs/system/module/module_permission.dart' as perms;
import 'package:sipged/_blocs/system/user/user_data.dart';
import 'package:sipged/_blocs/system/user/user_permission.dart' as roles;

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
  })  : _currentUser = initialUser,
        super(ApostillesState.initial()) {
    _init();

    if (initialUser != null) {
      updateUser(initialUser);
    }
  }

  final ProcessData contract;
  final ApostillesRepository repository;

  UserData? _currentUser;

  // =========================
  // Inicialização
  // =========================

  Future<void> _init() async {
    final cId = contract.id?.trim();

    if (cId == null || cId.isEmpty) {
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
        ),
      );
      return;
    }

    await loadApostilles();
  }

  // =========================
  // Permissões
  // =========================

  void updateUser(UserData? user) {
    _currentUser = user;
    final editable = _canEditUser(user);

    if (editable != state.isEditable) {
      emit(state.copyWith(isEditable: editable));
    }
  }

  bool _canEditUser(UserData? user) {
    if (user == null) return false;

    if (roles.roleForUser(user) == roles.UserProfile.administrador) {
      return true;
    }

    final canEdit = perms.userCanModule(
      user: user,
      module: 'apostilles',
      action: 'edit',
    );

    final canCreate = perms.userCanModule(
      user: user,
      module: 'apostilles',
      action: 'create',
    );

    return canEdit || canCreate;
  }

  // =========================
  // Carregamento
  // =========================

  Future<void> loadApostilles() async {
    final cId = contract.id?.trim();

    if (cId == null || cId.isEmpty) {
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
        ),
      );
      return;
    }

    emit(state.copyWith(status: ApostillesStatus.loading, clearError: true));

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
          sideAttachments: state.sideAttachments,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ApostillesStatus.error,
          errorMessage: 'Erro ao carregar apostilamentos: $e',
        ),
      );
    }
  }

  // =========================
  // Seleção
  // =========================

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
    final index = state.apostilles.indexWhere((e) => e.id == data.id);

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
          (e) => (e.apostilleOrder ?? 0) == order,
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

  // =========================
  // Validação
  // =========================

  void updateFormValidity({
    required String orderText,
    required String dateText,
    required String processText,
    required String valueText,
  }) {
    final ord = int.tryParse(orderText.trim()) ?? 0;

    final valid = ord > 0 &&
        dateText.trim().isNotEmpty &&
        processText.trim().isNotEmpty &&
        valueText.trim().isNotEmpty;

    if (valid != state.formValid) {
      emit(state.copyWith(formValid: valid));
    }
  }

  // =========================
  // Save / Update / Delete
  // =========================

  ApostillesData? _findByOrder(int order) {
    if (order <= 0) return null;

    try {
      return state.apostilles.firstWhere(
            (e) => (e.apostilleOrder ?? 0) == order,
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
    final cId = contract.id?.trim();

    if (cId == null || cId.isEmpty) {
      throw Exception('Contrato não informado para salvar o apostilamento.');
    }

    emit(state.copyWith(isSaving: true, clearError: true));

    try {
      final int ord = int.tryParse(orderText.trim()) ?? 0;

      final ApostillesData? byOrder = _findByOrder(ord);
      final String? resolvedId = state.selected?.id ?? byOrder?.id;

      final apostille = ApostillesData(
        id: resolvedId,
        contractId: cId,
        apostilleOrder: ord > 0 ? ord : null,
        apostilleData: SipGedFormatDates.ddMMyyyyToDate(dateText),
        apostilleValue: SipGedFormatNumbers.toDouble(valueText),
        apostilleNumberProcess: processText.trim(),
        pdfUrl: state.selected?.pdfUrl ?? byOrder?.pdfUrl,
        attachments: state.selected?.attachments ?? byOrder?.attachments,
      );

      await repository.saveOrUpdateApostille(
        contractId: cId,
        data: apostille,
      );

      final bool created = resolvedId == null;

      await loadApostilles();

      if (ord > 0) {
        selectApostilleByOrder(ord);
      } else {
        createNewApostille();
      }

      return ApostilleSaveResult(
        created: created,
        order: ord > 0 ? ord : null,
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
      createNewApostille();

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

  // =========================
  // Attachments
  // =========================

  Future<void> reloadAttachments() async {
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

      if ((selected.pdfUrl ?? '').isNotEmpty) {
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

      final List<Attachment> list = files.map((f) {
        final ext = RegExp(r'\.([a-z0-9]+)$', caseSensitive: false)
            .firstMatch(f.name)
            ?.group(0) ??
            '';

        return Attachment(
          id: f.name,
          label: f.name.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), ''),
          url: f.url,
          path: 'contracts/$cId/apostilles/${selected.id}/${f.name}',
          ext: ext,
          createdAt: DateTime.now(),
          createdBy: _currentUser?.uid,
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
    } catch (_) {
      emit(state.copyWith(sideLoading: false, clearUploadProgress: true));
      rethrow;
    }
  }

  String _suggestLabelFromName(ApostillesData apostille, String original) {
    final base = original
        .split('/')
        .last
        .replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');

    final ord = apostille.apostilleOrder ?? 0;

    return 'Apostilamento $ord - $base';
  }

  Future<ApostilleAttachmentAddResult> addAttachmentWithPicker(
      BuildContext context,
      ) async {
    final cId = contract.id?.trim();
    final a = state.selected;

    if (cId == null || cId.isEmpty) {
      throw Exception('Contrato não informado para anexar arquivo.');
    }

    if (a == null || a.id == null || a.id!.trim().isEmpty) {
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

      final label = _suggestLabelFromName(a, originalName);

      final att = await repository.uploadAttachmentBytes(
        contract: contract,
        apostille: a,
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
        apostilleId: a.id!,
        attachments: current,
      );

      final updatedSelected = a.copyWith(attachments: current);

      emit(
        state.copyWith(
          selected: updatedSelected,
          sideAttachments: current,
          sideLoading: false,
          clearUploadProgress: true,
        ),
      );

      return ApostilleAttachmentAddResult(
        apostilleId: a.id,
        apostilleOrder: a.apostilleOrder,
        attachment: att,
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
    final cId = contract.id?.trim();
    final a = state.selected;

    if (cId == null || cId.isEmpty) {
      throw Exception('Contrato não informado para renomear anexo.');
    }

    if (a == null || a.id == null || a.id!.trim().isEmpty) {
      throw Exception('Nenhum apostilamento selecionado.');
    }

    if (a.attachments == null) {
      throw Exception('O apostilamento selecionado não possui anexos.');
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
        contractId: cId,
        apostilleId: a.id!,
        attachments: list,
      );

      emit(
        state.copyWith(
          selected: a.copyWith(attachments: list),
          sideAttachments: list,
          sideLoading: false,
          clearUploadProgress: true,
        ),
      );

      return ApostilleAttachmentRenameResult(
        apostilleId: a.id,
        apostilleOrder: a.apostilleOrder,
        oldAttachment: oldAtt,
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
    final cId = contract.id?.trim();
    final a = state.selected;

    if (cId == null || cId.isEmpty) {
      throw Exception('Contrato não informado para remover anexo.');
    }

    if (a == null || a.id == null || a.id!.trim().isEmpty) {
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
        contractId: cId,
        apostilleId: a.id!,
        attachments: atts,
      );

      emit(
        state.copyWith(
          selected: a.copyWith(attachments: atts),
          sideAttachments: atts,
          sideLoading: false,
          clearUploadProgress: true,
        ),
      );

      return ApostilleAttachmentDeleteResult(
        apostilleId: a.id,
        apostilleOrder: a.apostilleOrder,
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

  // =========================
  // Helpers de ordem
  // =========================

  Set<int> _extractExistingOrders(List<ApostillesData> list) {
    return list
        .map((e) => e.apostilleOrder ?? 0)
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