// lib/_blocs/actives/roads/active_roads_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';

import 'active_roads_state.dart';
import 'active_roads_data.dart';
import 'active_roads_repository.dart';
import 'package:siged/_blocs/system/setup/setup_data.dart';

class ActiveRoadsCubit extends Cubit<ActiveRoadsState> {
  final ActiveRoadsRepository _repo;

  ActiveRoadsCubit({ActiveRoadsRepository? repository})
      : _repo = repository ?? ActiveRoadsRepository(),
        super(const ActiveRoadsState());

  // ---------------------------------------------------------------------------
  // Configs "globais" da visualização
  // ---------------------------------------------------------------------------

  /// Zoom máximo em que ainda usamos cluster de labels.
  static const double clusterUntilZoom = 12.0;

  /// Se deve usar cluster de marcadores para o zoom informado.
  bool shouldUseCluster(double zoom) => zoom < clusterUntilZoom;

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
      loadStatus: ActiveRoadsLoadStatus.loading,
      error: null,
    ));
    try {
      final list = await _repo.fetchAll();

      // 🔹 labels de região vindos dos próprios dados (regional / metadata['regional'])
      final regionLabels = _buildRegionLabelsFromData(list);

      emit(
        state.copyWith(
          initialized: setInitialized ? true : state.initialized,
          all: list,
          regionLabels: regionLabels,
          loadStatus: ActiveRoadsLoadStatus.success,
          error: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          loadStatus: ActiveRoadsLoadStatus.failure,
          error: e.toString(),
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers internos
  // ---------------------------------------------------------------------------

  List<String> _buildRegionLabelsFromData(List<ActiveRoadsData> list) {
    final labels = list
        .map(
          (r) => (r.regional ?? r.metadata?['regional'] ?? '')
          .toString()
          .trim(),
    )
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toUpperCase().compareTo(b.toUpperCase()));

    return labels;
  }

  /// Lookup simples por id (para tooltips, detalhes, etc.)
  ActiveRoadsData? findById(String id) {
    for (final r in state.all) {
      if (r.id == id) return r;
    }
    return null;
  }

  /// Converte a tag (Object?) usada no mapa em um ActiveRoadsData.
  ActiveRoadsData? findByPolylineTag(Object? tag) {
    final id = tag?.toString();
    if (id == null) return null;
    return findById(id);
  }

  /// Título padrão do tooltip de rodovia.
  String tooltipTitle(ActiveRoadsData road) {
    final acr = road.acronym ?? '--';
    final cod = road.roadCode ?? '--';
    return 'Rodovia: AL-$acr ($cod)';
  }

  /// Subtítulo padrão do tooltip de rodovia.
  String tooltipSubtitle(ActiveRoadsData road) {
    final ini = road.initialSegment ?? '--';
    final fim = road.finalSegment ?? '--';
    final ext = road.extension?.toStringAsFixed(2) ?? '--';
    return 'Trecho: $ini / $fim, $ext km de extensão';
  }

  // ---------------------------------------------------------------------------
  // Integração com Setup (REGIÕES) — OPCIONAL
  // ---------------------------------------------------------------------------

  /// Atualiza a lista de rótulos de regiões a partir do Setup (company/órgão atual).
  ///
  /// Opcional: caso queira forçar usar labels oficiais do Setup.
  void syncRegionsFromSetup(List<SetupData> setupRegions) {
    final labels = setupRegions
        .map((r) => (r.regionName ?? r.label).trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toUpperCase().compareTo(b.toUpperCase()));

    emit(state.copyWith(regionLabels: labels));
  }

  // ---------------------------------------------------------------------------
  // Seleção / Filtros
  // ---------------------------------------------------------------------------

  void selectPolyline(String? id) {
    emit(state.copyWith(selectedPolylineId: id));
  }

  void clearPolylineSelection() {
    emit(state.copyWith(selectedPolylineId: null));
  }

  void setRegionFilter(String? region) {
    emit(state.copyWith(selectedRegionFilter: region));
  }

  void setSurfaceFilter(String? surfaceCode) {
    emit(state.copyWith(selectedSurfaceFilter: surfaceCode));
  }

  void setPieFilter(int? pieIndex) {
    emit(state.copyWith(selectedPieIndexFilter: pieIndex));
  }

  // ---------------------------------------------------------------------------
  // CRUD / Import
  // ---------------------------------------------------------------------------

  Future<void> upsert(ActiveRoadsData data) async {
    emit(state.copyWith(savingOrImporting: true, error: null));
    try {
      final saved = await _repo.upsert(data);

      final list = List<ActiveRoadsData>.from(state.all);
      final idx = list.indexWhere((r) => r.id == saved.id);
      if (idx == -1) {
        list.add(saved);
      } else {
        list[idx] = saved;
      }

      // reordena como você fazia no _fetchAllNormalized
      list.sort((a, b) {
        final aKey = '${a.acronym ?? ''}_${a.initialKm ?? 0}';
        final bKey = '${b.acronym ?? ''}_${b.initialKm ?? 0}';
        return aKey.compareTo(bKey);
      });

      // 🔹 recalcula labels de região
      final regionLabels = _buildRegionLabelsFromData(list);

      emit(state.copyWith(
        all: list,
        regionLabels: regionLabels,
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

      // recalcula labels após delete
      final regionLabels = _buildRegionLabelsFromData(filtered);

      emit(state.copyWith(
        all: filtered,
        regionLabels: regionLabels,
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
    required List<Map<String, dynamic>> subcolecoes,
  }) async {
    emit(state.copyWith(savingOrImporting: true, error: null));
    try {
      await _repo.importarRodoviasComCoordenadas(
        linhasPrincipais: linhasPrincipais,
        subcolecoes: subcolecoes,
      );
      final list = await _repo.fetchAll();

      // mesma ordenação
      list.sort((a, b) {
        final aKey = '${a.acronym ?? ''}_${a.initialKm ?? 0}';
        final bKey = '${b.acronym ?? ''}_${b.initialKm ?? 0}';
        return aKey.compareTo(bKey);
      });

      // 🔹 recalcula labels
      final regionLabels = _buildRegionLabelsFromData(list);

      emit(state.copyWith(
        all: list,
        regionLabels: regionLabels,
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
