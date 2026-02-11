// lib/_blocs/modules/contracts/contracts/validity/validity_cubit.dart
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_blocs/modules/contracts/validity/validity_data.dart';
import 'package:siged/_blocs/modules/contracts/validity/validity_repository.dart';
import 'package:siged/_blocs/modules/contracts/validity/validity_state.dart';
import 'package:siged/_utils/formats/sipged_format_dates.dart';
import 'package:siged/_widgets/list/files/attachment.dart';

class ValidityCubit extends Cubit<ValidityState> {
  final ValidityRepository _repository;

  ValidityCubit({required ValidityRepository repository})
      : _repository = repository,
        super(ValidityState.initial());

  // ---------------------------------------------------------------------------
  // Helpers internos
  // ---------------------------------------------------------------------------

  Set<int> _existingOrders(List<ValidityData> list) {
    return list
        .map((v) => v.orderNumber ?? 0)
        .where((n) => n > 0)
        .toSet();
  }

  int _nextAvailableOrder(Set<int> set) {
    if (set.isEmpty) return 1;
    for (int i = 1; i <= set.length + 1; i++) {
      if (!set.contains(i)) return i;
    }
    final max = set.reduce((a, b) => a > b ? a : b);
    return max + 1;
  }

  List<String> _orderNumberOptionsFromSet(Set<int> set) {
    final maxPlusOne =
    set.isEmpty ? 1 : (set.reduce((a, b) => a > b ? a : b) + 1);
    return List<String>.generate(maxPlusOne, (i) => '${i + 1}');
  }

  List<String> _rulesOrderTypes(List<ValidityData> validities) {
    final List<String> newOrders = [];
    final String? lastOrder =
    validities.isEmpty ? null : validities.last.ordertype;

    if (lastOrder == null) {
      newOrders.addAll(ValidityData.typeOfOrder);
    } else if (lastOrder == 'ORDEM DE INÍCIO') {
      newOrders.addAll([
        'ORDEM DE PARALISAÇÃO',
        'ORDEM DE FINALIZAÇÃO',
      ]);
    } else if (lastOrder == 'ORDEM DE PARALISAÇÃO') {
      newOrders.add('ORDEM DE REINÍCIO');
    } else if (lastOrder == 'ORDEM DE REINÍCIO') {
      newOrders.addAll([
        'ORDEM DE PARALISAÇÃO',
        'ORDEM DE FINALIZAÇÃO',
      ]);
    } else if (lastOrder != 'ORDEM DE FINALIZAÇÃO') {
      newOrders.addAll(ValidityData.typeOfOrder);
    }

    return newOrders;
  }

  List<ValidityData> _sorted(List<ValidityData> list) {
    final l = List<ValidityData>.from(list);
    l.sort((a, b) => (a.orderNumber ?? 0).compareTo(b.orderNumber ?? 0));
    return List<ValidityData>.unmodifiable(l);
  }

  // ---------------------------------------------------------------------------
  // Carregamento inicial para um contrato
  // ---------------------------------------------------------------------------

