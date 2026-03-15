import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/geo_feature_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/geo_feature_repository.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/geo_feature_state.dart';
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

      final nextAvailableFields =
      Map<String, List<String>>.from(state.availableFieldsByLayer);
      nextAvailableFields[layer.id] = _extractFieldsFromFeatures(features);

      final currentSelection = state.selected;
      final shouldClearSelection = currentSelection != null &&
          currentSelection.layerId == layer.id &&
          !features.any(
                (f) => f.selectionKey == currentSelection.feature.selectionKey,
          );

      emit(
        state.copyWith(
          featuresByLayer: nextFeatures,
          loadingByLayer: nextLoading,
          loadedByLayer: nextLoaded,
          availableFieldsByLayer: nextAvailableFields,
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

  Future<List<String>> ensureLayerFieldNames(
      GeoLayersData layer, {
        bool force = false,
      }) async {
    final path = (layer.effectiveCollectionPath ?? '').trim();
    if (path.isEmpty || layer.isGroup) return const [];

    final cached = state.availableFieldsByLayer[layer.id];
    if (!force && cached != null && cached.isNotEmpty) {
      return cached;
    }

    try {
      final fieldNames = await _repository.loadFieldNames(
        collectionPath: path,
      );

      final nextFields =
      Map<String, List<String>>.from(state.availableFieldsByLayer);
      nextFields[layer.id] = fieldNames;

      emit(
        state.copyWith(
          availableFieldsByLayer: nextFields,
          clearError: true,
        ),
      );

      return fieldNames;
    } catch (e) {
      emit(
        state.copyWith(
          error: e.toString(),
        ),
      );
      return const [];
    }
  }

  Future<void> reloadLayer(GeoLayersData layer) async {
    await ensureLayerLoaded(layer, force: true);
  }

  Future<void> addPointFeaturesBatch({
    required GeoLayersData layer,
    required List<LatLng> points,
    Map<String, dynamic> commonProperties = const {},
  }) async {
    final path = (layer.effectiveCollectionPath ?? '').trim();
    if (path.isEmpty || layer.isGroup || points.isEmpty) return;

    final loadingMap = Map<String, bool>.from(state.loadingByLayer);
    loadingMap[layer.id] = true;

    emit(
      state.copyWith(
        loadingByLayer: loadingMap,
        clearError: true,
      ),
    );

    try {
      await _repository.addPointFeaturesBatch(
        layerId: layer.id,
        collectionPath: path,
        points: points,
        commonProperties: commonProperties,
      );

      await ensureLayerLoaded(layer, force: true);
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

  Future<void> addLineFeaturesBatch({
    required GeoLayersData layer,
    required List<List<LatLng>> lines,
    Map<String, dynamic> commonProperties = const {},
  }) async {
    final path = (layer.effectiveCollectionPath ?? '').trim();
    final validLines = lines.where((e) => e.length >= 2).toList(growable: false);

    if (path.isEmpty || layer.isGroup || validLines.isEmpty) return;

    final loadingMap = Map<String, bool>.from(state.loadingByLayer);
    loadingMap[layer.id] = true;

    emit(
      state.copyWith(
        loadingByLayer: loadingMap,
        clearError: true,
      ),
    );

    try {
      await _repository.addLineFeaturesBatch(
        layerId: layer.id,
        collectionPath: path,
        lines: validLines,
        commonProperties: commonProperties,
      );

      await ensureLayerLoaded(layer, force: true);
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

  Future<void> addPolygonFeaturesBatch({
    required GeoLayersData layer,
    required List<List<LatLng>> polygons,
    Map<String, dynamic> commonProperties = const {},
  }) async {
    final path = (layer.effectiveCollectionPath ?? '').trim();
    final validPolygons =
    polygons.where((e) => e.length >= 3).toList(growable: false);

    if (path.isEmpty || layer.isGroup || validPolygons.isEmpty) return;

    final loadingMap = Map<String, bool>.from(state.loadingByLayer);
    loadingMap[layer.id] = true;

    emit(
      state.copyWith(
        loadingByLayer: loadingMap,
        clearError: true,
      ),
    );

    try {
      await _repository.addPolygonFeaturesBatch(
        layerId: layer.id,
        collectionPath: path,
        polygons: validPolygons,
        commonProperties: commonProperties,
      );

      await ensureLayerLoaded(layer, force: true);
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

  void unloadLayer(String layerId) {
    final nextFeatures =
    Map<String, List<GeoFeatureData>>.from(state.featuresByLayer);
    nextFeatures.remove(layerId);

    final nextLoaded = Map<String, bool>.from(state.loadedByLayer);
    nextLoaded.remove(layerId);

    final nextLoading = Map<String, bool>.from(state.loadingByLayer);
    nextLoading.remove(layerId);

    final nextAvailableFields =
    Map<String, List<String>>.from(state.availableFieldsByLayer);
    nextAvailableFields.remove(layerId);

    final clearSelection = state.selected?.layerId == layerId;

    emit(
      state.copyWith(
        featuresByLayer: nextFeatures,
        loadedByLayer: nextLoaded,
        loadingByLayer: nextLoading,
        availableFieldsByLayer: nextAvailableFields,
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

  List<String> _extractFieldsFromFeatures(List<GeoFeatureData> features) {
    final keys = <String>{};

    for (final feature in features) {
      keys.addAll(feature.properties.keys);
    }

    final result = keys.toList()..sort();
    return result;
  }
}