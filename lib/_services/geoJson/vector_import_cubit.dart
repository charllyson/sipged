// lib/_services/geoJson/vector_import_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';

import 'vector_import_state.dart';
import 'vector_import_data.dart';
import 'vector_import_repository.dart';

class VectorImportCubit extends Cubit<VectorImportState> {
  final VectorImportRepository _repo;

  VectorImportCubit({
    VectorImportRepository? repository,
  })  : _repo = repository ?? VectorImportRepository(),
        super(VectorImportState.initial());

  // ---------------------------------------------------------------------------
  // Fluxo principal
  // ---------------------------------------------------------------------------

  Future<void> startImport(String collectionPath) async {
    emit(
      state.copyWith(
        status: VectorImportStatus.pickingFile,
        error: null,
        collectionPath: collectionPath,
        features: const [],
        columns: const [],
        fieldMapping: const {}, // zera mapeamento
      ),
    );

    try {
      final raw = await _repo.pickAndParseRawFeatures();
      final (features, columns) = _repo.buildImportedFeatures(raw);

      emit(
        state.copyWith(
          status: VectorImportStatus.previewReady,
          features: features,
          columns: columns,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: VectorImportStatus.failure,
          error: e.toString(),
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Seleções / edição de colunas / linhas
  // ---------------------------------------------------------------------------

  void toggleRowSelection(int index, bool selected) {
    final list = [...state.features];
    list[index] = list[index].copyWith(selected: selected);
    emit(state.copyWith(features: list));
  }

  void toggleColumnSelection(int index, bool selected) {
    final cols = [...state.columns];
    cols[index] = cols[index].copyWith(selected: selected);
    emit(state.copyWith(columns: cols));
  }

  void renameColumn(int index, String newName) {
    final cols = [...state.columns];
    final oldName = cols[index].name;
    cols[index] = cols[index].copyWith(name: newName);

    // Atualiza editedProperties de cada feature
    final feats = state.features.map((f) {
      if (!f.editedProperties.containsKey(oldName)) {
        return f;
      }
      final newProps = Map<String, dynamic>.from(f.editedProperties);
      final value = newProps.remove(oldName);
      newProps[newName] = value;
      return f.copyWith(editedProperties: newProps);
    }).toList();

    // Atualiza fieldMapping (se apontava para a coluna antiga)
    final newMapping = Map<String, String>.from(state.fieldMapping);
    newMapping.updateAll((key, value) {
      if (value == oldName) return newName;
      return value;
    });

    emit(
      state.copyWith(
        columns: cols,
        features: feats,
        fieldMapping: newMapping,
      ),
    );
  }

  void changeColumnType(int index, TypeFieldGeoJson newType) {
    final cols = [...state.columns];
    cols[index] = cols[index].copyWith(type: newType);
    emit(state.copyWith(columns: cols));
  }

  // ---------------------------------------------------------------------------
  // Geometria e mapeamento De -> Para
  // ---------------------------------------------------------------------------

  void toggleSaveGeometry(int index, bool value) {
    final list = [...state.features];
    list[index] = list[index].copyWith(saveGeometry: value);
    emit(state.copyWith(features: list));
  }

  void changeGeometryFieldName(int index, String fieldName) {
    final list = [...state.features];
    list[index] = list[index].copyWith(geometryFieldName: fieldName);
    emit(state.copyWith(features: list));
  }

  /// Define o mapeamento "campo destino" -> "coluna do arquivo" ou GEOMETRIA.
  ///
  /// - [targetField]: ex.: "state", "road", "region", "points".
  /// - [sourceColumn]: ex.: "UF", "RODOVIA", "REGIAO" ou [kGeometrySourceLabel].
  ///
  /// Se [sourceColumn] for null ou vazio, remove o mapeamento.
  void setFieldMapping(String targetField, String? sourceColumn) {
    final map = Map<String, String>.from(state.fieldMapping);
    if (sourceColumn == null || sourceColumn.trim().isEmpty) {
      map.remove(targetField);
    } else {
      map[targetField] = sourceColumn.trim();
    }
    emit(state.copyWith(fieldMapping: map));
  }

  /// Aplica o mapeamento de campos sobre as features antes de salvar.
  ///
  /// - Se não houver mapeamento, devolve a lista original.
  /// - Se houver, monta um novo `editedProperties` contendo APENAS
  ///   os campos mapeados.
  /// - Quando a fonte for [kGeometrySourceLabel], usa `geometryPoints`
  ///   como valor do campo de destino (array de GeoPoint).
  List<ImportedFeatureData> _applyFieldMapping() {
    final mapping = state.fieldMapping;
    if (mapping.isEmpty) return state.features;

    return state.features.map((f) {
      final newProps = <String, dynamic>{};

      mapping.forEach((targetField, sourceField) {
        if (sourceField == kGeometrySourceLabel) {
          if (f.geometryPoints.isNotEmpty) {
            newProps[targetField] = f.geometryPoints;
          }
        } else if (f.editedProperties.containsKey(sourceField)) {
          newProps[targetField] = f.editedProperties[sourceField];
        }
      });

      return f.copyWith(editedProperties: newProps);
    }).toList(growable: false);
  }

  Future<void> save() async {
    final path = state.collectionPath;
    if (path == null) return;

    emit(
      state.copyWith(
        status: VectorImportStatus.saving,
        progress: 0.0,
        error: null,
      ),
    );

    try {
      // aplica mapeamento De -> Para antes de persistir
      final mappedFeatures = _applyFieldMapping();

      await _repo.saveToCollection(
        collectionPath: path,
        features: mappedFeatures,
        onProgress: (p) {
          emit(state.copyWith(progress: p));
        },
      );

      emit(state.copyWith(status: VectorImportStatus.success));
    } catch (e) {
      emit(
        state.copyWith(
          status: VectorImportStatus.failure,
          error: e.toString(),
        ),
      );
    }
  }
}
