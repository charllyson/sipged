import 'package:collection/collection.dart';

import 'feature_data.dart';

enum FeatureImportStatus {
  idle,
  pickingFile,
  loadingFirestore,
  previewReady,
  saving,
  deleting,
  success,
  failure,
}

class LayerSelection {
  final String layerId;
  final FeatureData feature;

  const LayerSelection({
    required this.layerId,
    required this.feature,
  });

  @override
  bool operator ==(Object other) {
    return other is LayerSelection &&
        other.layerId == layerId &&
        other.feature == feature;
  }

  @override
  int get hashCode => Object.hash(layerId, feature);
}

class FeatureState {
  final Map<String, List<FeatureData>> featuresByLayer;
  final Map<String, bool> loadingByLayer;
  final Map<String, bool> loadedByLayer;
  final Map<String, List<String>> availableFieldsByLayer;

  final String? error;
  final LayerSelection? selected;

  final FeatureImportStatus importStatus;
  final String? importCollectionPath;
  final List<FeatureData> importFeatures;
  final List<ImportColumnMeta> importColumns;
  final double importProgress;
  final Map<String, String> importFieldMapping;

  /// Incremente sempre que algo que impacta renderização do mapa mudar.
  final int visualRevision;

  const FeatureState({
    this.featuresByLayer = const {},
    this.loadingByLayer = const {},
    this.loadedByLayer = const {},
    this.availableFieldsByLayer = const {},
    this.error,
    this.selected,
    this.importStatus = FeatureImportStatus.idle,
    this.importCollectionPath,
    this.importFeatures = const [],
    this.importColumns = const [],
    this.importProgress = 0.0,
    this.importFieldMapping = const {},
    this.visualRevision = 0,
  });

  bool get isAnyLoading => loadingByLayer.values.any((e) => e == true);

  bool get isImportBusy =>
      importStatus == FeatureImportStatus.pickingFile ||
          importStatus == FeatureImportStatus.loadingFirestore ||
          importStatus == FeatureImportStatus.saving ||
          importStatus == FeatureImportStatus.deleting;

  bool get hasAnyImportedSelected =>
      importFeatures.any((feature) => feature.selected);

  FeatureState copyWith({
    Map<String, List<FeatureData>>? featuresByLayer,
    Map<String, bool>? loadingByLayer,
    Map<String, bool>? loadedByLayer,
    Map<String, List<String>>? availableFieldsByLayer,
    String? error,
    LayerSelection? selected,
    FeatureImportStatus? importStatus,
    String? importCollectionPath,
    List<FeatureData>? importFeatures,
    List<ImportColumnMeta>? importColumns,
    double? importProgress,
    Map<String, String>? importFieldMapping,
    int? visualRevision,
    bool clearError = false,
    bool clearSelection = false,
    bool clearImportSession = false,
  }) {
    return FeatureState(
      featuresByLayer: featuresByLayer ?? this.featuresByLayer,
      loadingByLayer: loadingByLayer ?? this.loadingByLayer,
      loadedByLayer: loadedByLayer ?? this.loadedByLayer,
      availableFieldsByLayer:
      availableFieldsByLayer ?? this.availableFieldsByLayer,
      error: clearError ? null : (error ?? this.error),
      selected: clearSelection ? null : (selected ?? this.selected),
      importStatus: clearImportSession
          ? FeatureImportStatus.idle
          : (importStatus ?? this.importStatus),
      importCollectionPath: clearImportSession
          ? null
          : (importCollectionPath ?? this.importCollectionPath),
      importFeatures:
      clearImportSession ? const [] : (importFeatures ?? this.importFeatures),
      importColumns:
      clearImportSession ? const [] : (importColumns ?? this.importColumns),
      importProgress:
      clearImportSession ? 0.0 : (importProgress ?? this.importProgress),
      importFieldMapping: clearImportSession
          ? const {}
          : (importFieldMapping ?? this.importFieldMapping),
      visualRevision: visualRevision ?? this.visualRevision,
    );
  }

  static const _deepEq = DeepCollectionEquality();

  @override
  bool operator ==(Object other) {
    return other is FeatureState &&
        _deepEq.equals(other.featuresByLayer, featuresByLayer) &&
        _deepEq.equals(other.loadingByLayer, loadingByLayer) &&
        _deepEq.equals(other.loadedByLayer, loadedByLayer) &&
        _deepEq.equals(other.availableFieldsByLayer, availableFieldsByLayer) &&
        other.error == error &&
        other.selected == selected &&
        other.importStatus == importStatus &&
        other.importCollectionPath == importCollectionPath &&
        _deepEq.equals(other.importFeatures, importFeatures) &&
        _deepEq.equals(other.importColumns, importColumns) &&
        other.importProgress == importProgress &&
        _deepEq.equals(other.importFieldMapping, importFieldMapping) &&
        other.visualRevision == visualRevision;
  }

  @override
  int get hashCode => Object.hash(
    _deepEq.hash(featuresByLayer),
    _deepEq.hash(loadingByLayer),
    _deepEq.hash(loadedByLayer),
    _deepEq.hash(availableFieldsByLayer),
    error,
    selected,
    importStatus,
    importCollectionPath,
    _deepEq.hash(importFeatures),
    _deepEq.hash(importColumns),
    importProgress,
    _deepEq.hash(importFieldMapping),
    visualRevision,
  );
}