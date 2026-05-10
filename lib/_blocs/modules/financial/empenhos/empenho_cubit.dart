import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/system/permission/permission_data.dart';
import 'package:sipged/_widgets/list/files/attachment.dart';
import 'package:sipged/screens/modules/financial/dashboard/finance_utils.dart';

import 'empenho_data.dart';
import 'empenho_repository.dart';
import 'empenho_state.dart';

class EmpenhoCubit extends Cubit<EmpenhoState> {
  EmpenhoCubit({
    EmpenhoRepository? repository,
    UserPermissionData? initialPermissions,
    String? initialTenantId,
  })  : _repo = repository ?? EmpenhoRepository(tenantId: initialTenantId),
        _tenantId = initialTenantId?.trim(),
        super(EmpenhoState.initial()) {
    _syncTenantOnRepository();
  }

  final EmpenhoRepository _repo;

  String? _tenantId;

  String? _lastContractId;

  String? get activeTenantId {
    final clean = _tenantId?.trim();

    if (clean == null || clean.isEmpty) return null;

    return clean;
  }

  void _syncTenantOnRepository() {
    _repo.setActiveTenantId(activeTenantId);
  }

  bool _hasTenantOrFail() {
    final tid = activeTenantId;

    if (tid == null || tid.isEmpty) {
      emit(
        state.copyWith(
          status: EmpenhoStatus.failure,
          items: const [],
          dfds: const [],
          loadingDfds: false,
          error: 'Tenant ativo não identificado para carregar empenhos.',
        ),
      );

      return false;
    }

    _repo.setActiveTenantId(tid);

    return true;
  }

  Future<void> updatePermissions({
    UserPermissionData? permissions,
    String? tenantId,
    bool reload = true,
  }) async {
    final oldTenantId = activeTenantId;


    final cleanTenantId = tenantId?.trim();
    _tenantId =
    cleanTenantId == null || cleanTenantId.isEmpty ? null : cleanTenantId;

    _syncTenantOnRepository();

    final changedTenant = oldTenantId != activeTenantId;

    if (!reload || !changedTenant) return;

    await init(contractId: _lastContractId);
  }

  Future<void> init({
    String? contractId,
  }) async {
    final cid = (contractId ?? '').trim();
    _lastContractId = cid.isEmpty ? null : cid;

    if (!_hasTenantOrFail()) return;

    await loadDfds();

    if (cid.isNotEmpty) {
      await loadByContract(cid);
    } else {
      await loadAll();
    }
  }

