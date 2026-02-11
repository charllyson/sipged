import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:siged/_blocs/modules/contracts/_process/process_data.dart';
import 'package:siged/_blocs/modules/contracts/apostilles/apostilles_data.dart';
import 'package:siged/_blocs/modules/contracts/apostilles/apostilles_repository.dart';

import 'package:siged/_blocs/system/user/user_data.dart';
import 'package:siged/_blocs/system/permitions/user_permission.dart' as roles;
import 'package:siged/_blocs/system/permitions/module_permission.dart' as perms;

import 'package:siged/_utils/formats/sipged_format_dates.dart';
import 'package:siged/_utils/formats/sipged_format_numbers.dart';

import 'package:siged/_widgets/list/files/attachment.dart';
import 'package:siged/_widgets/notification/app_notification.dart';
import 'package:siged/_widgets/notification/notification_center.dart';

import 'apostilles_state.dart';

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

  String _userName() {
    final u = _currentUser;
    return (u?.name ?? u?.email ?? 'Usuário').trim();
  }

  String _stamp([DateTime? dt]) {
    final d = dt ?? DateTime.now();
    return DateFormat('dd/MM/yyyy HH:mm').format(d);
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

    if (roles.roleForUser(user) == roles.UserProfile.ADMINISTRADOR) {
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
          // SideListBox permanece como está; reloadAttachments controla o resto
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
  // Seleção (toggle)
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

    final index = state.apostilles.indexWhere((e) => (e.apostilleOrder ?? 0) == order);

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
          sideAttachments: (data.attachments ?? const <Attachment>[]),
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
        sideAttachments: (data.attachments ?? const <Attachment>[]),
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
  // Form validation
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
  // Save/Update/Delete
  // =========================

  ApostillesData? _findByOrder(int order) {
    if (order <= 0) return null;
    try {
      return state.apostilles.firstWhere((e) => (e.apostilleOrder ?? 0) == order);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveOrUpdate({
    required String orderText,
    required String dateText,
    required String valueText,
    required String processText,
  }) async {
    final cId = contract.id?.trim();
    if (cId == null || cId.isEmpty) return;

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

      await repository.saveOrUpdateApostille(contractId: cId, data: apostille);

      final bool didUpdate = resolvedId != null;

      NotificationCenter.instance.show(
        AppNotification(
          title: Text(didUpdate ? 'Apostilamento atualizado' : 'Apostilamento salvo'),
          type: AppNotificationType.success,
          details: Text('${_userName()} • ${_stamp()}', style: const TextStyle(fontSize: 11)),
        ),
      );

      await loadApostilles();

      if (ord > 0) {
        selectApostilleByOrder(ord);
      } else {
        createNewApostille();
      }
    } catch (e) {
      NotificationCenter.instance.show(
        AppNotification(
          title: Text('Erro ao salvar: $e'),
          type: AppNotificationType.error,
          details: Text('${_userName()} • ${_stamp()}', style: const TextStyle(fontSize: 11)),
        ),
      );
      emit(state.copyWith(isSaving: false, errorMessage: 'Erro ao salvar: $e'));
      return;
    } finally {
      emit(state.copyWith(isSaving: false));
    }
  }

  Future<void> deleteSelectedApostille() async {
    final cId = contract.id?.trim();
    final selected = state.selected;
    if (cId == null || cId.isEmpty || selected?.id == null) return;

    emit(state.copyWith(isSaving: true, clearError: true));

    try {
      await repository.deleteApostille(contractId: cId, apostilleId: selected!.id!);

      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Apostilamento deletado'),
          type: AppNotificationType.success,
          details: Text('${_userName()} • ${_stamp()}', style: const TextStyle(fontSize: 11)),
        ),
      );

      await loadApostilles();
      createNewApostille();
    } catch (e) {
      NotificationCenter.instance.show(
        AppNotification(
          title: Text('Erro ao deletar: $e'),
          type: AppNotificationType.error,
          details: Text('${_userName()} • ${_stamp()}', style: const TextStyle(fontSize: 11)),
        ),
      );
      emit(state.copyWith(isSaving: false, errorMessage: 'Erro ao deletar: $e'));
      return;
    } finally {
      emit(state.copyWith(isSaving: false));
    }
  }

  // =========================
  // Attachments (SideList) - PADRÃO ADITIVOS
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

    emit(state.copyWith(sideLoading: true, clearUploadProgress: true, clearError: true));

    try {
      // 1) se já tem attachments no doc, usa isso
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

      // 2) se tem pdfUrl legado, não lista anexos
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

      // 3) lista storage e grava attachments no doc
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

      final updatedSelected = selected.copyWith(pdfUrl: null, attachments: list);

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
    final base = original.split('/').last.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');
    final ord = apostille.apostilleOrder ?? 0;
    return 'Apostilamento $ord - $base';
  }

  Future<void> addAttachmentWithPicker(BuildContext context) async {
    final cId = contract.id?.trim();
    final a = state.selected;

    if (cId == null || cId.isEmpty || a == null || a.id == null) return;
    if (!state.canAddFile) return;

    emit(
      state.copyWith(
        sideLoading: true,
        uploadProgress: 0.0,
        clearError: true,
      ),
    );

    try {
      final (Uint8List bytes, String originalName) = await repository.pickFileBytes();

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

      final current = List<Attachment>.from(a.attachments ?? const <Attachment>[])..add(att);

      await repository.setAttachments(contractId: cId, apostilleId: a.id!, attachments: current);

      final updatedSelected = a.copyWith(attachments: current);

      emit(
        state.copyWith(
          selected: updatedSelected,
          sideAttachments: current,
          sideLoading: false,
          clearUploadProgress: true,
        ),
      );

      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Anexo adicionado'),
          subtitle: Text(att.label),
          type: AppNotificationType.success,
          details: Text('${_userName()} • ${_stamp()}', style: const TextStyle(fontSize: 11)),
        ),
      );
    } catch (e) {
      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Erro ao anexar'),
          type: AppNotificationType.error,
          details: Text('${_userName()} • ${_stamp()}', style: const TextStyle(fontSize: 11)),
        ),
      );

      emit(
        state.copyWith(
          sideLoading: false,
          clearUploadProgress: true,
          errorMessage: 'Erro ao anexar: $e',
        ),
      );
    }
  }

  Future<void> renameAttachment({
    required int index,
    required String newLabel,
  }) async {
    final cId = contract.id?.trim();
    final a = state.selected;

    if (cId == null || cId.isEmpty || a == null || a.attachments == null) return;
    if (a.id == null) return;
    if (index < 0 || index >= a.attachments!.length) return;

    emit(state.copyWith(sideLoading: true, clearUploadProgress: true, clearError: true));

    try {
      final att = a.attachments![index];

      final updated = Attachment(
        id: att.id,
        label: newLabel.isEmpty ? att.label : newLabel,
        url: att.url,
        path: att.path,
        ext: att.ext,
        size: att.size,
        createdAt: att.createdAt,
        createdBy: att.createdBy,
        updatedAt: DateTime.now(),
        updatedBy: _currentUser?.uid,
      );

      final list = List<Attachment>.from(a.attachments!)..[index] = updated;

      await repository.setAttachments(contractId: cId, apostilleId: a.id!, attachments: list);

      emit(
        state.copyWith(
          selected: a.copyWith(attachments: list),
          sideAttachments: list,
          sideLoading: false,
          clearUploadProgress: true,
        ),
      );

      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Nome do anexo atualizado'),
          type: AppNotificationType.success,
          details: Text('${_userName()} • ${_stamp()}', style: const TextStyle(fontSize: 11)),
        ),
      );
    } catch (e) {
      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Erro ao renomear'),
          type: AppNotificationType.error,
          details: Text('${_userName()} • ${_stamp()}', style: const TextStyle(fontSize: 11)),
        ),
      );

      emit(
        state.copyWith(
          sideLoading: false,
          clearUploadProgress: true,
          errorMessage: 'Erro ao renomear: $e',
        ),
      );
    }
  }

  Future<void> deleteAttachment(int index) async {
    final cId = contract.id?.trim();
    final a = state.selected;

    if (cId == null || cId.isEmpty || a == null || a.id == null) return;

    emit(state.copyWith(sideLoading: true, clearUploadProgress: true, clearError: true));

    try {
      final atts = List<Attachment>.from(a.attachments ?? const <Attachment>[]);

      if (index >= 0 && index < atts.length) {
        final removed = atts.removeAt(index);
        if (removed.path.isNotEmpty) {
          await repository.deleteStorageByPath(removed.path);
        }
        await repository.setAttachments(contractId: cId, apostilleId: a.id!, attachments: atts);
      }

      emit(
        state.copyWith(
          selected: a.copyWith(attachments: atts),
          sideAttachments: atts,
          sideLoading: false,
          clearUploadProgress: true,
        ),
      );

      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Anexo removido'),
          type: AppNotificationType.success,
          details: Text('${_userName()} • ${_stamp()}', style: const TextStyle(fontSize: 11)),
        ),
      );
    } catch (e) {
      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Erro ao remover'),
          type: AppNotificationType.error,
          details: Text('${_userName()} • ${_stamp()}', style: const TextStyle(fontSize: 11)),
        ),
      );

      emit(
        state.copyWith(
          sideLoading: false,
          clearUploadProgress: true,
          errorMessage: 'Erro ao remover: $e',
        ),
      );
    }
  }

  // =========================
  // Helpers de ordem
  // =========================

  Set<int> _extractExistingOrders(List<ApostillesData> list) {
    return list.map((e) => e.apostilleOrder ?? 0).where((e) => e > 0).toSet();
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
