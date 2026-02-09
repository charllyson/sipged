// lib/_blocs/modules/contracts/additives/additives_cubit.dart
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:siged/_blocs/modules/contracts/_process/process_data.dart';
import 'package:siged/_blocs/modules/contracts/additives/additives_data.dart';
import 'package:siged/_blocs/modules/contracts/additives/additives_repository.dart';

// usuário/permissões
import 'package:siged/_blocs/system/user/user_data.dart';
import 'package:siged/_blocs/system/permitions/user_permission.dart' as roles;
import 'package:siged/_blocs/system/permitions/module_permission.dart' as perms;
import 'package:siged/_widgets/list/files/attachment.dart';

// notificações locais
import 'package:siged/_widgets/notification/app_notification.dart';
import 'package:siged/_widgets/notification/notification_center.dart';

// utils
import 'package:siged/_utils/converters/converters_utils.dart';
import 'package:siged/_utils/formats/format_field.dart';

import 'additives_state.dart';

class AdditivesCubit extends Cubit<AdditivesState> {
  AdditivesCubit({
    required this.contract,
    required this.repository,
    UserData? initialUser,
  })  : _currentUser = initialUser,
        super(AdditivesState.initial()) {
    _init();
    if (initialUser != null) {
      updateUser(initialUser);
    }
  }

  final ProcessData contract;
  final AdditivesRepository repository;

  UserData? _currentUser;

