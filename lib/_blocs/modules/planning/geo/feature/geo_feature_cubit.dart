import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';

import 'geo_feature_data.dart';
import 'geo_feature_repository.dart';
import 'geo_feature_state.dart';
import '../layer/geo_layers_data.dart';

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
                (feature) =>
            feature.selectionKey == currentSelection.feature.selectionKey,
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

  Future<void> startImport(String collectionPath) async {
    emit(
      state.copyWith(
        importStatus: GeoFeatureImportStatus.pickingFile,
        importCollectionPath: collectionPath,
        importFeatures: const [],
        importColumns: const [],
        importFieldMapping: const {},
        importProgress: 0.0,
        clearError: true,
      ),
    );

    try {
      final raw = await _repository.pickAndParseRawFeatures();
      final result = _repository.buildImportedFeatures(raw);

      emit(
        state.copyWith(
          importStatus: GeoFeatureImportStatus.previewReady,
          importFeatures: result.$1,
          importColumns: result.$2,
          importProgress: 0.0,
          clearError: true,
        ),
      );
    } catch (e) {
      _emitFailure(e);
    }
  }

  Future<void> startFromFirestore(String collectionPath) async {
    emit(
      state.copyWith(
        importStatus: GeoFeatureImportStatus.loadingFirestore,
        importCollectionPath: collectionPath,
        importFeatures: const [],
        importColumns: const [],
        importFieldMapping: const {},
        importProgress: 0.0,
        clearError: true,
      ),
    );

    try {
      final result = await _repository.loadFromFirestoreAsImportedFeatures(
        collectionPath: collectionPath,
        limit: 1500,
      );

      emit(
        state.copyWith(
          importStatus: GeoFeatureImportStatus.previewReady,
          importFeatures: result.$1,
          importColumns: result.$2,
          importProgress: 0.0,
          clearError: true,
        ),
      );
    } catch (e) {
      _emitFailure(e);
    }
  }

  void clearImportSession() {
    emit(
      state.copyWith(
        clearImportSession: true,
        clearError: true,
      ),
    );
  }

  void toggleRowSelection(int index, bool selected) {
    if (index < 0 || index >= state.importFeatures.length) return;

    final list = [...state.importFeatures];
    list[index] = list[index].copyWith(selected: selected);

    emit(
      state.copyWith(
        importFeatures: list,
        clearError: true,
      ),
    );
  }

  void toggleColumnSelection(int index, bool selected) {
    if (index < 0 || index >= state.importColumns.length) return;

    final cols = [...state.importColumns];
    cols[index] = cols[index].copyWith(selected: selected);

    emit(
      state.copyWith(
        importColumns: cols,
        clearError: true,
      ),
    );
  }

  void renameColumn(int index, String newName) {
    if (index < 0 || index >= state.importColumns.length) return;

    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;

    final cols = [...state.importColumns];
    final oldName = cols[index].name;

    if (trimmed == oldName) return;

    final exists = cols.any(
          (c) => c.name.toLowerCase() == trimmed.toLowerCase() && c.name != oldName,
    );

    if (exists) {
      emit(
        state.copyWith(
          importStatus: GeoFeatureImportStatus.failure,
          error: 'Já existe uma coluna com o nome "$trimmed".',
        ),
      );
      return;
    }

    cols[index] = cols[index].copyWith(name: trimmed);

    final feats = state.importFeatures.map((feature) {
      if (!feature.editedProperties.containsKey(oldName)) return feature;

      final newProps = Map<String, dynamic>.from(feature.editedProperties);
      final value = newProps.remove(oldName);
      newProps[trimmed] = value;

      final newTypes = Map<String, TypeFieldGeoJson>.from(feature.columnTypes);
      final oldType = newTypes.remove(oldName);
      if (oldType != null) {
        newTypes[trimmed] = oldType;
      }

      return feature.copyWith(
        editedProperties: newProps,
        columnTypes: newTypes,
      );
    }).toList(growable: false);

    final newMapping = Map<String, String>.from(state.importFieldMapping)
      ..updateAll((_, value) => value == oldName ? trimmed : value);

    emit(
      state.copyWith(
        importColumns: cols,
        importFeatures: feats,
        importFieldMapping: newMapping,
        clearError: true,
      ),
    );
  }

  void changeColumnType(int index, TypeFieldGeoJson newType) {
    if (index < 0 || index >= state.importColumns.length) return;

    final cols = [...state.importColumns];
    final colName = cols[index].name;
    cols[index] = cols[index].copyWith(type: newType);

    final feats = state.importFeatures.map((feature) {
      final newTypes = Map<String, TypeFieldGeoJson>.from(feature.columnTypes);
      newTypes[colName] = newType;
      return feature.copyWith(columnTypes: newTypes);
    }).toList(growable: false);

    emit(
      state.copyWith(
        importColumns: cols,
        importFeatures: feats,
        clearError: true,
      ),
    );
  }

  void setFieldMapping(String targetField, String? sourceColumn) {
    final map = Map<String, String>.from(state.importFieldMapping);

    final value = sourceColumn?.trim();
    if (value == null || value.isEmpty) {
      map.remove(targetField);
    } else {
      map[targetField] = value;
    }

    emit(
      state.copyWith(
        importFieldMapping: map,
        clearError: true,
      ),
    );
  }

  Future<void> save() => saveImportedFeatures();

  Future<void> saveImportedFeatures() async {
    final path = state.importCollectionPath?.trim();
    if (path == null || path.isEmpty) return;

    emit(
      state.copyWith(
        importStatus: GeoFeatureImportStatus.saving,
        importProgress: 0.0,
        clearError: true,
      ),
    );

    try {
      final selectedCols =
      state.importColumns.where((c) => c.selected).toList(growable: false);

      if (selectedCols.isEmpty) {
        emit(
          state.copyWith(
            importStatus: GeoFeatureImportStatus.failure,
            error: 'Nenhuma coluna selecionada para salvar.',
          ),
        );
        return;
      }

      final selectedRows =
      state.importFeatures.where((f) => f.selected).toList(growable: false);

      if (selectedRows.isEmpty) {
        emit(
          state.copyWith(
            importStatus: GeoFeatureImportStatus.failure,
            error: 'Nenhuma linha selecionada para salvar.',
          ),
        );
        return;
      }

      final selectedColNames =
      selectedCols.map((c) => c.name).toList(growable: false);

      final typeByColumn = {
        for (final col in selectedCols) col.name: col.type,
      };

      final prepared = selectedRows.map((feature) {
        final newProps = <String, dynamic>{};

        for (final colName in selectedColNames) {
          final rawValue = feature.editedProperties[colName];
          final type = typeByColumn[colName] ?? TypeFieldGeoJson.string;
          newProps[colName] = _castValue(rawValue, type);
        }

        return feature.copyWith(
          editedProperties: newProps,
          columnTypes: {
            for (final colName in selectedColNames)
              colName: typeByColumn[colName] ?? TypeFieldGeoJson.string,
          },
        );
      }).toList(growable: false);

      await _repository.saveFeaturesToCollection(
        collectionPath: path,
        features: prepared,
        onProgress: (progress) {
          emit(state.copyWith(importProgress: progress));
        },
      );

      emit(
        state.copyWith(
          importStatus: GeoFeatureImportStatus.success,
          importProgress: 1.0,
          clearError: true,
        ),
      );
    } catch (e) {
      _emitFailure(e);
    }
  }

  Future<void> deleteSelectedFromFirestore() async {
    final path = state.importCollectionPath?.trim();
    if (path == null || path.isEmpty) return;

    final selected =
    state.importFeatures.where((f) => f.selected).toList(growable: false);
    if (selected.isEmpty) return;

    final ids =
    selected.map((f) => f.id).whereType<String>().toList(growable: false);
    if (ids.isEmpty) return;

    emit(
      state.copyWith(
        importStatus: GeoFeatureImportStatus.deleting,
        importProgress: 0.0,
        clearError: true,
      ),
    );

    try {
      await _repository.deleteFeaturesFromCollection(
        collectionPath: path,
        docIds: ids,
        onProgress: (progress) {
          emit(state.copyWith(importProgress: progress));
        },
      );

      final remaining = state.importFeatures
          .where((feature) => !ids.contains(feature.id))
          .toList(growable: false);

      emit(
        state.copyWith(
          importStatus: GeoFeatureImportStatus.previewReady,
          importFeatures: remaining,
          importProgress: 0.0,
          clearError: true,
        ),
      );
    } catch (e) {
      _emitFailure(e);
    }
  }

  dynamic _castValue(dynamic value, TypeFieldGeoJson type) {
    if (value == null) return null;

    final raw = value.toString().trim();

    switch (type) {
      case TypeFieldGeoJson.string:
        return value.toString();

      case TypeFieldGeoJson.integer:
        if (raw.isEmpty) return null;
        if (value is int) return value;
        if (value is num) return value.toInt();
        return int.tryParse(raw) ?? value;

      case TypeFieldGeoJson.double_:
        if (raw.isEmpty) return null;
        if (value is double) return value;
        if (value is num) return value.toDouble();
        return double.tryParse(raw.replaceAll(',', '.')) ?? value;

      case TypeFieldGeoJson.boolean:
        if (raw.isEmpty) return null;
        if (value is bool) return value;

        final v = raw.toLowerCase();
        if (v == 'true' || v == '1' || v == 'sim' || v == 'yes') return true;
        if (v == 'false' ||
            v == '0' ||
            v == 'nao' ||
            v == 'não' ||
            v == 'no') {
          return false;
        }
        return value;

      case TypeFieldGeoJson.datetime:
        if (raw.isEmpty) return null;
        if (value is DateTime) return value;
        if (value is Timestamp) return value.toDate();

        final parsed = DateTime.tryParse(raw);
        return parsed ?? value;
    }
  }

  List<String> _extractFieldsFromFeatures(List<GeoFeatureData> features) {
    final keys = <String>{};

    for (final feature in features) {
      keys.addAll(feature.editedProperties.keys);
    }

    final result = keys.toList()..sort();
    return result;
  }

  void _emitFailure(Object error) {
    emit(
      state.copyWith(
        importStatus: GeoFeatureImportStatus.failure,
        error: error.toString(),
      ),
    );
  }
}