  Future<void> loadForContract(String contractId) async {
    if (contractId.isEmpty) return;

    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final contract =
      await _repository.getSpecificContract(uid: contractId);
      if (contract == null) {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: 'Contrato não encontrado',
          ),
        );
        return;
      }

      final validities =
      await _repository.getAllValidityOfContract(uidContract: contractId);
      final sortedValidities = _sorted(validities);

      final additives =
      await _repository.buscarAditivos(contractId);

      final existingSet = _existingOrders(sortedValidities);
      final nextOrder = _nextAvailableOrder(existingSet);

      emit(
        state.copyWith(
          isLoading: false,
          contract: contract,
          validities: sortedValidities,
          additives: additives,
          nextOrderNumber: nextOrder,
          orderNumberOptions: _orderNumberOptionsFromSet(existingSet),
          greyOrderItems:
          existingSet.map((e) => e.toString()).toSet(),
          availableOrderTypes: _rulesOrderTypes(sortedValidities),
          selectedValidity: null,
          attachments: const <Attachment>[],
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Erro ao carregar validades: $e',
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Seleção por número de ordem (dropdown inteligente)
  // ---------------------------------------------------------------------------

  /// Chamado quando o usuário muda o número da ordem no dropdown.
  ///
  /// - Se já existe validade com esse número → seleciona.
  /// - Se não existe → cria draft novo (ainda não salvo) com esse número.
  Future<void> selectOrderNumber(String? value) async {
    final picked = int.tryParse(value ?? '');
    if (picked == null || picked <= 0) return;

    final currentValidities = state.validities;
    final idx = currentValidities
        .indexWhere((x) => (x.orderNumber ?? -1) == picked);

    if (idx >= 0) {
      await selectValidity(currentValidities[idx]);
      return;
    }

    // Novo draft
    final draft = ValidityData(
      uidContract: state.contract?.id,
      orderNumber: picked,
    );

    emit(
      state.copyWith(
        selectedValidity: draft,
        attachments: const <Attachment>[],
        errorMessage: null,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Seleção direta de uma validade (linha da tabela / timeline)
  // ---------------------------------------------------------------------------

  Future<void> selectValidity(ValidityData data) async {
    final contract = state.contract;
    if (contract == null) return;

    try {
      final attachments = await _repository.loadAndEnsureAttachments(
        contract: contract,
        validity: data,
      );

      emit(
        state.copyWith(
          selectedValidity: data,
          attachments: attachments,
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          selectedValidity: data,
          attachments: const <Attachment>[],
          errorMessage: 'Erro ao carregar anexos: $e',
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Criação de nova validade (limpar formulário)
  // ---------------------------------------------------------------------------

  Future<void> createNewValidity() async {
    final contract = state.contract;
    if (contract == null) return;

    final existingSet = _existingOrders(state.validities);
    final nextOrder = _nextAvailableOrder(existingSet);

    final draft = ValidityData(
      uidContract: contract.id,
      orderNumber: nextOrder,
    );

    emit(
      state.copyWith(
        selectedValidity: draft,
        nextOrderNumber: nextOrder,
        attachments: const <Attachment>[],
        errorMessage: null,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Atualização de campos do formulário (ordertype / orderdate)
  // ---------------------------------------------------------------------------

  void updateOrderType(String? type) {
    final current = state.selectedValidity;
    if (current == null) return;

    emit(
      state.copyWith(
        selectedValidity: current.copyWith(ordertype: type),
      ),
    );
  }

  void updateOrderDate(String? ddMMyyyy) {
    final current = state.selectedValidity;
    if (current == null) return;

    emit(
      state.copyWith(
        selectedValidity: current.copyWith(
          orderdate: ddMMyyyy != null && ddMMyyyy.isNotEmpty
              ? SipGedFormatDates.ddMMyyyyToDate(ddMMyyyy)
              : null,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Save / Update
  // ---------------------------------------------------------------------------

  Future<void> saveSelected() async {
    final contract = state.contract;
    final current = state.selectedValidity;
    if (contract == null || current == null) return;

    emit(state.copyWith(isSaving: true, errorMessage: null));

    try {
      final toSave = current.copyWith(
        uidContract: contract.id,
      );

      final saved =
      await _repository.salvarOuAtualizarValidade(toSave);

      await _repository.notificarUsuariosSobreValidade(
        saved,
        contract.id!,
      );

      // Atualiza lista em memória
      final list = List<ValidityData>.from(state.validities);
      final idx = list.indexWhere((e) => e.id == saved.id);
      if (idx >= 0) {
        list[idx] = saved;
      } else {
        list.add(saved);
      }
      final sorted = _sorted(list);

      final existingSet = _existingOrders(sorted);
      final nextOrder = _nextAvailableOrder(existingSet);

      emit(
        state.copyWith(
          isSaving: false,
          validities: sorted,
          selectedValidity: saved,
          nextOrderNumber: nextOrder,
          orderNumberOptions:
          _orderNumberOptionsFromSet(existingSet),
          greyOrderItems:
          existingSet.map((e) => e.toString()).toSet(),
          availableOrderTypes: _rulesOrderTypes(sorted),
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isSaving: false,
          errorMessage: 'Erro ao salvar validade: $e',
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Delete
  // ---------------------------------------------------------------------------

  Future<void> deleteValidity(String validityId) async {
    final contract = state.contract;
    if (contract == null) return;

    emit(state.copyWith(isSaving: true, errorMessage: null));

    try {
      await _repository.deletarValidade(
        contract.id!,
        validityId,
      );

      final list = List<ValidityData>.from(state.validities)
        ..removeWhere((e) => e.id == validityId);
      final sorted = _sorted(list);

      final existingSet = _existingOrders(sorted);
      final nextOrder = _nextAvailableOrder(existingSet);

      emit(
        state.copyWith(
          isSaving: false,
          validities: sorted,
          selectedValidity: null,
          attachments: const <Attachment>[],
          nextOrderNumber: nextOrder,
          orderNumberOptions:
          _orderNumberOptionsFromSet(existingSet),
          greyOrderItems:
          existingSet.map((e) => e.toString()).toSet(),
          availableOrderTypes: _rulesOrderTypes(sorted),
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isSaving: false,
          errorMessage: 'Erro ao apagar validade: $e',
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Anexos: adicionar / renomear / remover
  // ---------------------------------------------------------------------------

  String _suggestLabelFromName(ValidityData v, String original) {
    final base = original
        .split('/')
        .last
        .replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');
    final ord = v.orderNumber ?? 0;
    return 'Ordem $ord - $base';
  }

  /// Pegamos o arquivo (via repository → storage), mas o diálogo de label
  /// continua responsabilidade da UI. Aqui só aplica o label final.
  Future<Attachment?> addAttachmentFromBytes({
    required Uint8List bytes,
    required String originalName,
    required String? customLabel,
  }) async {
    final contract = state.contract;
    final v = state.selectedValidity;
    if (contract == null || v == null || contract.id == null) {
      return null;
    }

    emit(state.copyWith(isSaving: true, errorMessage: null));

    try {
      final suggestion = _suggestLabelFromName(v, originalName);
      final label =
      (customLabel == null || customLabel.isEmpty)
          ? suggestion
          : customLabel;

      final att = await _repository.uploadAttachmentBytes(
        contract: contract,
        validity: v,
        bytes: bytes,
        originalName: originalName,
        label: label,
      );

      final current =
      List<Attachment>.from(state.attachments)..add(att);

      await _repository.setAttachments(
        contractId: contract.id!,
        validityId: v.id!,
        attachments: current,
      );

      emit(
        state.copyWith(
          isSaving: false,
          attachments: current,
          selectedValidity: v.copyWith(attachments: current),
        ),
      );

      return att;
    } catch (e) {
      emit(
        state.copyWith(
          isSaving: false,
          errorMessage: 'Erro ao adicionar anexo: $e',
        ),
      );
      return null;
    }
  }

  Future<void> renameAttachment(int index, String newLabel) async {
    final contract = state.contract;
    final v = state.selectedValidity;
    if (contract == null || v == null || v.id == null) return;
    if (index < 0 || index >= state.attachments.length) return;

    emit(state.copyWith(isSaving: true, errorMessage: null));

    try {
      final old = state.attachments[index];
      final updated = Attachment(
        id: old.id,
        label: newLabel.isEmpty ? old.label : newLabel,
        url: old.url,
        path: old.path,
        ext: old.ext,
        size: old.size,
        createdAt: old.createdAt,
        createdBy: old.createdBy,
        updatedAt: DateTime.now(),
        updatedBy: null, // se quiser, injeta uid aqui via repo
      );

      final list = List<Attachment>.from(state.attachments);
      list[index] = updated;

      await _repository.setAttachments(
        contractId: contract.id!,
        validityId: v.id!,
        attachments: list,
      );

      emit(
        state.copyWith(
          isSaving: false,
          attachments: list,
          selectedValidity: v.copyWith(attachments: list),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isSaving: false,
          errorMessage: 'Erro ao renomear anexo: $e',
        ),
      );
    }
  }

  Future<void> deleteAttachmentAt(int index) async {
    final contract = state.contract;
    final v = state.selectedValidity;
    if (contract == null || v == null || v.id == null) return;
    if (index < 0 || index >= state.attachments.length) return;

    emit(state.copyWith(isSaving: true, errorMessage: null));

    try {
      final list = List<Attachment>.from(state.attachments);
      final removed = list.removeAt(index);

      if ((removed.path).isNotEmpty) {
        await _repository.deleteStorageByPath(removed.path);
      }

      await _repository.setAttachments(
        contractId: contract.id!,
        validityId: v.id!,
        attachments: list,
      );

      emit(
        state.copyWith(
          isSaving: false,
          attachments: list,
          selectedValidity: v.copyWith(attachments: list),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isSaving: false,
          errorMessage: 'Erro ao remover anexo: $e',
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Cálculos de prazo (aproveitando as funções puras do repositório)
  // ---------------------------------------------------------------------------

  DateTime? get dataFinalContrato {
    final c = state.contract;
    if (c == null) return null;
    return _repository.calcularDataFinalContratoLocal(
      contract: c,
      additives: state.additives,
    );
  }

  DateTime? get dataFinalExecucao {
    final c = state.contract;
    if (c == null) return null;
    return _repository.calcularDataFinalExecucaoLocal(
      contract: c,
      validities: state.validities,
      additives: state.additives,
    );
  }
}
