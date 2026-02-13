import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sipged/_widgets/list/files/attachment.dart';
import 'package:sipged/screens/modules/financial/finance_utils.dart';

import 'empenho_data.dart';
import 'empenho_repository.dart';
import 'empenho_state.dart';

class EmpenhoCubit extends Cubit<EmpenhoState> {
  final EmpenhoRepository _repo;

  EmpenhoCubit({EmpenhoRepository? repository})
      : _repo = repository ?? EmpenhoRepository(),
        super(EmpenhoState.initial());

  // ==================== LOAD ====================

  Future<void> loadAll() async {
    emit(state.copyWith(status: EmpenhoStatus.loading, clearError: true));
    try {
      final list = await _repo.getAll();
      emit(state.copyWith(
        status: EmpenhoStatus.success,
        items: list,
        contractId: null,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(status: EmpenhoStatus.failure, error: e.toString()));
    }
  }

  Future<void> loadByContract(String contractId) async {
    emit(state.copyWith(
      status: EmpenhoStatus.loading,
      contractId: contractId,
      clearError: true,
    ));

    try {
      final list = await _repo.getAllByContract(contractId: contractId);
      emit(state.copyWith(
        status: EmpenhoStatus.success,
        items: list,
        contractId: contractId,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(status: EmpenhoStatus.failure, error: e.toString()));
    }
  }

  // ==================== SELECTION ====================

  void select(EmpenhoData? e) {
    if (e == null) {
      emit(state.copyWith(
        selected: null,
        clearSelected: true,
        numero: '',

        // ✅ limpa demanda
        clearDemand: true,
        credor: '',

        // ✅ limpa company
        clearCompanyId: true,
        companyLabel: '',

        // ✅ limpa fonte
        fundingSourceId: null,
        clearFundingSourceId: true,
        fundingSourceLabel: '',

        totalText: '',
        date: null,
        sliceLabels: const [],
        sliceAmounts: const [],
        attachments: const [],
        clearSelectedSideIndex: true,
        clearError: true,
        status: EmpenhoStatus.success,
      ));
      return;
    }

    emit(state.copyWith(
      selected: e,
      numero: e.numero,

      demandContractId: e.demandContractId,
      demandLabel: e.demandLabel,
      // legado
      credor: e.demandLabel,

      companyId: e.companyId,
      companyLabel: e.companyLabel ?? '',

      fundingSourceId: e.fundingSourceId,
      fundingSourceLabel: e.fundingSourceLabel,

      totalText: e.empenhadoTotal.toStringAsFixed(2),
      date: e.date,
      sliceLabels: e.slices.map((s) => s.label).toList(),
      sliceAmounts: e.slices.map((s) => s.amount.toStringAsFixed(2)).toList(),
      attachments: (e.attachments ?? const <Attachment>[]),
      clearSelectedSideIndex: true,
      clearError: true,
      status: EmpenhoStatus.success,
    ));
  }

  // ==================== SETTERS (FORM) ====================

  void setNumero(String v) => emit(state.copyWith(numero: v));

  /// ✅ DEMANDA (id + label)
  void setDemandContractId(String? id) => emit(state.copyWith(demandContractId: id));
  void setDemandLabel(String label) =>
      emit(state.copyWith(demandLabel: label, credor: label)); // espelha legado
  void clearDemand() => emit(state.copyWith(clearDemand: true, credor: ''));

  // ✅ COMPANY
  void setCompanyId(String? id) => emit(state.copyWith(companyId: id));
  void setCompanyLabel(String v) => emit(state.copyWith(companyLabel: v));
  void clearCompany() => emit(state.copyWith(clearCompanyId: true, companyLabel: ''));

  // ✅ Fonte de recurso
  void setFundingSourceLabel(String v) =>
      emit(state.copyWith(fundingSourceLabel: v));

  void setFundingSourceId(String? id) =>
      emit(state.copyWith(fundingSourceId: id));

  void clearFundingSourceId() =>
      emit(state.copyWith(clearFundingSourceId: true));

  void setTotalText(String v) => emit(state.copyWith(totalText: v));
  void setDate(DateTime? d) => emit(state.copyWith(date: d));

  // ==================== SLICES ====================

  void addSlice() {
    emit(state.copyWith(
      sliceLabels: [...state.sliceLabels, 'Nova fatia'],
      sliceAmounts: [...state.sliceAmounts, '0'],
    ));
  }

  void removeSlice(int index) {
    if (index < 0 || index >= state.sliceLabels.length) return;
    final labels = [...state.sliceLabels]..removeAt(index);
    final amounts = [...state.sliceAmounts]..removeAt(index);
    emit(state.copyWith(sliceLabels: labels, sliceAmounts: amounts));
  }

  void setSliceLabel(int index, String v) {
    if (index < 0 || index >= state.sliceLabels.length) return;
    final labels = [...state.sliceLabels];
    labels[index] = v;
    emit(state.copyWith(sliceLabels: labels));
  }

  void setSliceAmount(int index, String v) {
    if (index < 0 || index >= state.sliceAmounts.length) return;
    final amounts = [...state.sliceAmounts];
    amounts[index] = v;
    emit(state.copyWith(sliceAmounts: amounts));
  }

  // ==================== ATTACHMENTS ====================

  void selectSideIndex(int? i) => emit(state.copyWith(selectedSideIndex: i));

  void addAttachment(Attachment a) {
    final list = [...state.attachments, a];
    emit(state.copyWith(attachments: list, selectedSideIndex: list.length - 1));
  }

  void deleteAttachmentAt(int index) {
    if (index < 0 || index >= state.attachments.length) return;
    final list = [...state.attachments]..removeAt(index);

    int? nextSelected;
    if (list.isNotEmpty) {
      nextSelected = (index >= list.length) ? list.length - 1 : index;
    }
    emit(state.copyWith(attachments: list, selectedSideIndex: nextSelected));
  }
  /// SideListBox (novo) -> quando a UI muda a lista (reorder/rename local etc)
  void setAttachmentsFromUi(List<dynamic> items) {
    final list = <Attachment>[];
    for (final it in items) {
      if (it is Attachment) list.add(it);
    }

    // mantém selectedSideIndex válido
    int? idx = state.selectedSideIndex;
    if (idx != null) {
      if (list.isEmpty) {
        idx = null;
      } else if (idx < 0) idx = 0;
      else if (idx >= list.length) idx = list.length - 1;
    }

    emit(state.copyWith(attachments: list, selectedSideIndex: idx));
  }

  /// SideListBox (novo) -> rename com persistência (retorna bool)
  Future<bool> persistRenameAttachment({
    required int index,
    required Attachment oldItem,
    required Attachment newItem,
  }) async {
    // só permite se existir registro selecionado (id)
    final sel = state.selected;
    if (sel?.id == null) return false;

    if (index < 0 || index >= state.attachments.length) return false;

    final newLabel = newItem.label.trim();
    if (newLabel.isEmpty) return false;

    // evita escrita desnecessária
    if (oldItem.label.trim() == newLabel) return true;

    try {
      // atualiza lista local
      final list = [...state.attachments];
      list[index] = list[index].copyWith(
        label: newLabel,
        updatedAt: DateTime.now(),
        // updatedBy: ... (se você tiver uid no state, pluga aqui)
      );
      emit(state.copyWith(attachments: list));

      // persiste no Firestore via repo (update parcial)
      final payload = EmpenhoData(
        id: sel!.id,
        contractId: sel.contractId,
        numero: sel.numero,

        demandContractId: sel.demandContractId,
        demandLabel: sel.demandLabel,
        credor: sel.credor,

        companyId: sel.companyId,
        companyLabel: sel.companyLabel,

        fundingSourceId: sel.fundingSourceId,
        fundingSourceLabel: sel.fundingSourceLabel,
        objeto: sel.objeto,

        date: sel.date,
        empenhadoTotal: sel.empenhadoTotal,
        slices: sel.slices,

        attachments: list.isEmpty ? null : list,
        pdfUrl: list.isNotEmpty ? list.first.url : null, // compat
      );

      await _repo.saveOrUpdate(payload);

      // mantém state.selected coerente (pra reabrir e não perder rename)
      emit(state.copyWith(selected: sel.copyWith(
        attachments: list.isEmpty ? null : list,
        pdfUrl: list.isNotEmpty ? list.first.url : null,
      )));

      return true;
    } catch (_) {
      // se falhar, tenta reverter no state (opcional)
      final list = [...state.attachments];
      if (index >= 0 && index < list.length) {
        list[index] = list[index].copyWith(label: oldItem.label);
        emit(state.copyWith(attachments: list));
      }
      return false;
    }
  }

  void editAttachmentLabel(int index, String newLabel) {
    if (index < 0 || index >= state.attachments.length) return;
    final list = [...state.attachments];
    final old = list[index];
    list[index] = old.copyWith(label: newLabel);
    emit(state.copyWith(attachments: list));
  }

  // ==================== COMPUTEDS ====================

  double _toDoubleMoney(String s) {
    final raw = s.trim();
    if (raw.isEmpty) return 0.0;

    final normalized = raw
        .replaceAll('R\$', '')
        .replaceAll(' ', '')
        .replaceAll('.', '')
        .replaceAll(',', '.');

    return double.tryParse(normalized) ?? 0.0;
  }

  double get totalValue => _toDoubleMoney(state.totalText);

  double get somaFatias {
    double sum = 0;
    for (final s in state.sliceAmounts) {
      sum += _toDoubleMoney(s);
    }
    return sum;
  }

  bool get formValidated {
    final numero = state.numero.trim();
    final demandLabel = state.demandLabel.trim();
    final demandId = (state.demandContractId ?? '').trim();
    final company = (state.companyId ?? '').trim();
    final fonte = state.fundingSourceLabel.trim();
    final total = totalValue;

    return numero.isNotEmpty &&
        demandLabel.isNotEmpty &&
        demandId.isNotEmpty &&
        company.isNotEmpty &&
        fonte.isNotEmpty &&
        total > 0;
  }

  // ==================== SAVE/DELETE ====================

  Future<void> saveOrUpdate() async {
    if (!formValidated) {
      emit(state.copyWith(
        status: EmpenhoStatus.failure,
        error:
        'Preencha Número, Demanda (selecionada), Contratante, Fonte de recurso e Valor total (> 0).',
      ));
      return;
    }

    emit(state.copyWith(status: EmpenhoStatus.loading, clearError: true));

    try {
      final dt = state.date ?? DateTime.now();

      final slices = <AllocationSlice>[];
      for (int i = 0; i < state.sliceLabels.length; i++) {
        final label = state.sliceLabels[i].trim();
        final amount = _toDoubleMoney(state.sliceAmounts[i]);
        if (label.isEmpty) continue;
        if (amount <= 0) continue;
        slices.add(AllocationSlice(label: label, amount: amount));
      }

      final payload = EmpenhoData(
        id: state.selected?.id,
        contractId:
        (state.contractId?.trim().isEmpty ?? true) ? null : state.contractId,

        numero: state.numero.trim(),

        // ✅ demanda (novo)
        demandContractId: state.demandContractId,
        demandLabel: state.demandLabel.trim(),

        // ✅ legado espelhado
        credor: state.demandLabel.trim(),

        companyId: state.companyId,
        companyLabel: state.companyLabel.trim().isEmpty ? null : state.companyLabel.trim(),

        fundingSourceId: state.fundingSourceId,
        fundingSourceLabel: state.fundingSourceLabel.trim(),

        // compat
        objeto: state.fundingSourceLabel.trim(),

        date: dt,
        empenhadoTotal: totalValue,
        slices: slices,
        attachments: state.attachments.isEmpty ? null : state.attachments,
        pdfUrl: state.attachments.isNotEmpty ? state.attachments.first.url : null,
      );

      await _repo.saveOrUpdate(payload);

      final cid = state.contractId?.trim() ?? '';
      if (cid.isNotEmpty) {
        await loadByContract(cid);
      } else {
        await loadAll();
      }

      emit(state.copyWith(status: EmpenhoStatus.success, clearError: true));
    } catch (e) {
      emit(state.copyWith(status: EmpenhoStatus.failure, error: e.toString()));
    }
  }

  Future<void> deleteSelected() async {
    final sel = state.selected;
    if (sel?.id == null) return;

    emit(state.copyWith(status: EmpenhoStatus.loading, clearError: true));

    try {
      await _repo.deleteById(sel!.id!);

      final cid = state.contractId?.trim() ?? '';
      if (cid.isNotEmpty) {
        await loadByContract(cid);
      } else {
        await loadAll();
      }

      select(null);
      emit(state.copyWith(status: EmpenhoStatus.success, clearError: true));
    } catch (e) {
      emit(state.copyWith(status: EmpenhoStatus.failure, error: e.toString()));
    }
  }
}
