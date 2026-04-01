import 'package:equatable/equatable.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data.dart';

class LayerState extends Equatable {
  final List<LayerData> tree;
  final Set<String> activeLayerIds;
  final Map<String, bool> hasDataByLayer;

  final bool isLoading;
  final bool isSaving;
  final bool isRefreshingLayerData;
  final bool loaded;

  final String? error;

  const LayerState({
    this.tree = const [],
    this.activeLayerIds = const <String>{},
    this.hasDataByLayer = const <String, bool>{},
    this.isLoading = false,
    this.isSaving = false,
    this.isRefreshingLayerData = false,
    this.error,
    this.loaded = false,
  });

  bool isLayerActive(String id) => activeLayerIds.contains(id);

  LayerState copyWith({
    List<LayerData>? tree,
    Set<String>? activeLayerIds,
    Map<String, bool>? hasDataByLayer,
    bool? isLoading,
    bool? isSaving,
    bool? isRefreshingLayerData,
    String? error,
    bool? loaded,
    bool clearError = false,
  }) {
    return LayerState(
      tree: tree ?? this.tree,
      activeLayerIds: activeLayerIds ?? this.activeLayerIds,
      hasDataByLayer: hasDataByLayer ?? this.hasDataByLayer,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isRefreshingLayerData:
      isRefreshingLayerData ?? this.isRefreshingLayerData,
      error: clearError ? null : (error ?? this.error),
      loaded: loaded ?? this.loaded,
    );
  }

  @override
  List<Object?> get props => [
    tree,
    activeLayerIds,
    hasDataByLayer,
    isLoading,
    isSaving,
    isRefreshingLayerData,
    error,
    loaded,
  ];
}