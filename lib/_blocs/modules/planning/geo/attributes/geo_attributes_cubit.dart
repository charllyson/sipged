import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'geo_attributes_state.dart';
import 'geo_attributes_data.dart';
import 'geo_attributes_repository.dart';

class GeoAttributesCubit extends Cubit<GeoAttributesState> {
  final GeoAttributesRepository _repo;

  GeoAttributesCubit({
    GeoAttributesRepository? repository,
  })  : _repo = repository ?? GeoAttributesRepository(),
        super(GeoAttributesState.initial());

  Future<void> startImport(String collectionPath) async {
    emit(
      state.copyWith(
        status: GeoAttributesStatus.pickingFile,
        collectionPath: collectionPath,
        features: const [],
        columns: const [],
        fieldMapping: const {},
        progress: 0.0,
        clearError: true,
      ),
    );

    try {
      final raw = await _repo.pickAndParseRawFeatures();
      final result = _repo.buildImportedFeatures(raw);

      emit(
        state.copyWith(
          status: GeoAttributesStatus.previewReady,
          features: result.$1,
          columns: result.$2,
          progress: 0.0,
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
        status: GeoAttributesStatus.loadingFirestore,
        collectionPath: collectionPath,
        features: const [],
        columns: const [],
        progress: 0.0,
        clearError: true,
      ),
    );

    try {
      final result = await _repo.loadFromFirestoreAsImportedFeatures(
        collectionPath: collectionPath,
        limit: 1500,
      );

      emit(
        state.copyWith(
          status: GeoAttributesStatus.previewReady,
          features: result.$1,
          columns: result.$2,
          progress: 0.0,
          clearError: true,
        ),
      );
    } catch (e) {
      _emitFailure(e);
    }
  }

  void toggleRowSelection(int index, bool selected) {
    if (index < 0 || index >= state.features.length) return;

    final list = [...state.features];
    list[index] = list[index].copyWith(selected: selected);

    emit(state.copyWith(features: list, clearError: true));
  }

  void toggleColumnSelection(int index, bool selected) {
    if (index < 0 || index >= state.columns.length) return;

    final cols = [...state.columns];
    cols[index] = cols[index].copyWith(selected: selected);

    emit(state.copyWith(columns: cols, clearError: true));
  }

  void renameColumn(int index, String newName) {
    if (index < 0 || index >= state.columns.length) return;

    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;

    final cols = [...state.columns];
    final oldName = cols[index].name;

    if (trimmed == oldName) return;

    final exists = cols.any(
          (c) => c.name.toLowerCase() == trimmed.toLowerCase() && c.name != oldName,
    );

    if (exists) {
      emit(
        state.copyWith(
          status: GeoAttributesStatus.failure,
          error: 'Já existe uma coluna com o nome "$trimmed".',
        ),
      );
      return;
    }

    cols[index] = cols[index].copyWith(name: trimmed);

    final feats = state.features.map((f) {
      if (!f.editedProperties.containsKey(oldName)) return f;

      final newProps = Map<String, dynamic>.from(f.editedProperties);
      final value = newProps.remove(oldName);
      newProps[trimmed] = value;

      final newTypes = Map<String, TypeFieldGeoJson>.from(f.columnTypes);
      final oldType = newTypes.remove(oldName);
      if (oldType != null) {
        newTypes[trimmed] = oldType;
      }

      return f.copyWith(
        editedProperties: newProps,
        columnTypes: newTypes,
      );
    }).toList(growable: false);

    final newMapping = Map<String, String>.from(state.fieldMapping)
      ..updateAll((_, value) => value == oldName ? trimmed : value);

    emit(
      state.copyWith(
        columns: cols,
        features: feats,
        fieldMapping: newMapping,
        clearError: true,
      ),
    );
  }

  void changeColumnType(int index, TypeFieldGeoJson newType) {
    if (index < 0 || index >= state.columns.length) return;

    final cols = [...state.columns];
    final colName = cols[index].name;
    cols[index] = cols[index].copyWith(type: newType);

    final feats = state.features.map((f) {
      final newTypes = Map<String, TypeFieldGeoJson>.from(f.columnTypes);
      newTypes[colName] = newType;
      return f.copyWith(columnTypes: newTypes);
    }).toList(growable: false);

    emit(
      state.copyWith(
        columns: cols,
        features: feats,
        clearError: true,
      ),
    );
  }

  Future<void> save() => saveAllFields();

  Future<void> saveAllFields() async {
    final path = state.collectionPath?.trim();
    if (path == null || path.isEmpty) return;

    emit(
      state.copyWith(
        status: GeoAttributesStatus.saving,
        progress: 0.0,
        clearError: true,
      ),
    );

    try {
      final selectedCols =
      state.columns.where((c) => c.selected).toList(growable: false);

      if (selectedCols.isEmpty) {
        emit(
          state.copyWith(
            status: GeoAttributesStatus.failure,
            error: 'Nenhuma coluna selecionada para salvar.',
          ),
        );
        return;
      }

      final selectedRows =
      state.features.where((f) => f.selected).toList(growable: false);

      if (selectedRows.isEmpty) {
        emit(
          state.copyWith(
            status: GeoAttributesStatus.failure,
            error: 'Nenhuma linha selecionada para salvar.',
          ),
        );
        return;
      }

      final selectedColNames =
      selectedCols.map((c) => c.name).toList(growable: false);

      final typeByColumn = {
        for (final c in selectedCols) c.name: c.type,
      };

      final prepared = selectedRows.map((f) {
        final newProps = <String, dynamic>{};

        for (final colName in selectedColNames) {
          final rawValue = f.editedProperties[colName];
          final type = typeByColumn[colName] ?? TypeFieldGeoJson.string;
          newProps[colName] = _castValue(rawValue, type);
        }

        return f.copyWith(editedProperties: newProps);
      }).toList(growable: false);

      await _repo.saveToCollection(
        collectionPath: path,
        features: prepared,
        onProgress: (p) {
          emit(state.copyWith(progress: p));
        },
      );

      emit(
        state.copyWith(
          status: GeoAttributesStatus.success,
          progress: 1.0,
          clearError: true,
        ),
      );
    } catch (e) {
      _emitFailure(e);
    }
  }

  Future<void> deleteSelectedFromFirestore() async {
    final path = state.collectionPath?.trim();
    if (path == null || path.isEmpty) return;

    final selected =
    state.features.where((f) => f.selected).toList(growable: false);
    if (selected.isEmpty) return;

    final ids =
    selected.map((f) => f.docId).whereType<String>().toList(growable: false);
    if (ids.isEmpty) return;

    emit(
      state.copyWith(
        status: GeoAttributesStatus.deleting,
        progress: 0.0,
        clearError: true,
      ),
    );

    try {
      await _repo.deleteDocs(
        collectionPath: path,
        docIds: ids,
        onProgress: (p) {
          emit(state.copyWith(progress: p));
        },
      );

      final remaining = state.features
          .where((f) => !ids.contains(f.docId))
          .toList(growable: false);

      emit(
        state.copyWith(
          status: GeoAttributesStatus.previewReady,
          features: remaining,
          progress: 0.0,
          clearError: true,
        ),
      );
    } catch (e) {
      _emitFailure(e);
    }
  }

  void setFieldMapping(String targetField, String? sourceColumn) {
    final map = Map<String, String>.from(state.fieldMapping);

    final value = sourceColumn?.trim();
    if (value == null || value.isEmpty) {
      map.remove(targetField);
    } else {
      map[targetField] = value;
    }

    emit(state.copyWith(fieldMapping: map, clearError: true));
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

  void _emitFailure(Object error) {
    emit(
      state.copyWith(
        status: GeoAttributesStatus.failure,
        error: error.toString(),
      ),
    );
  }
}