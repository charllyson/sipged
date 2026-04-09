import 'package:equatable/equatable.dart';

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

class LayerSelection extends Equatable {
  final String layerId;
  final FeatureData feature;

  const LayerSelection({
    required this.layerId,
    required this.feature,
  });

  @override
  List<Object?> get props => [layerId, feature];
}

class FeatureState extends Equatable {
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
      importCollectionPath:
      clearImportSession ? null : (importCollectionPath ?? this.importCollectionPath),
      importFeatures:
      clearImportSession ? const [] : (importFeatures ?? this.importFeatures),
      importColumns:
      clearImportSession ? const [] : (importColumns ?? this.importColumns),
      importProgress:
      clearImportSession ? 0.0 : (importProgress ?? this.importProgress),
      importFieldMapping: clearImportSession
          ? const {}
          : (importFieldMapping ?? this.importFieldMapping),
    );
  }

  @override
  List<Object?> get props => [
    featuresByLayer,
    loadingByLayer,
    loadedByLayer,
    availableFieldsByLayer,
    error,
    selected,
    importStatus,
    importCollectionPath,
    importFeatures,
    importColumns,
    importProgress,
    importFieldMapping,
  ];
}