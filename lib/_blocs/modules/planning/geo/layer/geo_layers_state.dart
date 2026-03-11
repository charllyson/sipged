import 'package:equatable/equatable.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data.dart';

class GeoLayersState extends Equatable {
  final List<GeoLayersData> tree;
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final bool loaded;

  const GeoLayersState({
    this.tree = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.loaded = false,
  });

  GeoLayersState copyWith({
    List<GeoLayersData>? tree,
    bool? isLoading,
    bool? isSaving,
    String? error,
    bool? loaded,
    bool clearError = false,
  }) {
    return GeoLayersState(
      tree: tree ?? this.tree,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
      loaded: loaded ?? this.loaded,
    );
  }

  @override
  List<Object?> get props => [tree, isLoading, isSaving, error, loaded];
}