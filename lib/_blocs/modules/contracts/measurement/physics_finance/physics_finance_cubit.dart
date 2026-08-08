// lib/_blocs/modules/contracts/measurement/physics_finance/physics_finance_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/additives/additives_data.dart';
import 'package:sipged/_blocs/modules/contracts/additives/additives_repository.dart';

import 'physics_finance_data.dart';
import 'physics_finance_repository.dart';
import 'physics_finance_state.dart';

class PhysicsFinanceCubit extends Cubit<PhysicsFinanceState> {
  PhysicsFinanceCubit({
    required this._repository,
    required String tenantId,
    AdditivesRepository? additivesRepository,
  })  : _additivesRepository = additivesRepository ??
            AdditivesRepository(
              tenantId: tenantId.trim(),
            ),
        _tenantId = tenantId.trim(),
        super(PhysicsFinanceState.initial()) {
    _syncRepositoriesTenant();
  }

  final PhysicsFinanceRepository _repository;
  final AdditivesRepository _additivesRepository;

  String _tenantId;
  String? _loadedTermsKey;

  bool get hasTenantId {
    return _tenantId.trim().isNotEmpty;
  }

  String get tenantId {
    return _requireTenantId();
  }

  String _requireTenantId() {
    final cleanTenantId = _tenantId.trim();

    if (cleanTenantId.isEmpty) {
      throw Exception(
        'tenantId é obrigatório para acessar o planejamento físico-financeiro.',
      );
    }

    return cleanTenantId;
  }

  void _syncRepositoriesTenant() {
    final cleanTenantId = _tenantId.trim();

    _repository.setActiveTenantId(
      cleanTenantId.isEmpty ? null : cleanTenantId,
    );

    _additivesRepository.setActiveTenantId(
      cleanTenantId.isEmpty ? null : cleanTenantId,
    );
  }

  void updateTenantId(String tenantId) {
    final cleanTenantId = tenantId.trim();

    if (cleanTenantId.isEmpty) {
      throw Exception(
        'tenantId é obrigatório para atualizar o planejamento físico-financeiro.',
      );
    }

    if (_tenantId == cleanTenantId) return;

    _tenantId = cleanTenantId;
    _loadedTermsKey = null;

    _syncRepositoriesTenant();

    emit(PhysicsFinanceState.initial());
  }

  String _termsLoadKey({
    required String contractId,
    required int periods,
  }) {
    return <String>[
      _tenantId.trim(),
      contractId.trim(),
      periods.toString(),
    ].join('|');
  }

  List<double> _normalizeList(
      List<double> source,
      int periods,
      ) {
    if (periods <= 0) return const <double>[];

    if (source.length == periods) {
      return List<double>.from(source);
    }

    if (source.length > periods) {
      return List<double>.from(source.take(periods));
    }

    return <double>[
      ...source,
      ...List<double>.filled(periods - source.length, 0.0),
    ];
  }

  Map<String, List<double>> _normalizeGrid(
      Map<String, List<double>> source,
      int periods,
      ) {
    final Map<String, List<double>> output = <String, List<double>>{};

    if (periods <= 0) return output;

    source.forEach((key, value) {
      final cleanKey = key.trim();

      if (cleanKey.isEmpty) return;

      output[cleanKey] = _normalizeList(value, periods);
    });

    return output;
  }

  Future<void> loadTerms({
    required String contractId,
    required int periods,
    bool forceReload = false,
  }) async {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) {
      _loadedTermsKey = null;

      emit(
        state.copyWith(
          isLoading: false,
          termsLoaded: true,
          additives: const <AdditivesData>[],
          termAdditiveId: const <int, String>{},
          schedulesByTerm: const <int, PhysicsFinanceData>{},
          gridByTerm: const <int, Map<String, List<double>>>{},
          errorMessage:
          'contractId é obrigatório para carregar o planejamento físico-financeiro.',
        ),
      );
      return;
    }

