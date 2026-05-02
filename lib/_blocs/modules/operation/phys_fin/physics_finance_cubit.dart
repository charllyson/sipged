// lib/_blocs/modules/operation/phys_fin/physics_finance_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/additives/additives_data.dart';
import 'package:sipged/_blocs/modules/contracts/additives/additives_repository.dart';

import 'physics_finance_data.dart';
import 'physics_finance_repository.dart';
import 'physics_finance_state.dart';

class PhysicsFinanceCubit extends Cubit<PhysicsFinanceState> {
  PhysicsFinanceCubit({
    required PhysicsFinanceRepository repository,
    AdditivesRepository? additivesRepository,
  })  : _repository = repository,
        _additivesRepository = additivesRepository ?? AdditivesRepository(),
        super(PhysicsFinanceState.initial());

  final PhysicsFinanceRepository _repository;
  final AdditivesRepository _additivesRepository;

  List<double> _normalizeList(
      List<double> source,
      int periods,
      ) {
    if (source.length == periods) return List<double>.from(source);

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

    source.forEach((key, value) {
      output[key] = _normalizeList(value, periods);
    });

    return output;
  }

  Future<void> loadTerms({
    required String contractId,
    required int periods,
    bool forceReload = false,
  }) async {
    if (contractId.isEmpty) return;

    if (state.termsLoaded && !forceReload) return;

    emit(
      state.copyWith(
        isLoading: true,
        clearErrorMessage: true,
      ),
    );

    try {
      final additives = await _additivesRepository.ensureForContract(contractId);

      final orderedAdditives = List<AdditivesData>.from(additives)
        ..sort(
              (a, b) => (a.additiveOrder ?? 0).compareTo(b.additiveOrder ?? 0),
        );

      final Map<int, String> termAdditiveId = <int, String>{};

      for (final additive in orderedAdditives) {
        final int order = additive.additiveOrder ?? 0;
        final String? id = additive.id;

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
        final String additiveId = entry.value;

        final schedule = await _repository.get(
          contractId: contractId,
          additiveId: additiveId,
          termOrder: termOrder,
        );

        if (schedule != null) {
          schedulesByTerm[termOrder] = schedule;
          gridByTerm[termOrder] = _normalizeGrid(schedule.grid, periods);
        } else {
          gridByTerm[termOrder] = <String, List<double>>{};
        }
      }

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
    final Map<int, Map<String, List<double>>> gridByTerm =
    Map<int, Map<String, List<double>>>.from(state.gridByTerm);

    final Map<String, List<double>> termGrid =
    Map<String, List<double>>.from(
      gridByTerm[termOrder] ?? const <String, List<double>>{},
    );

    bool changed = false;

    for (final itemId in itemIds) {
      final List<double>? current = termGrid[itemId];

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
    return state.gridByTerm[termOrder]?[itemId] ?? const <double>[];
  }

  Future<void> updatePercentForTerm({
    required String contractId,
    required int termOrder,
    required String itemId,
    required int colIndex,
    required double value,
    required List<int> periods,
  }) async {
    final String? additiveId = state.termAdditiveId[termOrder];

    if (contractId.isEmpty || additiveId == null || additiveId.isEmpty) {
      return;
    }

    final Map<int, Map<String, List<double>>> gridByTerm =
    Map<int, Map<String, List<double>>>.from(state.gridByTerm);

    final Map<String, List<double>> termGrid =
    Map<String, List<double>>.from(
      gridByTerm[termOrder] ?? const <String, List<double>>{},
    );

    final List<double> row = List<double>.from(
      termGrid[itemId] ?? List<double>.filled(periods.length, 0.0),
    );

    final List<double> normalized = _normalizeList(row, periods.length);

    if (colIndex < 0 || colIndex >= normalized.length) return;

    normalized[colIndex] = value;
    termGrid[itemId] = normalized;
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
        contractId: contractId,
        additiveId: additiveId,
        termOrder: termOrder,
        periods: periods,
        grid: termGrid,
      );

      await _repository.upsert(
        contractId: contractId,
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
    emit(PhysicsFinanceState.initial());
  }
}