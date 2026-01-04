// lib/_blocs/actives/railway/active_railways_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';

import 'active_railway_data.dart';
import 'active_railways_repository.dart';
import 'active_railways_state.dart';

class ActiveRailwaysCubit extends Cubit<ActiveRailwaysState> {
  final ActiveRailwaysRepository _repo;

  ActiveRailwaysCubit({ActiveRailwaysRepository? repository})
      : _repo = repository ?? ActiveRailwaysRepository(),
        super(const ActiveRailwaysState());

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
      loadStatus: ActiveRailwaysLoadStatus.loading,
      error: null,
    ));

    try {
      final list = await _repo.fetchAll();
      final labels = _buildRegionLabels(list);

      emit(
        state.copyWith(
          initialized: setInitialized ? true : state.initialized,
          all: list,
          regionLabels: labels,
          loadStatus: ActiveRailwaysLoadStatus.success,
          error: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          loadStatus: ActiveRailwaysLoadStatus.failure,
          error: e.toString(),
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Regiões vindas dos dados (município/UF/nome)
  // ---------------------------------------------------------------------------

  /// Gera a lista de labels de regiões para o gráfico de barras
  /// a partir de `ActiveRailwayData.municipio` (fallback: `uf` / `nome`).
  ///
  /// Usa a canonização de `ActiveRailwayData.canonRegion` para
  /// evitar duplicados com acentos/letras diferentes, mas mantém
  /// um rótulo "bonito" para exibição.
  List<String> _buildRegionLabels(List<ActiveRailwayData> list) {
    // canon -> labelParaMostrar
    final Map<String, String> displayByCanon = {};

    for (final fer in list) {
      final raw =
      (fer.municipio ?? fer.uf ?? fer.nome ?? '').toString().trim();
      if (raw.isEmpty) continue;

      // canonização só pra chave (remove acento, normaliza)
      final canon = ActiveRailwayData.canonRegion(raw, const []);
      if (canon.isEmpty) continue;

      displayByCanon.putIfAbsent(canon, () => raw);
    }

    final labels = displayByCanon.values.toList();
    labels.sort((a, b) => a.toUpperCase().compareTo(b.toUpperCase()));
    return labels;
  }

  // ---------------------------------------------------------------------------
  // Seleção / Filtros / Zoom
  // ---------------------------------------------------------------------------

  void selectPolyline(String? id) {
    emit(state.copyWith(selectedPolylineId: id));
  }

  void setRegionFilter(String? region) {
    emit(state.copyWith(selectedRegionFilter: region));
  }

  void setStatusFilter(String? statusCode) {
    emit(state.copyWith(selectedStatusFilter: statusCode));
  }

  void setPieFilter(int? pieIndex) {
    emit(state.copyWith(selectedPieIndexFilter: pieIndex));
  }

  void setMapZoom(double zoom) {
    final z = double.parse(zoom.toStringAsFixed(2));
    if ((state.mapZoom - z).abs() >= 0.05) {
      emit(state.copyWith(mapZoom: z));
    }
  }

  // ---------------------------------------------------------------------------
  // Upsert / Delete / Import (delegando para o Repository)
  // ---------------------------------------------------------------------------

  Future<void> upsert(ActiveRailwayData data) async {
    emit(state.copyWith(savingOrImporting: true, error: null));
    try {
      final saved = await _repo.upsert(data);
      final list = List<ActiveRailwayData>.from(state.all);
      final idx = list.indexWhere((e) => e.id == saved.id);
      if (idx == -1) {
        list.add(saved);
      } else {
        list[idx] = saved;
      }

      final labels = _buildRegionLabels(list);

      emit(state.copyWith(
        all: list,
        regionLabels: labels,
        savingOrImporting: false,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        savingOrImporting: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> deleteById(String id) async {
    emit(state.copyWith(savingOrImporting: true, error: null));
    try {
      await _repo.deleteById(id);
      final filtered = [...state.all]..removeWhere((r) => r.id == id);
      final labels = _buildRegionLabels(filtered);

      emit(state.copyWith(
        all: filtered,
        regionLabels: labels,
        savingOrImporting: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        savingOrImporting: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> importBatch({
    required List<Map<String, dynamic>> linhasPrincipais,
    required List<Map<String, dynamic>> geometrias,
  }) async {
    emit(state.copyWith(savingOrImporting: true, error: null));
    try {
      await _repo.importBatch(
        linhasPrincipais: linhasPrincipais,
        geometrias: geometrias,
      );
      final list = await _repo.fetchAll();
      final labels = _buildRegionLabels(list);

      emit(state.copyWith(
        all: list,
        regionLabels: labels,
        savingOrImporting: false,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        savingOrImporting: false,
        error: e.toString(),
      ));
    }
  }
}