    if (periods <= 0) {
      _loadedTermsKey = null;

      emit(
        state.copyWith(
          isLoading: false,
          termsLoaded: true,
          additives: const <AdditivesData>[],
          termAdditiveId: const <int, String>{},
          schedulesByTerm: const <int, PhysicsFinanceData>{},
          gridByTerm: const <int, Map<String, List<double>>>{},
          errorMessage:
          'Quantidade de períodos inválida para o planejamento físico-financeiro.',
        ),
      );
      return;
    }

    try {
      _requireTenantId();
      _syncRepositoriesTenant();
    } catch (e) {
      _loadedTermsKey = null;

      emit(
        state.copyWith(
          isLoading: false,
          termsLoaded: true,
          additives: const <AdditivesData>[],
          termAdditiveId: const <int, String>{},
          schedulesByTerm: const <int, PhysicsFinanceData>{},
          gridByTerm: const <int, Map<String, List<double>>>{},
          errorMessage: e.toString(),
        ),
      );
      return;
    }

    final String loadKey = _termsLoadKey(
      contractId: cleanContractId,
      periods: periods,
    );

    if (_loadedTermsKey == loadKey && state.termsLoaded && !forceReload) {
      return;
    }

    emit(
      state.copyWith(
        isLoading: true,
        clearErrorMessage: true,
      ),
    );

