// lib/_blocs/actives/oacs/active_oacs_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';

import 'active_oacs_data.dart';
import 'active_oacs_repository.dart';
import 'active_oacs_state.dart';

class ActiveOacsCubit extends Cubit<ActiveOacsState> {
  final ActiveOacsRepository _repo;

  ActiveOacsCubit({ActiveOacsRepository? repository})
      : _repo = repository ?? ActiveOacsRepository(),
        super(ActiveOacsState());

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
      loadStatus: ActiveOacsLoadStatus.loading,
      error: null,
    ));

    try {
      final list = await _repo.fetchAll();
      final regions = _buildRegionLabelsFromList(list);

      emit(state.copyWith(
        initialized: setInitialized ? true : state.initialized,
        all: list,
        regionLabels: regions,
        loadStatus: ActiveOacsLoadStatus.success,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        loadStatus: ActiveOacsLoadStatus.failure,
        error: e.toString(),
      ));
    }
  }

  // ---------------------------------------------------------------------------
  // REGIÕES vindas da própria lista de OACs
  // ---------------------------------------------------------------------------

  List<String> _buildRegionLabelsFromList(List<ActiveOacsData> source) {
    final Map<String, String> map = {};

    for (final o in source) {
      final raw = (o.region ?? '').trim();
      if (raw.isEmpty) continue;

      final key = raw.toUpperCase();
      map.putIfAbsent(key, () => raw);
    }

    final labels = map.values.toList();
    labels.sort((a, b) => a.toUpperCase().compareTo(b.toUpperCase()));
    return labels;
  }

  ActiveOacsState _withRebuiltRegions(List<ActiveOacsData> all) {
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
      form: ActiveOacsData.fromData(selected),
    ));
  }

  void clearSelection() {
    emit(state.copyWith(
      selectedIndex: null,
      form: ActiveOacsData(),
    ));
  }

  void patchForm(ActiveOacsData data) {
    emit(state.copyWith(form: data));
  }

  // ---------------------------------------------------------------------------
  // Upsert / Delete
  // ---------------------------------------------------------------------------

  Future<void> upsert(ActiveOacsData data) async {
    emit(state.copyWith(saving: true, error: null));

    try {
      final saved = await _repo.upsert(data);

      final all = List<ActiveOacsData>.from(state.all);
      final idx = all.indexWhere((a) => a.id == saved.id);

      if (idx == -1) {
        all.add(saved);
      } else {
        all[idx] = saved;
      }

      final nextState = _withRebuiltRegions(all).copyWith(
        form: ActiveOacsData(),
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

      final all = List<ActiveOacsData>.from(state.all)
        ..removeWhere((a) => a.id == id);

      final nextState = _withRebuiltRegions(all).copyWith(
        form: ActiveOacsData(),
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
        form: isFormOfDeleted ? ActiveOacsData() : state.form,
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
