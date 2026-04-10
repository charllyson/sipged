import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';

import '../layer/layer_data.dart';
import 'feature_data.dart';
import 'feature_repository.dart';
import 'feature_state.dart';

class FeatureCubit extends Cubit<FeatureState> {
  FeatureCubit({
    FeatureRepository? repository,
  })  : _repository = repository ?? FeatureRepository(),
        super(const FeatureState());

  final FeatureRepository _repository;

  final Map<String, Future<void>> _inFlightLayerLoads = {};
  final Map<String, Future<List<String>>> _inFlightFieldLoads = {};

  void _emitIfChanged(FeatureState next) {
    if (next != state) emit(next);
  }

  Map<String, bool> _setLoadingFlag(String layerId, bool value) {
    final next = Map<String, bool>.from(state.loadingByLayer);
    next[layerId] = value;
    return Map<String, bool>.unmodifiable(next);
  }

  Map<String, bool> _setLoadedFlag(String layerId, bool value) {
    final next = Map<String, bool>.from(state.loadedByLayer);
    next[layerId] = value;
    return Map<String, bool>.unmodifiable(next);
  }

  Map<String, List<FeatureData>> _setFeaturesForLayer(
      String layerId,
      List<FeatureData> features,
      ) {
    final next = Map<String, List<FeatureData>>.from(state.featuresByLayer);
    next[layerId] = List<FeatureData>.unmodifiable(features);
    return Map<String, List<FeatureData>>.unmodifiable(next);
  }

  Map<String, List<String>> _setAvailableFieldsForLayer(
      String layerId,
      List<String> fields,
      ) {
    final next = Map<String, List<String>>.from(state.availableFieldsByLayer);
    next[layerId] = List<String>.unmodifiable(fields);
    return Map<String, List<String>>.unmodifiable(next);
  }

  Future<void> ensureLayerLoaded(
      LayerData layer, {
        bool force = false,
      }) async {
    final path = (layer.effectiveCollectionPath ?? '').trim();
    if (path.isEmpty || layer.isGroup) return;

    final alreadyLoaded = state.loadedByLayer[layer.id] == true;
    final isLoading = state.loadingByLayer[layer.id] == true;

    if (!force && alreadyLoaded) return;

    if (!force) {
      final inFlight = _inFlightLayerLoads[layer.id];
      if (inFlight != null) return inFlight;
      if (isLoading) return;
    }

    final future = _ensureLayerLoadedInternal(
      layer: layer,
      path: path,
      force: force,
    );

    _inFlightLayerLoads[layer.id] = future;

    try {
      await future;
    } finally {
      _inFlightLayerLoads.remove(layer.id);
    }
  }