    try {
      final additives = await _additivesRepository.ensureForContract(
        cleanContractId,
      );

      final orderedAdditives = List<AdditivesData>.from(additives)
        ..sort(
              (a, b) => (a.additiveOrder ?? 0).compareTo(
            b.additiveOrder ?? 0,
          ),
        );

      final Map<int, String> termAdditiveId = <int, String>{};

      for (final additive in orderedAdditives) {
        final int order = additive.additiveOrder ?? 0;
        final String? id = additive.id?.trim();

        if (order > 0 && id != null && id.isNotEmpty) {
          termAdditiveId[order] = id;
        }
      }

      final Map<int, PhysicsFinanceData> schedulesByTerm =
      <int, PhysicsFinanceData>{};

      final Map<int, Map<String, List<double>>> gridByTerm =
      <int, Map<String, List<double>>>{};

      for (final entry in termAdditiveId.entries) {
        final int termOrder = entry.key;
        final String additiveId = entry.value.trim();

        if (termOrder <= 0 || additiveId.isEmpty) continue;

        final schedule = await _repository.get(
          contractId: cleanContractId,
          additiveId: additiveId,
          termOrder: termOrder,
        );

        if (schedule != null) {
          final normalizedGrid = _normalizeGrid(
            schedule.grid,
            periods,
          );

          schedulesByTerm[termOrder] = schedule.copyWith(
            grid: normalizedGrid,
          );

          gridByTerm[termOrder] = normalizedGrid;
        } else {
          gridByTerm[termOrder] = <String, List<double>>{};
        }
      }

      _loadedTermsKey = loadKey;

      emit(
        state.copyWith(
          isLoading: false,
          termsLoaded: true,
          additives: orderedAdditives,
          termAdditiveId: termAdditiveId,
          schedulesByTerm: schedulesByTerm,
          gridByTerm: gridByTerm,
          clearErrorMessage: true,
        ),
      );
    } catch (e) {
      _loadedTermsKey = null;

      emit(
        state.copyWith(
          isLoading: false,
          termsLoaded: true,
          additives: const <AdditivesData>[],
          termAdditiveId: const <int, String>{},
          schedulesByTerm: const <int, PhysicsFinanceData>{},
          gridByTerm: const <int, Map<String, List<double>>>{},
          errorMessage: 'Erro ao carregar planejamento físico-financeiro: $e',
        ),
      );
    }
  }

  void ensureTermGridRows({
    required int termOrder,
    required Iterable<String> itemIds,
    required int periods,
  }) {
    if (termOrder <= 0) return;
    if (periods <= 0) return;

    final Map<int, Map<String, List<double>>> gridByTerm =
    Map<int, Map<String, List<double>>>.from(state.gridByTerm);

    final Map<String, List<double>> termGrid = Map<String, List<double>>.from(
      gridByTerm[termOrder] ?? const <String, List<double>>{},
    );

    bool changed = false;

    for (final itemIdRaw in itemIds) {
      final itemId = itemIdRaw.trim();

      if (itemId.isEmpty) continue;

      final current = termGrid[itemId];

      if (current == null) {
        termGrid[itemId] = List<double>.filled(periods, 0.0);
        changed = true;
      } else if (current.length != periods) {
        termGrid[itemId] = _normalizeList(current, periods);
        changed = true;
      }
    }

    if (!changed) return;

    gridByTerm[termOrder] = termGrid;

    emit(
      state.copyWith(
        gridByTerm: gridByTerm,
      ),
    );
  }

  List<double> getPercentsForItem({
    required String itemId,
    required int termOrder,
  }) {
    final cleanItemId = itemId.trim();

    if (cleanItemId.isEmpty || termOrder <= 0) {
      return const <double>[];
    }

    return state.gridByTerm[termOrder]?[cleanItemId] ?? const <double>[];
  }

  Future<void> updatePercentForTerm({
    required String contractId,
    required int termOrder,
    required String itemId,
    required int colIndex,
    required double value,
    required List<int> periods,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanItemId = itemId.trim();

    if (cleanContractId.isEmpty) {
      emit(
        state.copyWith(
          isSaving: false,
          errorMessage:
          'contractId é obrigatório para salvar o planejamento físico-financeiro.',
        ),
      );
      return;
    }

    if (cleanItemId.isEmpty) return;

    if (termOrder <= 0) {
      emit(
        state.copyWith(
          isSaving: false,
          errorMessage: 'Termo inválido para salvar o planejamento.',
        ),
      );
      return;
    }

    if (periods.isEmpty) {
      emit(
        state.copyWith(
          isSaving: false,
          errorMessage:
          'Nenhum período informado para salvar o planejamento físico-financeiro.',
        ),
      );
      return;
    }

    try {
      _requireTenantId();
      _syncRepositoriesTenant();
    } catch (e) {
      emit(
        state.copyWith(
          isSaving: false,
          errorMessage: e.toString(),
        ),
      );
      return;
    }

    final additiveId = state.termAdditiveId[termOrder]?.trim();

    if (additiveId == null || additiveId.isEmpty) {
      emit(
        state.copyWith(
          isSaving: false,
          errorMessage:
          'Aditivo não encontrado para o termo $termOrder no contrato informado.',
        ),
      );
      return;
    }

    final Map<int, Map<String, List<double>>> gridByTerm =
    Map<int, Map<String, List<double>>>.from(state.gridByTerm);

    final Map<String, List<double>> termGrid = Map<String, List<double>>.from(
      gridByTerm[termOrder] ?? const <String, List<double>>{},
    );

    final List<double> row = List<double>.from(
      termGrid[cleanItemId] ?? List<double>.filled(periods.length, 0.0),
    );

    final normalized = _normalizeList(row, periods.length);

    if (colIndex < 0 || colIndex >= normalized.length) return;

    normalized[colIndex] = value;
    termGrid[cleanItemId] = normalized;
    gridByTerm[termOrder] = termGrid;

    emit(
      state.copyWith(
        gridByTerm: gridByTerm,
        isSaving: true,
        clearErrorMessage: true,
      ),
    );

    try {
      final schedule = PhysicsFinanceData(
        id: PhysicsFinanceData.docIdForTerm(termOrder),
        contractId: cleanContractId,
        additiveId: additiveId,
        termOrder: termOrder,
        periods: List<int>.from(periods),
        grid: termGrid,
      );

      await _repository.upsert(
        contractId: cleanContractId,
        additiveId: additiveId,
        schedule: schedule,
      );

      final Map<int, PhysicsFinanceData> schedulesByTerm =
      Map<int, PhysicsFinanceData>.from(state.schedulesByTerm);

      schedulesByTerm[termOrder] = schedule;

      emit(
        state.copyWith(
          isSaving: false,
          schedulesByTerm: schedulesByTerm,
          clearErrorMessage: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isSaving: false,
          errorMessage: 'Erro ao salvar planejamento físico-financeiro: $e',
        ),
      );
    }
  }

  void clear() {
    _loadedTermsKey = null;
    emit(PhysicsFinanceState.initial());
  }
}