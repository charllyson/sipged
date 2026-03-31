import 'package:equatable/equatable.dart';

import 'geo_feature_data.dart';

enum GeoFeatureImportStatus {
  idle,
  pickingFile,
  loadingFirestore,
  previewReady,
  saving,
  deleting,
  success,
  failure,
}

class GenericGeoLayerSelection extends Equatable {
  final String layerId;
  final GeoFeatureData feature;

  const GenericGeoLayerSelection({
    required this.layerId,
    required this.feature,
  });

  @override
  List<Object?> get props => [layerId, feature];
}

class GeoFeatureState extends Equatable {
  final Map<String, List<GeoFeatureData>> featuresByLayer;
  final Map<String, bool> loadingByLayer;
  final Map<String, bool> loadedByLayer;
  final Map<String, List<String>> availableFieldsByLayer;

  final String? error;
  final GenericGeoLayerSelection? selected;

  final GeoFeatureImportStatus importStatus;
  final String? importCollectionPath;
  final List<GeoFeatureData> importFeatures;
  final List<ImportColumnMeta> importColumns;
  final double importProgress;
  final Map<String, String> importFieldMapping;

  const GeoFeatureState({
    this.featuresByLayer = const {},
    this.loadingByLayer = const {},
    this.loadedByLayer = const {},
    this.availableFieldsByLayer = const {},
    this.error,
    this.selected,
    this.importStatus = GeoFeatureImportStatus.idle,
    this.importCollectionPath,
    this.importFeatures = const [],
    this.importColumns = const [],
    this.importProgress = 0.0,
    this.importFieldMapping = const {},
  });

  bool get isAnyLoading => loadingByLayer.values.any((e) => e == true);

  bool get isImportBusy =>
      importStatus == GeoFeatureImportStatus.pickingFile ||
          importStatus == GeoFeatureImportStatus.loadingFirestore ||
          importStatus == GeoFeatureImportStatus.saving ||
          importStatus == GeoFeatureImportStatus.deleting;

  bool get hasAnyImportedSelected =>
      importFeatures.any((feature) => feature.selected);

  GeoFeatureState copyWith({
    Map<String, List<GeoFeatureData>>? featuresByLayer,
    Map<String, bool>? loadingByLayer,
    Map<String, bool>? loadedByLayer,
    Map<String, List<String>>? availableFieldsByLayer,
    String? error,
    GenericGeoLayerSelection? selected,
    GeoFeatureImportStatus? importStatus,
    String? importCollectionPath,
    List<GeoFeatureData>? importFeatures,
    List<ImportColumnMeta>? importColumns,
    double? importProgress,
    Map<String, String>? importFieldMapping,
    bool clearError = false,
    bool clearSelection = false,
    bool clearImportSession = false,
  }) {
    return GeoFeatureState(
      featuresByLayer: featuresByLayer ?? this.featuresByLayer,
      loadingByLayer: loadingByLayer ?? this.loadingByLayer,
      loadedByLayer: loadedByLayer ?? this.loadedByLayer,
      availableFieldsByLayer:
      availableFieldsByLayer ?? this.availableFieldsByLayer,
      error: clearError ? null : (error ?? this.error),
      selected: clearSelection ? null : (selected ?? this.selected),
      importStatus: clearImportSession
          ? GeoFeatureImportStatus.idle
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