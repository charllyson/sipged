import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'attributes_table_state.dart';
import 'attributes_table_data.dart';
import 'attributes_table_repository.dart';

class AttributesTableCubit extends Cubit<VectorImportState> {
  final AttributesTableRepository _repo;

  AttributesTableCubit({AttributesTableRepository? repository})
      : _repo = repository ?? AttributesTableRepository(),
        super(VectorImportState.initial());

  Future<void> startImport(String collectionPath) async {
    emit(
      state.copyWith(
        status: AttributesTableStatus.pickingFile,
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
      final (features, columns) = _repo.buildImportedFeatures(raw);

      emit(
        state.copyWith(
          status: AttributesTableStatus.previewReady,
          features: features,
          columns: columns,
          progress: 0.0,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AttributesTableStatus.failure,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> startFromFirestore(String collectionPath) async {
    emit(
      state.copyWith(
        status: AttributesTableStatus.loadingFirestore,
        collectionPath: collectionPath,
        features: const [],
        columns: const [],
        progress: 0.0,
        clearError: true,
      ),
    );

    try {
      final (features, columns) = await _repo.loadFromFirestoreAsImportedFeatures(
        collectionPath: collectionPath,
        limit: 1500,
      );

      emit(
        state.copyWith(
          status: AttributesTableStatus.previewReady,
          features: features,
          columns: columns,
          progress: 0.0,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AttributesTableStatus.failure,
          error: e.toString(),
        ),
      );
    }
  }

  void toggleRowSelection(int index, bool selected) {
    final list = [...state.features];
    if (index < 0 || index >= list.length) return;

    list[index] = list[index].copyWith(selected: selected);
    emit(state.copyWith(features: list));
  }

  void toggleColumnSelection(int index, bool selected) {
    final cols = [...state.columns];
    if (index < 0 || index >= cols.length) return;

    cols[index] = cols[index].copyWith(selected: selected);
    emit(state.copyWith(columns: cols));
  }

  void renameColumn(int index, String newName) {
    final cols = [...state.columns];
    if (index < 0 || index >= cols.length) return;

    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;

    final oldName = cols[index].name;
    if (trimmed == oldName) return;

    final exists = cols.any(
          (c) => c.name.toLowerCase() == trimmed.toLowerCase() && c.name != oldName,
    );
    if (exists) {
      emit(state.copyWith(
        status: AttributesTableStatus.failure,
        error: 'Já existe uma coluna com o nome "$trimmed".',
      ));
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

    final newMapping = Map<String, String>.from(state.fieldMapping);
    newMapping.updateAll((key, value) => value == oldName ? trimmed : value);

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
    final cols = [...state.columns];
    if (index < 0 || index >= cols.length) return;

    final colName = cols[index].name;
    cols[index] = cols[index].copyWith(type: newType);

    final feats = state.features.map((f) {
      final newTypes = Map<String, TypeFieldGeoJson>.from(f.columnTypes);
      newTypes[colName] = newType;
      return f.copyWith(columnTypes: newTypes);
    }).toList(growable: false);

    emit(state.copyWith(columns: cols, features: feats));
  }

  Future<void> save() => saveAllFields();

  Future<void> saveAllFields() async {
    final path = state.collectionPath;
    if (path == null || path.trim().isEmpty) return;

    emit(
      state.copyWith(
        status: AttributesTableStatus.saving,
        progress: 0.0,
        clearError: true,
      ),
    );

    try {
      final selectedCols = state.columns
          .where((c) => c.selected)
          .toList(growable: false);

      if (selectedCols.isEmpty) {
        emit(
          state.copyWith(
            status: AttributesTableStatus.failure,
            error: 'Nenhuma coluna selecionada para salvar.',
          ),
        );
        return;
      }

      final selectedColNames = selectedCols.map((c) => c.name).toList(growable: false);
      final typeByColumn = {
        for (final c in selectedCols) c.name: c.type,
      };

      final prepared = state.features
          .where((f) => f.selected)
          .map((f) {
        final newProps = <String, dynamic>{};

        for (final colName in selectedColNames) {
          final rawValue = f.editedProperties[colName];
          final type = typeByColumn[colName] ?? TypeFieldGeoJson.string;
          newProps[colName] = _castValue(rawValue, type);
        }

        return f.copyWith(editedProperties: newProps);
      })
          .toList(growable: false);

      await _repo.saveToCollection(
        collectionPath: path,
        features: prepared,
        onProgress: (p) => emit(state.copyWith(progress: p)),
      );

      emit(
        state.copyWith(
          status: AttributesTableStatus.success,
          progress: 1.0,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AttributesTableStatus.failure,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> deleteSelectedFromFirestore() async {
    final path = state.collectionPath;
    if (path == null || path.trim().isEmpty) return;

    final selected = state.features.where((f) => f.selected).toList(growable: false);
    if (selected.isEmpty) return;

    final ids = selected.map((f) => f.docId).whereType<String>().toList(growable: false);
    if (ids.isEmpty) return;

    emit(
      state.copyWith(
        status: AttributesTableStatus.deleting,
        progress: 0.0,
        clearError: true,
      ),
    );

    try {
      await _repo.deleteDocs(
        collectionPath: path,
        docIds: ids,
        onProgress: (p) => emit(state.copyWith(progress: p)),
      );

      final remaining = state.features
          .where((f) => !ids.contains(f.docId))
          .toList(growable: false);

      emit(
        state.copyWith(
          status: AttributesTableStatus.previewReady,
          features: remaining,
          progress: 0.0,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AttributesTableStatus.failure,
          error: e.toString(),
        ),
      );
    }
  }

  void setFieldMapping(String targetField, String? sourceColumn) {
    final map = Map<String, String>.from(state.fieldMapping);

    if (sourceColumn == null || sourceColumn.trim().isEmpty) {
      map.remove(targetField);
    } else {
      map[targetField] = sourceColumn.trim();
    }

    emit(state.copyWith(fieldMapping: map));
  }

  dynamic _castValue(dynamic value, TypeFieldGeoJson type) {
    if (value == null) return null;

    switch (type) {
      case TypeFieldGeoJson.string:
        return value.toString();

      case TypeFieldGeoJson.integer:
        if (value is int) return value;
        if (value is num) return value.toInt();
        return int.tryParse(value.toString().trim()) ?? value;

      case TypeFieldGeoJson.double_:
        if (value is double) return value;
        if (value is num) return value.toDouble();

        final normalized = value.toString().trim().replaceAll(',', '.');
        return double.tryParse(normalized) ?? value;

      case TypeFieldGeoJson.boolean:
        if (value is bool) return value;

        final v = value.toString().trim().toLowerCase();
        if (v == 'true' || v == '1' || v == 'sim' || v == 'yes') return true;
        if (v == 'false' || v == '0' || v == 'nao' || v == 'não' || v == 'no') {
          return false;
        }
        return value;

      case TypeFieldGeoJson.datetime:
        if (value is DateTime) return value;
        if (value is Timestamp) return value.toDate();

        final raw = value.toString().trim();
        final parsed = DateTime.tryParse(raw);
        return parsed ?? value;
    }
  }
}