  Future<void> _ensureLayerLoadedInternal({
    required LayerData layer,
    required String path,
    required bool force,
  }) async {
    final currentlyLoading = state.loadingByLayer[layer.id] == true;
    if (!currentlyLoading) {
      _emitIfChanged(
        state.copyWith(
          loadingByLayer: _setLoadingFlag(layer.id, true),
          clearError: true,
        ),
      );
    }

    try {
      final features = await _repository.loadFeatures(
        layerId: layer.id,
        collectionPath: path,
      );

      final nextFeatures = _setFeaturesForLayer(layer.id, features);
      final nextLoading = _setLoadingFlag(layer.id, false);
      final nextLoaded = _setLoadedFlag(layer.id, true);
      final nextAvailableFields = _setAvailableFieldsForLayer(
        layer.id,
        _extractFieldsFromFeatures(features),
      );

      final currentSelection = state.selected;
      final shouldClearSelection = currentSelection != null &&
          currentSelection.layerId == layer.id &&
          !features.any(
                (feature) =>
            feature.selectionKey == currentSelection.feature.selectionKey,
          );

      _emitIfChanged(
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
      _emitIfChanged(
        state.copyWith(
          loadingByLayer: _setLoadingFlag(layer.id, false),
          error: e.toString(),
        ),
      );
    }
  }

  Future<List<String>> ensureLayerFieldNames(
      LayerData layer, {
        bool force = false,
      }) async {
    final path = (layer.effectiveCollectionPath ?? '').trim();
    if (path.isEmpty || layer.isGroup) return const [];

    final cached = state.availableFieldsByLayer[layer.id];
    if (!force && cached != null && cached.isNotEmpty) {
      return cached;
    }

    if (!force) {
      final inFlight = _inFlightFieldLoads[layer.id];
      if (inFlight != null) return inFlight;
    }

    final future = _ensureLayerFieldNamesInternal(
      layerId: layer.id,
      path: path,
    );

    _inFlightFieldLoads[layer.id] = future;

    try {
      return await future;
    } finally {
      _inFlightFieldLoads.remove(layer.id);
    }
  }

  Future<List<String>> _ensureLayerFieldNamesInternal({
    required String layerId,
    required String path,
  }) async {
    try {
      final fieldNames = await _repository.loadFieldNames(
        collectionPath: path,
      );

      final current = state.availableFieldsByLayer[layerId];
      if (current != null &&
          current.length == fieldNames.length &&
          _sameOrderedStrings(current, fieldNames)) {
        return current;
      }

      _emitIfChanged(
        state.copyWith(
          availableFieldsByLayer: _setAvailableFieldsForLayer(layerId, fieldNames),
          clearError: true,
        ),
      );

      return fieldNames;
    } catch (e) {
      _emitIfChanged(
        state.copyWith(
          error: e.toString(),
        ),
      );
      return const [];
    }
  }

  Future<void> reloadLayer(LayerData layer) async {
    await ensureLayerLoaded(layer, force: true);
  }

  Future<void> addPointFeaturesBatch({
    required LayerData layer,
    required List<LatLng> points,
    Map<String, dynamic> commonProperties = const {},
  }) async {
    final path = (layer.effectiveCollectionPath ?? '').trim();
    if (path.isEmpty || layer.isGroup || points.isEmpty) return;

    await _runLayerMutation(
      layerId: layer.id,
      action: () async {
        await _repository.addPointFeaturesBatch(
          layerId: layer.id,
          collectionPath: path,
          points: points,
          commonProperties: commonProperties,
        );
        await ensureLayerLoaded(layer, force: true);
      },
    );
  }

  Future<void> addLineFeaturesBatch({
    required LayerData layer,
    required List<List<LatLng>> lines,
    Map<String, dynamic> commonProperties = const {},
  }) async {
    final path = (layer.effectiveCollectionPath ?? '').trim();
    final validLines = lines.where((e) => e.length >= 2).toList(growable: false);

    if (path.isEmpty || layer.isGroup || validLines.isEmpty) return;

    await _runLayerMutation(
      layerId: layer.id,
      action: () async {
        await _repository.addLineFeaturesBatch(
          layerId: layer.id,
          collectionPath: path,
          lines: validLines,
          commonProperties: commonProperties,
        );
        await ensureLayerLoaded(layer, force: true);
      },
    );
  }

  Future<void> addPolygonFeaturesBatch({
    required LayerData layer,
    required List<List<LatLng>> polygons,
    Map<String, dynamic> commonProperties = const {},
  }) async {
    final path = (layer.effectiveCollectionPath ?? '').trim();
    final validPolygons =
    polygons.where((e) => e.length >= 3).toList(growable: false);

    if (path.isEmpty || layer.isGroup || validPolygons.isEmpty) return;

    await _runLayerMutation(
      layerId: layer.id,
      action: () async {
        await _repository.addPolygonFeaturesBatch(
          layerId: layer.id,
          collectionPath: path,
          polygons: validPolygons,
          commonProperties: commonProperties,
        );
        await ensureLayerLoaded(layer, force: true);
      },
    );
  }

  Future<void> _runLayerMutation({
    required String layerId,
    required Future<void> Function() action,
  }) async {
    final currentlyLoading = state.loadingByLayer[layerId] == true;
    if (!currentlyLoading) {
      _emitIfChanged(
        state.copyWith(
          loadingByLayer: _setLoadingFlag(layerId, true),
          clearError: true,
        ),
      );
    }

    try {
      await action();
    } catch (e) {
      _emitIfChanged(
        state.copyWith(
          loadingByLayer: _setLoadingFlag(layerId, false),
          error: e.toString(),
        ),
      );
      return;
    }

    _emitIfChanged(
      state.copyWith(
        loadingByLayer: _setLoadingFlag(layerId, false),
        clearError: true,
      ),
    );
  }

  void unloadLayer(String layerId) {
    final nextFeatures = Map<String, List<FeatureData>>.from(state.featuresByLayer)
      ..remove(layerId);

    final nextLoaded = Map<String, bool>.from(state.loadedByLayer)
      ..remove(layerId);

    final nextLoading = Map<String, bool>.from(state.loadingByLayer)
      ..remove(layerId);

    final nextAvailableFields =
    Map<String, List<String>>.from(state.availableFieldsByLayer)
      ..remove(layerId);

    final clearSelection = state.selected?.layerId == layerId;

    _emitIfChanged(
      state.copyWith(
        featuresByLayer: Map<String, List<FeatureData>>.unmodifiable(nextFeatures),
        loadedByLayer: Map<String, bool>.unmodifiable(nextLoaded),
        loadingByLayer: Map<String, bool>.unmodifiable(nextLoading),
        availableFieldsByLayer:
        Map<String, List<String>>.unmodifiable(nextAvailableFields),
        clearSelection: clearSelection,
        clearError: true,
      ),
    );
  }

  void clearSelection() {
    if (state.selected == null && state.error == null) return;

    _emitIfChanged(
      state.copyWith(
        clearSelection: true,
        clearError: true,
      ),
    );
  }

  void selectFeature({
    required String layerId,
    required FeatureData feature,
  }) {
    final nextSelection = LayerSelection(
      layerId: layerId,
      feature: feature,
    );

    if (state.selected == nextSelection && state.error == null) return;

    _emitIfChanged(
      state.copyWith(
        selected: nextSelection,
        clearError: true,
      ),
    );
  }

  Future<void> startImport(String collectionPath) async {
    _emitIfChanged(
      state.copyWith(
        importStatus: FeatureImportStatus.pickingFile,
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

      _emitIfChanged(
        state.copyWith(
          importStatus: FeatureImportStatus.previewReady,
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
    _emitIfChanged(
      state.copyWith(
        importStatus: FeatureImportStatus.loadingFirestore,
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

      _emitIfChanged(
        state.copyWith(
          importStatus: FeatureImportStatus.previewReady,
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
    if (state.importStatus == FeatureImportStatus.idle &&
        state.importCollectionPath == null &&
        state.importFeatures.isEmpty &&
        state.importColumns.isEmpty &&
        state.importFieldMapping.isEmpty &&
        state.importProgress == 0.0) {
      return;
    }

    _emitIfChanged(
      state.copyWith(
        clearImportSession: true,
        clearError: true,
      ),
    );
  }

  void toggleRowSelection(int index, bool selected) {
    if (index < 0 || index >= state.importFeatures.length) return;
    if (state.importFeatures[index].selected == selected) return;

    final list = List<FeatureData>.from(state.importFeatures);
    list[index] = list[index].copyWith(selected: selected);

    _emitIfChanged(
      state.copyWith(
        importFeatures: List<FeatureData>.unmodifiable(list),
        clearError: true,
      ),
    );
  }

  void toggleColumnSelection(int index, bool selected) {
    if (index < 0 || index >= state.importColumns.length) return;
    if (state.importColumns[index].selected == selected) return;

    final cols = List<ImportColumnMeta>.from(state.importColumns);
    cols[index] = cols[index].copyWith(selected: selected);

    _emitIfChanged(
      state.copyWith(
        importColumns: List<ImportColumnMeta>.unmodifiable(cols),
        clearError: true,
      ),
    );
  }

  void renameColumn(int index, String newName) {
    if (index < 0 || index >= state.importColumns.length) return;

    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;

    final cols = List<ImportColumnMeta>.from(state.importColumns);
    final oldName = cols[index].name;

    if (trimmed == oldName) return;

    final exists = cols.any(
          (c) => c.name.toLowerCase() == trimmed.toLowerCase() && c.name != oldName,
    );

    if (exists) {
      _emitIfChanged(
        state.copyWith(
          importStatus: FeatureImportStatus.failure,
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

    _emitIfChanged(
      state.copyWith(
        importColumns: List<ImportColumnMeta>.unmodifiable(cols),
        importFeatures: List<FeatureData>.unmodifiable(feats),
        importFieldMapping: Map<String, String>.unmodifiable(newMapping),
        clearError: true,
      ),
    );
  }

  void changeColumnType(int index, TypeFieldGeoJson newType) {
    if (index < 0 || index >= state.importColumns.length) return;
    if (state.importColumns[index].type == newType) return;

    final cols = List<ImportColumnMeta>.from(state.importColumns);
    final colName = cols[index].name;
    cols[index] = cols[index].copyWith(type: newType);

    final feats = state.importFeatures.map((feature) {
      final newTypes = Map<String, TypeFieldGeoJson>.from(feature.columnTypes);
      newTypes[colName] = newType;
      return feature.copyWith(columnTypes: newTypes);
    }).toList(growable: false);

    _emitIfChanged(
      state.copyWith(
        importColumns: List<ImportColumnMeta>.unmodifiable(cols),
        importFeatures: List<FeatureData>.unmodifiable(feats),
        clearError: true,
      ),
    );
  }

  void setFieldMapping(String targetField, String? sourceColumn) {
    final map = Map<String, String>.from(state.importFieldMapping);
    final value = sourceColumn?.trim();

    if (value == null || value.isEmpty) {
      if (!map.containsKey(targetField)) return;
      map.remove(targetField);
    } else {
      if (map[targetField] == value) return;
      map[targetField] = value;
    }

    _emitIfChanged(
      state.copyWith(
        importFieldMapping: Map<String, String>.unmodifiable(map),
        clearError: true,
      ),
    );
  }

  Future<void> save() => saveImportedFeatures();

  Future<void> saveImportedFeatures() async {
    final path = state.importCollectionPath?.trim();
    if (path == null || path.isEmpty) return;

    _emitIfChanged(
      state.copyWith(
        importStatus: FeatureImportStatus.saving,
        importProgress: 0.0,
        clearError: true,
      ),
    );

    try {
      final selectedCols =
      state.importColumns.where((c) => c.selected).toList(growable: false);

      if (selectedCols.isEmpty) {
        _emitIfChanged(
          state.copyWith(
            importStatus: FeatureImportStatus.failure,
            error: 'Nenhuma coluna selecionada para salvar.',
          ),
        );
        return;
      }

      final selectedRows =
      state.importFeatures.where((f) => f.selected).toList(growable: false);

      if (selectedRows.isEmpty) {
        _emitIfChanged(
          state.copyWith(
            importStatus: FeatureImportStatus.failure,
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

      double lastProgress = -1;

      await _repository.saveFeaturesToCollection(
        collectionPath: path,
        features: prepared,
        onProgress: (progress) {
          final normalized = progress.clamp(0.0, 1.0);
          if ((normalized - lastProgress).abs() < 0.01 && normalized < 1.0) {
            return;
          }
          lastProgress = normalized;
          _emitIfChanged(state.copyWith(importProgress: normalized));
        },
      );

      _emitIfChanged(
        state.copyWith(
          importStatus: FeatureImportStatus.success,
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

    final ids = selected
        .map((f) => f.id)
        .whereType<String>()
        .toList(growable: false);
    if (ids.isEmpty) return;

    _emitIfChanged(
      state.copyWith(
        importStatus: FeatureImportStatus.deleting,
        importProgress: 0.0,
        clearError: true,
      ),
    );

    try {
      double lastProgress = -1;

      await _repository.deleteFeaturesFromCollection(
        collectionPath: path,
        docIds: ids,
        onProgress: (progress) {
          final normalized = progress.clamp(0.0, 1.0);
          if ((normalized - lastProgress).abs() < 0.01 && normalized < 1.0) {
            return;
          }
          lastProgress = normalized;
          _emitIfChanged(state.copyWith(importProgress: normalized));
        },
      );

      final idSet = ids.toSet();
      final remaining = state.importFeatures
          .where((feature) => !idSet.contains(feature.id))
          .toList(growable: false);

      _emitIfChanged(
        state.copyWith(
          importStatus: FeatureImportStatus.previewReady,
          importFeatures: List<FeatureData>.unmodifiable(remaining),
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

  List<String> _extractFieldsFromFeatures(List<FeatureData> features) {
    final keys = <String>{};

    for (final feature in features) {
      keys.addAll(feature.editedProperties.keys);
    }

    final result = keys.toList()..sort();
    return List<String>.unmodifiable(result);
  }

  bool _sameOrderedStrings(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;

    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _emitFailure(Object error) {
    _emitIfChanged(
      state.copyWith(
        importStatus: FeatureImportStatus.failure,
        error: error.toString(),
      ),
    );
  }
}