import 'package:equatable/equatable.dart';
import 'package:sipged/_blocs/modules/planning/geo/generic/geo_feature_data.dart';

class GenericGeoLayerSelection extends Equatable {
  final String layerId;
  final GeoFeatureData feature;

  const GenericGeoLayerSelection({
    required this.layerId,
    required this.feature,
  });

  @override
  List<Object?> get props => [layerId, feature.selectionKey];
}

class GeoFeatureState extends Equatable {
  final Map<String, List<GeoFeatureData>> featuresByLayer;
  final Map<String, bool> loadingByLayer;
  final Map<String, bool> loadedByLayer;
  final String? error;
  final GenericGeoLayerSelection? selected;

  const GeoFeatureState({
    this.featuresByLayer = const {},
    this.loadingByLayer = const {},
    this.loadedByLayer = const {},
    this.error,
    this.selected,
  });

  bool get isAnyLoading => loadingByLayer.values.any((e) => e == true);

  GeoFeatureState copyWith({
    Map<String, List<GeoFeatureData>>? featuresByLayer,
    Map<String, bool>? loadingByLayer,
    Map<String, bool>? loadedByLayer,
    String? error,
    GenericGeoLayerSelection? selected,
    bool clearError = false,
    bool clearSelection = false,
  }) {
    return GeoFeatureState(
      featuresByLayer: featuresByLayer ?? this.featuresByLayer,
      loadingByLayer: loadingByLayer ?? this.loadingByLayer,
      loadedByLayer: loadedByLayer ?? this.loadedByLayer,
      error: clearError ? null : (error ?? this.error),
      selected: clearSelection ? null : (selected ?? this.selected),
    );
  }

  @override
  List<Object?> get props => [
    featuresByLayer,
    loadingByLayer,
    loadedByLayer,
    error,
    selected,
  ];
}