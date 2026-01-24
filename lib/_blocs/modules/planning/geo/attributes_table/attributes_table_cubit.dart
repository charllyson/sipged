// lib/_services/files/geoJson/attributes_table_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';

import 'attributes_table_state.dart';
import 'attributes_table_data.dart';
import 'attributes_table_repository.dart';

class AttributesTableCubit extends Cubit<VectorImportState> {
  final AttributesTableRepository _repo;

  AttributesTableCubit({AttributesTableRepository? repository})
      : _repo = repository ?? AttributesTableRepository(),
        super(VectorImportState.initial());

  // ---------------------------------------------------------------------------
  // ARQUIVO -> preview (QGIS-like)
  // ---------------------------------------------------------------------------
  Future<void> startImport(String collectionPath) async {
    emit(
      state.copyWith(
        status: AttributesTableStatus.pickingFile,
        error: null,
        collectionPath: collectionPath,
        features: const [],
        columns: const [],
        fieldMapping: const {},
        progress: 0.0,
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
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: AttributesTableStatus.failure, error: e.toString()));
    }
  }

  // ---------------------------------------------------------------------------
  // FIRESTORE -> preview (QGIS-like usando MESMO dialog)
  // ---------------------------------------------------------------------------
  Future<void> startFromFirestore(String collectionPath) async {
    emit(
      state.copyWith(
        status: AttributesTableStatus.loadingFirestore,
        error: null,
        collectionPath: collectionPath,
        features: const [],
        columns: const [],
        progress: 0.0,
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
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: AttributesTableStatus.failure, error: e.toString()));
    }
  }

  // ---------------------------------------------------------------------------
  // Seleções / edição
  // ---------------------------------------------------------------------------
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

    final oldName = cols[index].name;
    if (newName.trim().isEmpty || newName == oldName) return;

    cols[index] = cols[index].copyWith(name: newName);

    final feats = state.features.map((f) {
      if (!f.editedProperties.containsKey(oldName)) return f;

      final newProps = Map<String, dynamic>.from(f.editedProperties);
      final value = newProps.remove(oldName);
      newProps[newName] = value;

      return f.copyWith(editedProperties: newProps);
    }).toList(growable: false);

    final newMapping = Map<String, String>.from(state.fieldMapping);
    newMapping.updateAll((key, value) => value == oldName ? newName : value);

    emit(state.copyWith(columns: cols, features: feats, fieldMapping: newMapping));
  }

  void changeColumnType(int index, TypeFieldGeoJson newType) {
    final cols = [...state.columns];
    if (index < 0 || index >= cols.length) return;
    cols[index] = cols[index].copyWith(type: newType);
    emit(state.copyWith(columns: cols));
  }

  // ---------------------------------------------------------------------------
  // Import (arquivo -> Firestore)
  // ---------------------------------------------------------------------------
  Future<void> save() => saveAllFields();

  Future<void> saveAllFields() async {
    final path = state.collectionPath;
    if (path == null || path.trim().isEmpty) return;

    emit(state.copyWith(status: AttributesTableStatus.saving, progress: 0.0, error: null));

    try {
      final selectedCols = state.columns
          .where((c) => c.selected == true)
          .map((c) => c.name)
          .toList(growable: false);

      if (selectedCols.isEmpty) {
        emit(state.copyWith(
          status: AttributesTableStatus.failure,
          error: 'Nenhuma coluna selecionada para salvar.',
        ));
        return;
      }

      // Mantém apenas as colunas selecionadas em editedProperties (payload limpo)
      final prepared = state.features.map((f) {
        final newProps = <String, dynamic>{};
        for (final colName in selectedCols) {
          newProps[colName] = f.editedProperties[colName];
        }
        return f.copyWith(editedProperties: newProps);
      }).toList(growable: false);

      await _repo.saveToCollection(
        collectionPath: path,
        features: prepared,
        onProgress: (p) => emit(state.copyWith(progress: p)),
      );

      emit(state.copyWith(status: AttributesTableStatus.success, progress: 1.0));
    } catch (e) {
      emit(state.copyWith(status: AttributesTableStatus.failure, error: e.toString()));
    }
  }

  // ---------------------------------------------------------------------------
  // Excluir selecionados (modo Firestore)
  // ---------------------------------------------------------------------------
  Future<void> deleteSelectedFromFirestore() async {
    final path = state.collectionPath;
    if (path == null || path.trim().isEmpty) return;

    final selected = state.features.where((f) => f.selected == true).toList(growable: false);
    if (selected.isEmpty) return;

    final ids = selected.map((f) => f.docId).whereType<String>().toList(growable: false);
    if (ids.isEmpty) return;

    emit(state.copyWith(status: AttributesTableStatus.deleting, progress: 0.0, error: null));

    try {
      await _repo.deleteDocs(
        collectionPath: path,
        docIds: ids,
        onProgress: (p) => emit(state.copyWith(progress: p)),
      );

      // remove localmente
      final remaining = state.features.where((f) => !ids.contains(f.docId)).toList(growable: false);
      emit(state.copyWith(
        status: AttributesTableStatus.previewReady,
        features: remaining,
        progress: 0.0,
      ));
    } catch (e) {
      emit(state.copyWith(status: AttributesTableStatus.failure, error: e.toString()));
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
}
