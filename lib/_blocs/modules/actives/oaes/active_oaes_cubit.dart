// lib/_blocs/modules/actives/oaes/active_oaes_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';

import 'active_oaes_data.dart';
import 'active_oaes_repository.dart';
import 'active_oaes_state.dart';

class ActiveOaesCubit extends Cubit<ActiveOaesState> {
  final ActiveOaesRepository _repo;

  ActiveOaesCubit({ActiveOaesRepository? repository})
      : _repo = repository ?? ActiveOaesRepository(),
        super(ActiveOaesState());

  // ---------------------------------------------------------------------------
  // Loaders
  // ---------------------------------------------------------------------------

  Future<void> warmup() async {
    if (state.initialized) return;
    await _loadAll(setInitialized: true);
  }

  Future<void> refresh() async {
    await _loadAll(setInitialized: false);
  }

  Future<void> _loadAll({required bool setInitialized}) async {
    emit(state.copyWith(
      loadStatus: ActiveOaesLoadStatus.loading,
      error: null,
    ));

    try {
      final list = await _repo.fetchAll();
      final regions = _buildRegionLabelsFromList(list);

      emit(state.copyWith(
        initialized: setInitialized ? true : state.initialized,
        all: list,
        regionLabels: regions,
        loadStatus: ActiveOaesLoadStatus.success,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        loadStatus: ActiveOaesLoadStatus.failure,
        error: e.toString(),
      ));
    }
  }

  // ---------------------------------------------------------------------------
  // REGIÕES vindas da própria lista de OAEs
  // ---------------------------------------------------------------------------

  /// Gera a lista de rótulos de região a partir do campo `ActiveOaesData.region`.
  ///
  /// - Ignora null/vazio
  /// - Remove duplicados (case-insensitive)
  /// - Ordena alfabeticamente (ignorando maiúsc/minúsc)
  List<String> _buildRegionLabelsFromList(List<ActiveOaesData> source) {
    final Map<String, String> map = {};

    for (final o in source) {
      final raw = (o.region ?? '').trim();
      if (raw.isEmpty) continue;

      final key = raw.toUpperCase();
      // preserva o primeiro texto encontrado para exibição
      map.putIfAbsent(key, () => raw);
    }

    final labels = map.values.toList();
    labels.sort((a, b) => a.toUpperCase().compareTo(b.toUpperCase()));
    return labels;
  }

  // Recalcula regionLabels com base na lista atual `all`
  ActiveOaesState _withRebuiltRegions(List<ActiveOaesData> all) {
    final regions = _buildRegionLabelsFromList(all);
    return state.copyWith(
      all: all,
      regionLabels: regions,
    );
  }

  // ---------------------------------------------------------------------------
  // Seleção / Form
  // ---------------------------------------------------------------------------

  void selectByIndex(int index) {
    if (index < 0 || index >= state.all.length) return;
    final selected = state.all[index];

    emit(state.copyWith(
      selectedIndex: index,
      form: ActiveOaesData.fromData(selected),
    ));
  }

  void clearSelection() {
    emit(state.copyWith(
      selectedIndex: null,
      form: ActiveOaesData(),
    ));
  }

  void patchForm(ActiveOaesData data) {
    emit(state.copyWith(form: data));
  }

  // ---------------------------------------------------------------------------
  // Upsert / Delete
  // ---------------------------------------------------------------------------

  Future<void> upsert(ActiveOaesData data) async {
    emit(state.copyWith(saving: true, error: null));

    try {
      final saved = await _repo.upsert(data);

      final all = List<ActiveOaesData>.from(state.all);
      final idx = all.indexWhere((a) => a.id == saved.id);

      if (idx == -1) {
        all.add(saved);
      } else {
        all[idx] = saved;
      }

      final nextState = _withRebuiltRegions(all).copyWith(
        form: ActiveOaesData(),
        selectedIndex: null,
        saving: false,
        error: null,
      );

      emit(nextState);
    } catch (e) {
      emit(state.copyWith(
        saving: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> deleteById(String id) async {
    emit(state.copyWith(saving: true, error: null));

    try {
      await _repo.deleteById(id);

      final all = List<ActiveOaesData>.from(state.all)
        ..removeWhere((a) => a.id == id);

      final nextState = _withRebuiltRegions(all).copyWith(
        form: ActiveOaesData(),
        selectedIndex: null,
        saving: false,
        error: null,
      );

      emit(nextState);
    } catch (e) {
      emit(state.copyWith(
        saving: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> delete(String id) async {
    if (id.isEmpty) return;

    emit(state.copyWith(saving: true, error: null));

    try {
      await _repo.deleteById(id);

      final updatedList = state.all.where((e) => e.id != id).toList();
      final isFormOfDeleted = state.form.id == id;

      final nextState = _withRebuiltRegions(updatedList).copyWith(
        saving: false,
        selectedIndex: null,
        form: isFormOfDeleted ? ActiveOaesData() : state.form,
      );

      emit(nextState);
    } catch (e) {
      emit(state.copyWith(
        saving: false,
        error: e.toString(),
      ));
    }
  }

  // ---------------------------------------------------------------------------
  // Filtros (pie / região)
  // ---------------------------------------------------------------------------

  void setPieFilter(int? pieIndex) {
    emit(state.copyWith(selectedPieIndexFilter: pieIndex));
  }

  void setRegionFilter(String? regionLabel) {
    emit(state.copyWith(selectedRegionFilter: regionLabel));
  }
}