  // =========================
  // Inicialização
  // =========================

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
        ),
      );
      return;
    }
    await loadAdditives();
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
    if (roles.roleForUser(user) == roles.UserProfile.ADMINISTRADOR) {
      return true;
    }
    final canEdit = perms.userCanModule(
      user: user,
      module: 'additives',
      action: 'edit',
    );
    final canCreate = perms.userCanModule(
      user: user,
      module: 'additives',
      action: 'create',
    );
    return canEdit || canCreate;
  }

  // =========================
  // Carregamento / seleção
  // =========================

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
          // não força seleção aqui; a Page decide
          sideAttachments: state.sideAttachments,
        ),
      );
    } catch (e, st) {
      emit(
        state.copyWith(
          status: AdditivesStatus.error,
          errorMessage: 'Erro ao carregar aditivos: $e',
        ),
      );
    }
  }

  /// Seleção por índice (tabela, gráfico).
  /// Se clicar novamente no mesmo índice, faz toggle (desseleciona tudo).
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

  /// Seleção por objeto (tabela).
  /// Se clicar novamente no mesmo item, toggle.
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

  /// ✅ NOVO: seleção pelo dropdown (ordem)
  /// - Se existir, seleciona e sincroniza (form + gráfico + tabela + anexos)
  /// - Se não existir, fica "novo" (limpa seleção)
  void selectAdditiveByOrder(int order) {
    if (order <= 0) {
      _clearSelection();
      return;
    }

    final index =
    state.additives.indexWhere((e) => (e.additiveOrder ?? 0) == order);

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

    final data = state.additives[index];

    // se já está selecionado, apenas garante selectedIndex e anexos
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

    _selectAdditive(data, index);
  }

  void _selectAdditive(AdditivesData data, int? index) {
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
      ),
    );
  }

  // =========================
  // Regras exibição campos
  // =========================

  static bool exibeValor(String typeText) =>
      const ['VALOR', 'REEQUÍLIBRIO', 'RATIFICAÇÃO', 'RENOVAÇÃO']
          .contains(typeText.toUpperCase());

  static bool exibePrazo(String typeText) =>
      const ['PRAZO', 'RATIFICAÇÃO', 'RENOVAÇÃO']
          .contains(typeText.toUpperCase());

  void updateFormValidity({
    required String typeText,
    required String dateText,
    required String processText,
    required String valueText,
    required String addExecText,
    required String addContractText,
  }) {
    final tipo = typeText.toUpperCase();
    final obrig = <String>[
      dateText,
      processText,
      typeText,
    ];

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

  // =========================
  // Salvamento / atualização
  // =========================

  String _onlyDigits(String s) => s.replaceAll(RegExp(r'[^\d]'), '');

  AdditivesData? _findByOrder(int order) {
    if (order <= 0) return null;
    try {
      return state.additives.firstWhere((e) => (e.additiveOrder ?? 0) == order);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveOrUpdate({
    required String orderText,
    required String dateText,
    required String valueText,
    required String addDaysExecText,
    required String addDaysContractText,
    required String processText,
    required String typeText,
  }) async {
    if (contract.id == null) return;
    emit(state.copyWith(isSaving: true, clearError: true));

    try {
      final int ord = int.tryParse(orderText.trim()) ?? 0;

      // ✅ Proteção: se não há selected mas a ordem já existe, atualiza aquele item
      final AdditivesData? byOrder = _findByOrder(ord);
      final String? resolvedId = state.selected?.id ?? byOrder?.id;

      final additive = AdditivesData(
        id: resolvedId,
        additiveNumberProcess: processText,
        additiveOrder: ord > 0 ? ord : null,
        additiveDate: convertDDMMYYYYToDateTime(dateText),
        additiveValue: stringToDouble(valueText),
        additiveValidityContractDays:
        int.tryParse(_onlyDigits(addDaysContractText)),
        additiveValidityExecutionDays: int.tryParse(_onlyDigits(addDaysExecText)),
        typeOfAdditive: typeText,
        pdfUrl: state.selected?.pdfUrl ?? byOrder?.pdfUrl,
        attachments: state.selected?.attachments ?? byOrder?.attachments,
      );

      await repository.saveOrUpdateAdditive(
        contractId: contract.id!,
        data: additive,
      );

      final bool didUpdate = resolvedId != null;

      NotificationCenter.instance.show(
        AppNotification(
          title: Text(didUpdate ? 'Aditivo atualizado' : 'Aditivo salvo'),
          type: AppNotificationType.success,
          details: Text(
            '${_userName()} • ${_stamp()}',
            style: const TextStyle(fontSize: 11),
          ),
        ),
      );

      await loadAdditives();

      // ✅ Após salvar, mantém tudo sincronizado selecionando a mesma ordem
      if (ord > 0) {
        selectAdditiveByOrder(ord);
      } else {
        createNewAdditive();
      }
    } catch (e, st) {
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

  Future<void> deleteSelectedAdditive() async {
    final selected = state.selected;
    if (contract.id == null || selected?.id == null) return;

    print('>>> deleteSelectedAdditive: ${selected!.id}');
    emit(state.copyWith(isSaving: true, clearError: true));

    try {
      await repository.deleteAdditive(
        contractId: contract.id!,
        additiveId: selected.id!,
      );

      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Aditivo deletado'),
          type: AppNotificationType.success,
          details: Text(
            '${_userName()} • ${_stamp()}',
            style: const TextStyle(fontSize: 11),
          ),
        ),
      );

      await loadAdditives();
      createNewAdditive();
    } catch (e, st) {
      // ignore: avoid_print
      print('>>> ERRO em deleteSelectedAdditive: $e\n$st');
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

    if ((selected.pdfUrl ?? '').isNotEmpty) {
      emit(state.copyWith(sideAttachments: <Attachment>[]));
      return;
    }

    final files = await repository.listarArquivosDoAditivo(
      contractId: contract.id!,
      additiveId: selected.id!,
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
        path: 'contracts/${contract.id}/additives/${selected.id}/${f.name}',
        ext: RegExp(
          r'\.([a-z0-9]+)$',
          caseSensitive: false,
        ).firstMatch(f.name)?.group(0) ??
            '',
        createdAt: DateTime.now(),
        createdBy: _currentUser?.uid,
      ),
    )
        .toList();

    await repository.setAttachments(
      contractId: contract.id!,
      additiveId: selected.id!,
      attachments: list,
    );

    final updatedSelected = AdditivesData(
      id: selected.id,
      contractId: selected.contractId,
      additiveNumberProcess: selected.additiveNumberProcess,
      additiveOrder: selected.additiveOrder,
      additiveDate: selected.additiveDate,
      typeOfAdditive: selected.typeOfAdditive,
      additiveValue: selected.additiveValue,
      additiveValidityContractDays: selected.additiveValidityContractDays,
      additiveValidityExecutionDays: selected.additiveValidityExecutionDays,
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

  String _suggestLabelFromName(AdditivesData additive, String original) {
    final base =
    original.split('/').last.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');
    final ord = additive.additiveOrder ?? 0;
    return 'Aditivo $ord - $base';
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
        additive: a,
        bytes: bytes,
        originalName: originalName,
        label: label,
      );

      final current =
      List<Attachment>.from(a.attachments ?? const <Attachment>[])..add(att);

      await repository.setAttachments(
        contractId: cId,
        additiveId: a.id!,
        attachments: current,
      );

      final updatedSelected = AdditivesData(
        id: a.id,
        contractId: a.contractId,
        additiveNumberProcess: a.additiveNumberProcess,
        additiveOrder: a.additiveOrder,
        additiveDate: a.additiveDate,
        typeOfAdditive: a.typeOfAdditive,
        additiveValue: a.additiveValue,
        additiveValidityContractDays: a.additiveValidityContractDays,
        additiveValidityExecutionDays: a.additiveValidityExecutionDays,
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
      print('>>> ERRO em addAttachmentWithPicker: $e\n$st');
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
        additiveId: a.id!,
        attachments: list,
      );

      final updatedSelected = AdditivesData(
        id: a.id,
        contractId: a.contractId,
        additiveNumberProcess: a.additiveNumberProcess,
        additiveOrder: a.additiveOrder,
        additiveDate: a.additiveDate,
        typeOfAdditive: a.typeOfAdditive,
        additiveValue: a.additiveValue,
        additiveValidityContractDays: a.additiveValidityContractDays,
        additiveValidityExecutionDays: a.additiveValidityExecutionDays,
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
      print('>>> ERRO em renameAttachment: $e\n$st');
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
          additiveId: a.id!,
          attachments: atts,
        );
      }

      final updatedSelected = AdditivesData(
        id: a.id,
        contractId: a.contractId,
        additiveNumberProcess: a.additiveNumberProcess,
        additiveOrder: a.additiveOrder,
        additiveDate: a.additiveDate,
        typeOfAdditive: a.typeOfAdditive,
        additiveValue: a.additiveValue,
        additiveValidityContractDays: a.additiveValidityContractDays,
        additiveValidityExecutionDays: a.additiveValidityExecutionDays,
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
      print('>>> ERRO em deleteAttachment: $e\n$st');
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
