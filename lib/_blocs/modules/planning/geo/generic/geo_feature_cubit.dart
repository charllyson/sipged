import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sipged/_blocs/modules/planning/geo/generic/geo_feature_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/generic/geo_feature_repository.dart';
import 'package:sipged/_blocs/modules/planning/geo/generic/geo_feature_state.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data.dart';

class GeoFeatureCubit extends Cubit<GeoFeatureState> {
  GeoFeatureCubit({
    GeoFeatureRepository? repository,
  })  : _repository = repository ?? GeoFeatureRepository(),
        super(const GeoFeatureState());

  final GeoFeatureRepository _repository;

  Future<void> ensureLayerLoaded(
      GeoLayersData layer, {
        bool force = false,
      }) async {
    final path = (layer.effectiveCollectionPath ?? '').trim();
    if (path.isEmpty || layer.isGroup) return;

    final alreadyLoaded = state.loadedByLayer[layer.id] == true;
    final isLoading = state.loadingByLayer[layer.id] == true;

    if (!force && (alreadyLoaded || isLoading)) return;

    final loadingMap = Map<String, bool>.from(state.loadingByLayer);
    loadingMap[layer.id] = true;

    emit(
      state.copyWith(
        loadingByLayer: loadingMap,
        clearError: true,
      ),
    );

    try {
      final features = await _repository.loadFeatures(
        layerId: layer.id,
        collectionPath: path,
      );

      final nextFeatures =
      Map<String, List<GeoFeatureData>>.from(state.featuresByLayer);
      nextFeatures[layer.id] = features;

      final nextLoading = Map<String, bool>.from(state.loadingByLayer);
      nextLoading[layer.id] = false;

      final nextLoaded = Map<String, bool>.from(state.loadedByLayer);
      nextLoaded[layer.id] = true;

      final currentSelection = state.selected;
      final shouldClearSelection = currentSelection != null &&
          currentSelection.layerId == layer.id &&
          !features.any((f) => f.selectionKey == currentSelection.feature.selectionKey);

      emit(
        state.copyWith(
          featuresByLayer: nextFeatures,
          loadingByLayer: nextLoading,
          loadedByLayer: nextLoaded,
          clearSelection: shouldClearSelection,
          clearError: true,
        ),
      );
    } catch (e) {
      final nextLoading = Map<String, bool>.from(state.loadingByLayer);
      nextLoading[layer.id] = false;

      emit(
        state.copyWith(
          loadingByLayer: nextLoading,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> reloadLayer(GeoLayersData layer) async {
    await ensureLayerLoaded(layer, force: true);
  }

  void unloadLayer(String layerId) {
    final nextFeatures =
    Map<String, List<GeoFeatureData>>.from(state.featuresByLayer);
    nextFeatures.remove(layerId);

    final nextLoaded = Map<String, bool>.from(state.loadedByLayer);
    nextLoaded.remove(layerId);

    final nextLoading = Map<String, bool>.from(state.loadingByLayer);
    nextLoading.remove(layerId);

    final clearSelection = state.selected?.layerId == layerId;

    emit(
      state.copyWith(
        featuresByLayer: nextFeatures,
        loadedByLayer: nextLoaded,
        loadingByLayer: nextLoading,
        clearSelection: clearSelection,
        clearError: true,
      ),
    );
  }

  void clearSelection() {
    emit(
      state.copyWith(
        clearSelection: true,
        clearError: true,
      ),
    );
  }

  void selectFeature({
    required String layerId,
    required GeoFeatureData feature,
  }) {
    emit(
      state.copyWith(
        selected: GenericGeoLayerSelection(
          layerId: layerId,
          feature: feature,
        ),
        clearError: true,
      ),
    );
  }
}