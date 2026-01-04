import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:siged/_blocs/_process/process_data.dart';
import 'package:siged/_blocs/process/apostilles/apostilles_data.dart';
import 'package:siged/_blocs/process/apostilles/apostilles_repository.dart';

// usuário/permissões
import 'package:siged/_blocs/system/user/user_data.dart';
import 'package:siged/_blocs/system/permitions/user_permission.dart' as roles;
import 'package:siged/_blocs/system/permitions/page_permission.dart' as perms;

import 'package:siged/_widgets/list/files/attachment.dart';

// notificações locais
import 'package:siged/_widgets/notification/app_notification.dart';
import 'package:siged/_widgets/notification/notification_center.dart';

// utils
import 'package:siged/_utils/formats/converters_utils.dart';
import 'package:siged/_utils/formats/format_field.dart';

import 'apostilles_state.dart';

class ApostillesCubit extends Cubit<ApostillesState> {
  ApostillesCubit({
    required this.contract,
    required this.repository,
    UserData? initialUser,
  })  : _currentUser = initialUser,
        super(ApostillesState.initial()) {
    // ignore: avoid_print
    print('>>> ApostillesCubit criado para contrato: ${contract.id}');
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
    if (contract.id == null || contract.id!.isEmpty) {
      emit(
        state.copyWith(
          status: ApostillesStatus.loaded,
          apostilles: const <ApostillesData>[],
          existingOrders: <int>{},
          nextAvailableOrder: 1,
          clearSelected: true,
          clearSelectedIndex: true,
          editingMode: false,
          sideAttachments: <Attachment>[],
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
    emit(state.copyWith(isEditable: editable));
  }

  bool _canEditUser(UserData? user) {
    if (user == null) return false;
    if (roles.roleForUser(user) == roles.BaseRole.ADMINISTRADOR) return true;

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
    if (contract.id == null || contract.id!.isEmpty) {
      emit(
        state.copyWith(
          status: ApostillesStatus.loaded,
          apostilles: const <ApostillesData>[],
          existingOrders: <int>{},
          nextAvailableOrder: 1,
          clearSelected: true,
          clearSelectedIndex: true,
          editingMode: false,
          sideAttachments: <Attachment>[],
        ),
      );
      return;
    }

    emit(state.copyWith(status: ApostillesStatus.loading));

    try {
      final list = await repository.ensureForContract(contract.id!);
      final orders = _extractExistingOrders(list);
      final next = _computeNextOrder(orders);

      emit(
        state.copyWith(
          status: ApostillesStatus.loaded,
          apostilles: list,
          existingOrders: orders,
          nextAvailableOrder: next,
          clearSelected: false,
          clearSelectedIndex: false,
          sideAttachments: state.sideAttachments,
        ),
      );
    } catch (e, st) {
      // ignore: avoid_print
      print('>>> ERRO em loadApostilles: $e\n$st');
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

  /// ✅ NOVO: seleção pelo dropdown (ordem)
  /// - Se existir, seleciona (form + gráfico + tabela)
  /// - Se não existir, limpa seleção e deixa como "novo"
  void selectApostilleByOrder(int order) {
    if (order <= 0) {
      _clearSelection();
      return;
    }

    final index =
    state.apostilles.indexWhere((e) => (e.apostilleOrder ?? 0) == order);

    if (index == -1) {
      // não existe ainda -> modo novo
      emit(
        state.copyWith(
          clearSelected: true,
          clearSelectedIndex: true,
          editingMode: false,
          sideAttachments: <Attachment>[],
        ),
      );
      return;
    }

    final data = state.apostilles[index];

    // se já está selecionado, mantém selecionado (não toggle aqui)
    if (state.selected?.id == data.id) {
      emit(
        state.copyWith(
          selectedIndex: index,
          editingMode: true,
          sideAttachments: (data.attachments ?? const <Attachment>[]),
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
      ),
    );
  }

  void createNewApostille() {
    final next = _computeNextOrder(state.existingOrders);
    emit(
      state.copyWith(
        editingMode: false,
        clearSelected: true,
        clearSelectedIndex: true,
        sideAttachments: <Attachment>[],
        nextAvailableOrder: next,
        formValid: false,
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
      return state.apostilles
          .firstWhere((e) => (e.apostilleOrder ?? 0) == order);
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
    if (contract.id == null) return;

    emit(state.copyWith(isSaving: true, clearError: true));

    try {
      final int ord = int.tryParse(orderText.trim()) ?? 0;

      // ✅ Proteção: se não há selected mas a ordem já existe, atualiza aquele item
      final ApostillesData? byOrder = _findByOrder(ord);

      final String? resolvedId = state.selected?.id ?? byOrder?.id;

      final apostille = ApostillesData(
        id: resolvedId,
        apostilleOrder: ord > 0 ? ord : null,
        apostilleData: convertDDMMYYYYToDateTime(dateText),
        apostilleValue: stringToDouble(valueText),
        apostilleNumberProcess: processText,
        pdfUrl: state.selected?.pdfUrl ?? byOrder?.pdfUrl,
        attachments: state.selected?.attachments ?? byOrder?.attachments,
      );

      await repository.saveOrUpdateApostille(
        contractId: contract.id!,
        data: apostille,
      );

      final bool didUpdate = resolvedId != null;

      NotificationCenter.instance.show(
        AppNotification(
          title: Text(didUpdate ? 'Apostilamento atualizado' : 'Apostilamento salvo'),
          type: AppNotificationType.success,
          details: Text(
            '${_userName()} • ${_stamp()}',
            style: const TextStyle(fontSize: 11),
          ),
        ),
      );

      await loadApostilles();

      // ✅ Após salvar, volta a selecionar o mesmo order (mantém gráfico/tabela sincronizados)
      selectApostilleByOrder(ord);

      // opcional: se você quiser voltar para "novo", substitua a linha acima por:
      // createNewApostille();

    } catch (e, st) {
      // ignore: avoid_print
      print('>>> ERRO em saveOrUpdate Apostille: $e\n$st');
      NotificationCenter.instance.show(
        AppNotification(
          title: Text('Erro ao salvar: $e'),
          type: AppNotificationType.error,
          details: Text(
            '${_userName()} • ${_stamp()}',
            style: const TextStyle(fontSize: 11),
          ),
        ),
      );
      emit(
        state.copyWith(
          isSaving: false,
          errorMessage: 'Erro ao salvar: $e',
        ),
      );
      return;
    } finally {
      emit(state.copyWith(isSaving: false));
    }
  }

  Future<void> deleteSelectedApostille() async {
    final selected = state.selected;
    if (contract.id == null || selected?.id == null) return;

    emit(state.copyWith(isSaving: true, clearError: true));

    try {
      await repository.deleteApostille(
        contractId: contract.id!,
        apostilleId: selected!.id!,
      );

      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Apostilamento deletado'),
          type: AppNotificationType.success,
          details: Text(
            '${_userName()} • ${_stamp()}',
            style: const TextStyle(fontSize: 11),
          ),
        ),
      );

      await loadApostilles();
      createNewApostille();
    } catch (e, st) {
      // ignore: avoid_print
      print('>>> ERRO em deleteSelectedApostille: $e\n$st');
      NotificationCenter.instance.show(
        AppNotification(
          title: Text('Erro ao deletar: $e'),
          type: AppNotificationType.error,
          details: Text(
            '${_userName()} • ${_stamp()}',
            style: const TextStyle(fontSize: 11),
          ),
        ),
      );
      emit(
        state.copyWith(
          isSaving: false,
          errorMessage: 'Erro ao deletar: $e',
        ),
      );
      return;
    } finally {
      emit(state.copyWith(isSaving: false));
    }
  }

  // =========================
  // Attachments (SideList)
  // =========================

  Future<void> reloadAttachments() async {
    final selected = state.selected;
    if (selected == null || contract.id == null || selected.id == null) {
      emit(state.copyWith(sideAttachments: <Attachment>[]));
      return;
    }

    if ((selected.attachments ?? const <Attachment>[]).isNotEmpty) {
      emit(state.copyWith(sideAttachments: selected.attachments!));
      return;
    }

    // pdfUrl legado: deixa vazio; a UI pode tratar separadamente
    if ((selected.pdfUrl ?? '').isNotEmpty) {
      emit(state.copyWith(sideAttachments: <Attachment>[]));
      return;
    }

    final files = await repository.listarArquivosDaApostila(
      contractId: contract.id!,
      apostilleId: selected.id!,
    );

    if (files.isEmpty) {
      emit(state.copyWith(sideAttachments: <Attachment>[]));
      return;
    }

    final List<Attachment> list = files
        .map(
          (f) => Attachment(
        id: f.name,
        label: f.name.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), ''),
        url: f.url,
        path: 'contracts/${contract.id}/apostilles/${selected.id}/${f.name}',
        ext: RegExp(r'\.([a-z0-9]+)$', caseSensitive: false)
            .firstMatch(f.name)
            ?.group(0) ??
            '',
        createdAt: DateTime.now(),
        createdBy: _currentUser?.uid,
      ),
    )
        .toList();

    await repository.setAttachments(
      contractId: contract.id!,
      apostilleId: selected.id!,
      attachments: list,
    );

    final updatedSelected = ApostillesData(
      id: selected.id,
      contractId: selected.contractId,
      apostilleNumberProcess: selected.apostilleNumberProcess,
      apostilleOrder: selected.apostilleOrder,
      apostilleData: selected.apostilleData,
      apostilleValue: selected.apostilleValue,
      pdfUrl: null,
      attachments: list,
      createdAt: selected.createdAt,
      createdBy: selected.createdBy,
      updatedAt: selected.updatedAt,
      updatedBy: selected.updatedBy,
      deletedAt: selected.deletedAt,
      deletedBy: selected.deletedBy,
    );

    emit(
      state.copyWith(
        selected: updatedSelected,
        sideAttachments: list,
      ),
    );
  }

  String _suggestLabelFromName(ApostillesData apostille, String original) {
    final base =
    original.split('/').last.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');
    final ord = apostille.apostilleOrder ?? 0;
    return 'Apostilamento $ord - $base';
  }

  Future<void> addAttachmentWithPicker(BuildContext context) async {
    final cId = contract.id;
    final a = state.selected;
    if (cId == null || a == null || a.id == null) return;
    if (!state.canAddFile) return;

    emit(state.copyWith(isSaving: true, clearError: true));

    try {
      final (Uint8List bytes, String originalName) =
      await repository.pickFileBytes();

      final suggestion = _suggestLabelFromName(a, originalName);
      final label = suggestion;

      final att = await repository.uploadAttachmentBytes(
        contract: contract,
        apostille: a,
        bytes: bytes,
        originalName: originalName,
        label: label,
      );

      final current =
      List<Attachment>.from(a.attachments ?? const <Attachment>[])..add(att);

      await repository.setAttachments(
        contractId: cId,
        apostilleId: a.id!,
        attachments: current,
      );

      final updatedSelected = ApostillesData(
        id: a.id,
        contractId: a.contractId,
        apostilleNumberProcess: a.apostilleNumberProcess,
        apostilleOrder: a.apostilleOrder,
        apostilleData: a.apostilleData,
        apostilleValue: a.apostilleValue,
        pdfUrl: a.pdfUrl,
        attachments: current,
        createdAt: a.createdAt,
        createdBy: a.createdBy,
        updatedAt: a.updatedAt,
        updatedBy: a.updatedBy,
        deletedAt: a.deletedAt,
        deletedBy: a.deletedBy,
      );

      emit(
        state.copyWith(
          selected: updatedSelected,
          sideAttachments: current,
        ),
      );

      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Anexo adicionado'),
          subtitle: Text(att.label),
          type: AppNotificationType.success,
          details: Text(
            '${_userName()} • ${_stamp()}',
            style: const TextStyle(fontSize: 11),
          ),
        ),
      );
    } catch (e, st) {
      // ignore: avoid_print
      print('>>> ERRO em addAttachmentWithPicker Apostille: $e\n$st');
      NotificationCenter.instance.show(
        AppNotification(
          title: Text('Erro ao anexar: $e'),
          type: AppNotificationType.error,
          details: Text(
            '${_userName()} • ${_stamp()}',
            style: const TextStyle(fontSize: 11),
          ),
        ),
      );
      emit(
        state.copyWith(
          isSaving: false,
          errorMessage: 'Erro ao anexar: $e',
        ),
      );
      return;
    } finally {
      emit(state.copyWith(isSaving: false));
    }
  }

  Future<void> renameAttachment({
    required int index,
    required String newLabel,
  }) async {
    final a = state.selected;
    if (a == null || a.attachments == null) return;
    if (index < 0 || index >= a.attachments!.length) return;

    emit(state.copyWith(isSaving: true, clearError: true));

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

      await repository.setAttachments(
        contractId: contract.id!,
        apostilleId: a.id!,
        attachments: list,
      );

      final updatedSelected = ApostillesData(
        id: a.id,
        contractId: a.contractId,
        apostilleNumberProcess: a.apostilleNumberProcess,
        apostilleOrder: a.apostilleOrder,
        apostilleData: a.apostilleData,
        apostilleValue: a.apostilleValue,
        pdfUrl: a.pdfUrl,
        attachments: list,
        createdAt: a.createdAt,
        createdBy: a.createdBy,
        updatedAt: a.updatedAt,
        updatedBy: a.updatedBy,
        deletedAt: a.deletedAt,
        deletedBy: a.deletedBy,
      );

      emit(
        state.copyWith(
          selected: updatedSelected,
          sideAttachments: list,
        ),
      );

      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Nome do anexo atualizado'),
          type: AppNotificationType.success,
          details: Text(
            '${_userName()} • ${_stamp()}',
            style: const TextStyle(fontSize: 11),
          ),
        ),
      );
    } catch (e, st) {
      // ignore: avoid_print
      print('>>> ERRO em renameAttachment Apostille: $e\n$st');
      NotificationCenter.instance.show(
        AppNotification(
          title: Text('Erro ao renomear: $e'),
          type: AppNotificationType.error,
          details: Text(
            '${_userName()} • ${_stamp()}',
            style: const TextStyle(fontSize: 11),
          ),
        ),
      );
      emit(
        state.copyWith(
          isSaving: false,
          errorMessage: 'Erro ao renomear: $e',
        ),
      );
      return;
    } finally {
      emit(state.copyWith(isSaving: false));
    }
  }

  Future<void> deleteAttachment(int index) async {
    final a = state.selected;
    if (a == null || a.id == null || contract.id == null) return;

    emit(state.copyWith(isSaving: true, clearError: true));

    try {
      final atts = List<Attachment>.from(a.attachments ?? const <Attachment>[]);

      if (index >= 0 && index < atts.length) {
        final removed = atts.removeAt(index);
        if (removed.path.isNotEmpty) {
          await repository.deleteStorageByPath(removed.path);
        }
        await repository.setAttachments(
          contractId: contract.id!,
          apostilleId: a.id!,
          attachments: atts,
        );
      }

      final updatedSelected = ApostillesData(
        id: a.id,
        contractId: a.contractId,
        apostilleNumberProcess: a.apostilleNumberProcess,
        apostilleOrder: a.apostilleOrder,
        apostilleData: a.apostilleData,
        apostilleValue: a.apostilleValue,
        pdfUrl: a.pdfUrl,
        attachments: atts,
        createdAt: a.createdAt,
        createdBy: a.createdBy,
        updatedAt: a.updatedAt,
        updatedBy: a.updatedBy,
        deletedAt: a.deletedAt,
        deletedBy: a.deletedBy,
      );

      emit(
        state.copyWith(
          selected: updatedSelected,
          sideAttachments: atts,
        ),
      );

      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Anexo removido'),
          type: AppNotificationType.success,
          details: Text(
            '${_userName()} • ${_stamp()}',
            style: const TextStyle(fontSize: 11),
          ),
        ),
      );
    } catch (e, st) {
      // ignore: avoid_print
      print('>>> ERRO em deleteAttachment Apostille: $e\n$st');
      NotificationCenter.instance.show(
        AppNotification(
          title: Text('Erro ao remover: $e'),
          type: AppNotificationType.error,
          details: Text(
            '${_userName()} • ${_stamp()}',
            style: const TextStyle(fontSize: 11),
          ),
        ),
      );
      emit(
        state.copyWith(
          isSaving: false,
          errorMessage: 'Erro ao remover: $e',
        ),
      );
      return;
    } finally {
      emit(state.copyWith(isSaving: false));
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