  Future<void> loadDfds() async {
    if (state.loadingDfds) return;
    if (!_hasTenantOrFail()) return;

    emit(
      state.copyWith(
        loadingDfds: true,
        clearError: true,
      ),
    );

    try {
      final list = await _repo.getAvailableDfds();

      emit(
        state.copyWith(
          loadingDfds: false,
          dfds: list,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          loadingDfds: false,
          dfds: const [],
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> loadAll() async {
    _lastContractId = null;

    if (!_hasTenantOrFail()) return;

    emit(
      state.copyWith(
        status: EmpenhoStatus.loading,
        clearContractId: true,
        clearError: true,
      ),
    );

    try {
      final list = await _repo.getAll();

      emit(
        state.copyWith(
          status: EmpenhoStatus.success,
          items: list,
          clearContractId: true,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: EmpenhoStatus.failure,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> loadByContract(String contractId) async {
    final cid = contractId.trim();

    _lastContractId = cid.isEmpty ? null : cid;

    if (!_hasTenantOrFail()) return;

    emit(
      state.copyWith(
        status: EmpenhoStatus.loading,
        contractId: cid,
        clearError: true,
      ),
    );

    try {
      final list = await _repo.getAllByContract(contractId: cid);

      emit(
        state.copyWith(
          status: EmpenhoStatus.success,
          items: list,
          contractId: cid,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: EmpenhoStatus.failure,
          error: e.toString(),
        ),
      );
    }
  }

  void select(EmpenhoData? e) {
    if (e == null) {
      emit(
        state.copyWith(
          selected: null,
          clearSelected: true,
          numero: '',
          clearDemand: true,
          credor: '',
          clearCompanyId: true,
          companyLabel: '',
          clearFundingSourceId: true,
          fundingSourceLabel: '',
          totalText: '',
          clearDate: true,
          sliceLabels: const [],
          sliceAmounts: const [],
          attachments: const [],
          clearSelectedSideIndex: true,
          clearError: true,
          status: EmpenhoStatus.success,
        ),
      );

      return;
    }

    emit(
      state.copyWith(
        selected: e,
        numero: e.numero,
        demandContractId: e.demandContractId,
        demandLabel: e.demandLabel,
        credor: e.demandLabel,
        companyId: e.companyId,
        companyLabel: e.companyLabel ?? '',
        fundingSourceId: e.fundingSourceId,
        fundingSourceLabel: e.fundingSourceLabel,
        totalText: e.empenhadoTotal.toStringAsFixed(2),
        date: e.date,
        sliceLabels: e.slices.map((s) => s.label).toList(),
        sliceAmounts: e.slices.map((s) => s.amount.toStringAsFixed(2)).toList(),
        attachments: e.attachments ?? const <Attachment>[],
        clearSelectedSideIndex: true,
        clearError: true,
        status: EmpenhoStatus.success,
      ),
    );
  }

  void setNumero(String v) {
    emit(state.copyWith(numero: v));
  }

  void setDemandContractId(String? id) {
    final value = (id ?? '').trim();

    emit(
      state.copyWith(
        demandContractId: value.isEmpty ? null : value,
      ),
    );
  }

  void setDemandLabel(String label) {
    emit(
      state.copyWith(
        demandLabel: label.trim(),
        credor: label.trim(),
      ),
    );
  }

  void clearDemand() {
    emit(
      state.copyWith(
        clearDemand: true,
        credor: '',
      ),
    );
  }

  void setCompanyId(String? id) {
    final value = (id ?? '').trim();

    emit(
      state.copyWith(
        companyId: value.isEmpty ? null : value,
      ),
    );
  }

  void setCompanyLabel(String v) {
    emit(state.copyWith(companyLabel: v.trim()));
  }

  void clearCompany() {
    emit(
      state.copyWith(
        clearCompanyId: true,
        companyLabel: '',
      ),
    );
  }

  void setFundingSourceLabel(String v) {
    emit(state.copyWith(fundingSourceLabel: v.trim()));
  }

  void setFundingSourceId(String? id) {
    final value = (id ?? '').trim();

    emit(
      state.copyWith(
        fundingSourceId: value.isEmpty ? null : value,
      ),
    );
  }

  void clearFundingSourceId() {
    emit(state.copyWith(clearFundingSourceId: true));
  }

  void setTotalText(String v) {
    emit(state.copyWith(totalText: v));
  }

  void setDate(DateTime? d) {
    emit(
      state.copyWith(
        date: d,
        clearDate: d == null,
      ),
    );
  }

  void addSlice() {
    emit(
      state.copyWith(
        sliceLabels: [...state.sliceLabels, 'Nova fatia'],
        sliceAmounts: [...state.sliceAmounts, '0'],
      ),
    );
  }

  void removeSlice(int index) {
    if (index < 0 || index >= state.sliceLabels.length) return;

    final labels = [...state.sliceLabels]..removeAt(index);
    final amounts = [...state.sliceAmounts];

    if (index < amounts.length) {
      amounts.removeAt(index);
    }

    emit(
      state.copyWith(
        sliceLabels: labels,
        sliceAmounts: amounts,
      ),
    );
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

  void selectSideIndex(int? i) {
    if (i == null) {
      emit(state.copyWith(clearSelectedSideIndex: true));
      return;
    }

    emit(state.copyWith(selectedSideIndex: i));
  }

  void addAttachment(Attachment a) {
    final list = [...state.attachments, a];

    emit(
      state.copyWith(
        attachments: list,
        selectedSideIndex: list.length - 1,
      ),
    );
  }

  void deleteAttachmentAt(int index) {
    if (index < 0 || index >= state.attachments.length) return;

    final list = [...state.attachments]..removeAt(index);

    if (list.isEmpty) {
      emit(
        state.copyWith(
          attachments: list,
          clearSelectedSideIndex: true,
        ),
      );

      return;
    }

    final nextSelected = index >= list.length ? list.length - 1 : index;

    emit(
      state.copyWith(
        attachments: list,
        selectedSideIndex: nextSelected,
      ),
    );
  }

  void setAttachmentsFromUi(List<dynamic> items) {
    final list = <Attachment>[];

    for (final it in items) {
      if (it is Attachment) {
        list.add(it);
      }
    }

    int? idx = state.selectedSideIndex;

    if (idx != null) {
      if (list.isEmpty) {
        idx = null;
      } else if (idx < 0) {
        idx = 0;
      } else if (idx >= list.length) {
        idx = list.length - 1;
      }
    }

    emit(
      state.copyWith(
        attachments: list,
        selectedSideIndex: idx,
        clearSelectedSideIndex: idx == null,
      ),
    );
  }

  Future<bool> persistRenameAttachment({
    required int index,
    required Attachment oldItem,
    required Attachment newItem,
  }) async {
    if (!_hasTenantOrFail()) return false;

    final selected = state.selected;

    if (selected?.id == null || selected!.id!.trim().isEmpty) {
      return false;
    }

    if (index < 0 || index >= state.attachments.length) {
      return false;
    }

    final newLabel = newItem.label.trim();

    if (newLabel.isEmpty) {
      return false;
    }

    if (oldItem.label.trim() == newLabel) {
      return true;
    }

    final previous = [...state.attachments];

    try {
      final list = [...state.attachments];

      list[index] = list[index].copyWith(
        label: newLabel,
        updatedAt: DateTime.now(),
      );

      emit(state.copyWith(attachments: list));

      final payload = selected.copyWith(
        attachments: list.isEmpty ? null : list,
        clearAttachments: list.isEmpty,
        pdfUrl: list.isNotEmpty ? list.first.url : null,
        clearPdfUrl: list.isEmpty,
      );

      await _repo.saveOrUpdate(payload);

      emit(
        state.copyWith(
          selected: payload,
          attachments: list,
        ),
      );

      return true;
    } catch (_) {
      emit(state.copyWith(attachments: previous));
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

  double _toDoubleMoney(String s) {
    final raw = s.trim();

    if (raw.isEmpty) {
      return 0.0;
    }

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

  Future<void> saveOrUpdate() async {
    if (!_hasTenantOrFail()) return;

    if (!formValidated) {
      emit(
        state.copyWith(
          status: EmpenhoStatus.failure,
          error:
          'Preencha Número, Demanda selecionada, Contratante, Fonte de recurso e Valor total maior que zero.',
        ),
      );

      return;
    }

    emit(
      state.copyWith(
        status: EmpenhoStatus.loading,
        clearError: true,
      ),
    );

    try {
      final dt = state.date ?? DateTime.now();

      final slices = <AllocationSlice>[];

      for (int i = 0; i < state.sliceLabels.length; i++) {
        final label = state.sliceLabels[i].trim();

        final amount = i < state.sliceAmounts.length
            ? _toDoubleMoney(state.sliceAmounts[i])
            : 0.0;

        if (label.isEmpty || amount <= 0) {
          continue;
        }

        slices.add(
          AllocationSlice(
            label: label,
            amount: amount,
          ),
        );
      }

      final contractId = (state.contractId ?? '').trim();

      final payload = EmpenhoData(
        id: state.selected?.id,
        contractId: contractId.isEmpty ? null : contractId,
        numero: state.numero.trim(),
        demandContractId: state.demandContractId?.trim(),
        demandLabel: state.demandLabel.trim(),
        credor: state.demandLabel.trim(),
        companyId: state.companyId?.trim(),
        companyLabel:
        state.companyLabel.trim().isEmpty ? null : state.companyLabel.trim(),
        fundingSourceId: state.fundingSourceId?.trim(),
        fundingSourceLabel: state.fundingSourceLabel.trim(),
        objeto: state.fundingSourceLabel.trim(),
        date: dt,
        empenhadoTotal: totalValue,
        slices: slices,
        attachments: state.attachments.isEmpty ? null : state.attachments,
        pdfUrl: state.attachments.isNotEmpty ? state.attachments.first.url : null,
      );

      await _repo.saveOrUpdate(payload);

      if (contractId.isNotEmpty) {
        await loadByContract(contractId);
      } else {
        await loadAll();
      }

      emit(
        state.copyWith(
          status: EmpenhoStatus.success,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: EmpenhoStatus.failure,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> deleteSelected() async {
    if (!_hasTenantOrFail()) return;

    final selected = state.selected;

    if (selected?.id == null || selected!.id!.trim().isEmpty) {
      return;
    }

    emit(
      state.copyWith(
        status: EmpenhoStatus.loading,
        clearError: true,
      ),
    );

    try {
      await _repo.deleteById(selected.id!);

      final cid = state.contractId?.trim() ?? '';

      if (cid.isNotEmpty) {
        await loadByContract(cid);
      } else {
        await loadAll();
      }

      select(null);

      emit(
        state.copyWith(
          status: EmpenhoStatus.success,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: EmpenhoStatus.failure,
          error: e.toString(),
        ),
      );
    }
  }
}