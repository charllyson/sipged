import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siged/_widgets/list/files/attachment.dart';

import 'budget_data.dart';
import 'budget_repository.dart';
import 'budget_state.dart';

class BudgetCubit extends Cubit<BudgetState> {
  final BudgetRepository _repo;

  BudgetCubit({BudgetRepository? repository})
      : _repo = repository ?? BudgetRepository(),
        super(BudgetState.initial());

  // ==================== LOAD ====================

  Future<void> loadAll() async {
    emit(state.copyWith(status: BudgetStatus.loading, clearError: true));
    try {
      final list = await _repo.getAll();
      emit(state.copyWith(
        status: BudgetStatus.success,
        items: list,
        contractId: null,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(status: BudgetStatus.failure, error: e.toString()));
    }
  }

  Future<void> loadByContract(String contractId) async {
    emit(state.copyWith(
      status: BudgetStatus.loading,
      contractId: contractId,
      clearError: true,
    ));

    try {
      final list = await _repo.getAllByContract(contractId: contractId);
      emit(state.copyWith(
        status: BudgetStatus.success,
        items: list,
        contractId: contractId,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(status: BudgetStatus.failure, error: e.toString()));
    }
  }

  // ==================== SELECTION ====================

  void select(BudgetData? e) {
    if (e == null) {
      emit(state.copyWith(
        selected: null,
        clearSelected: true,
        year: DateTime.now().year,
        budgetCode: '',
        description: '',
        amountText: '',
        clearCompanyId: true,
        companyLabel: '',
        fundingSourceId: null,
        clearFundingSourceId: true,
        fundingSourceLabel: '',
        attachments: const [],
        clearSelectedSideIndex: true,
        clearError: true,
        status: BudgetStatus.success,
      ));
      return;
    }

    emit(state.copyWith(
      selected: e,
      year: e.year,
      budgetCode: e.budgetCode ?? '',
      description: e.description ?? '',
      amountText: e.amount.toStringAsFixed(2),
      companyId: e.companyId,
      companyLabel: e.companyLabel ?? '',
      fundingSourceId: e.fundingSourceId,
      fundingSourceLabel: e.fundingSourceLabel ?? '',
      attachments: (e.attachments ?? const <Attachment>[]),
      clearSelectedSideIndex: true,
      clearError: true,
      status: BudgetStatus.success,
    ));
  }

  // ==================== SETTERS (FORM) ====================

  void setCompanyId(String? id) => emit(state.copyWith(companyId: id));
  void setCompanyLabel(String v) => emit(state.copyWith(companyLabel: v));
  void clearCompany() => emit(state.copyWith(clearCompanyId: true, companyLabel: ''));

  void setFundingSourceLabel(String v) =>
      emit(state.copyWith(fundingSourceLabel: v));

  void setFundingSourceId(String? id) =>
      emit(state.copyWith(fundingSourceId: id));

  void clearFundingSourceId() =>
      emit(state.copyWith(clearFundingSourceId: true));

  void setYearText(String v) {
    final raw = v.trim();
    final y = int.tryParse(raw);
    emit(state.copyWith(year: y ?? 0));
  }

  void setBudgetCode(String v) => emit(state.copyWith(budgetCode: v));
  void setDescription(String v) => emit(state.copyWith(description: v));
  void setAmountText(String v) => emit(state.copyWith(amountText: v));

  // ==================== ATTACHMENTS ====================

  // ==================== ATTACHMENTS ====================

// ✅ novo: substituir lista inteira (usado pelo SideListBox.onItemsChanged)
  void setAttachments(List<Attachment> list) {
    // mantém selectedSideIndex consistente
    int? nextSelected = state.selectedSideIndex;
    if (list.isEmpty) {
      nextSelected = null;
    } else if (nextSelected == null || nextSelected < 0 || nextSelected >= list.length) {
      nextSelected = 0;
    }

    emit(state.copyWith(
      attachments: list,
      selectedSideIndex: nextSelected,
    ));
  }

// (mantém o seu)
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

  double get amountValue => _toDoubleMoney(state.amountText);

  bool get formValidated {
    final company = (state.companyId ?? '').trim();
    final fonte = state.fundingSourceLabel.trim();
    final y = state.year;
    final amount = amountValue;

    return company.isNotEmpty &&
        fonte.isNotEmpty &&
        y >= 2000 &&
        y <= 2100 &&
        amount > 0;
  }

  // ==================== SAVE/DELETE ====================

  Future<void> saveOrUpdate() async {
    if (!formValidated) {
      emit(state.copyWith(
        status: BudgetStatus.failure,
        error:
        'Preencha Contratante, Fonte de recurso, Exercício (ano válido) e Valor orçado (> 0).',
      ));
      return;
    }

    emit(state.copyWith(status: BudgetStatus.loading, clearError: true));

    try {
      final payload = BudgetData(
        id: state.selected?.id,
        contractId:
        (state.contractId?.trim().isEmpty ?? true) ? null : state.contractId,
        companyId: state.companyId,
        companyLabel:
        state.companyLabel.trim().isEmpty ? null : state.companyLabel.trim(),
        fundingSourceId: state.fundingSourceId,
        fundingSourceLabel: state.fundingSourceLabel.trim(),
        year: state.year,
        budgetCode: state.budgetCode.trim().isEmpty ? null : state.budgetCode.trim(),
        description: state.description.trim().isEmpty ? null : state.description.trim(),
        amount: amountValue,
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

      emit(state.copyWith(status: BudgetStatus.success, clearError: true));
    } catch (e) {
      emit(state.copyWith(status: BudgetStatus.failure, error: e.toString()));
    }
  }

  Future<void> deleteSelected() async {
    final sel = state.selected;
    if (sel?.id == null) return;

    emit(state.copyWith(status: BudgetStatus.loading, clearError: true));

    try {
      await _repo.deleteById(sel!.id!);

      final cid = state.contractId?.trim() ?? '';
      if (cid.isNotEmpty) {
        await loadByContract(cid);
      } else {
        await loadAll();
      }

      select(null);
      emit(state.copyWith(status: BudgetStatus.success, clearError: true));
    } catch (e) {
      emit(state.copyWith(status: BudgetStatus.failure, error: e.toString()));
    }
  }
}
