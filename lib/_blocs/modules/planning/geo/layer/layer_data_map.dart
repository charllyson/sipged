import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

import 'package:sipged/_blocs/modules/planning/geo/feature/feature_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/feature_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/feature_state.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_state.dart';
import 'package:sipged/_blocs/modules/planning/geo/map/map_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/map/map_state.dart';
import 'package:sipged/_blocs/modules/planning/geo/toolbox/toolbox_state.dart';
import 'package:sipged/screens/modules/planning/geo/status/status_bar.dart';

class LayerDataMap extends Equatable {
  final List<LayerData> currentTree;
  final Set<String> activeLayerIds;
  final Map<String, bool> hasDataByLayer;

  final Map<String, LayerData> layersById;
  final List<String> orderedLeafIdsTopToBottom;
  final List<String> orderedActiveLayerIdsForMap;

  final List<FeatureData> visibleFeatures;
  final String? selectedFeatureKey;

  final LayerData? activePointLayer;
  final LayerData? activeLineLayer;
  final LayerData? activePolygonLayer;

  final Map<String, List<LatLng>> visiblePointDrafts;
  final Map<String, List<LatLng>> visibleLineDrafts;
  final Map<String, List<LatLng>> visiblePolygonDrafts;

  final bool isLoading;
  final bool showFloatingStatus;

  const LayerDataMap({
    required this.currentTree,
    required this.activeLayerIds,
    required this.hasDataByLayer,
    required this.layersById,
    required this.orderedLeafIdsTopToBottom,
    required this.orderedActiveLayerIdsForMap,
    required this.visibleFeatures,
    required this.selectedFeatureKey,
    required this.activePointLayer,
    required this.activeLineLayer,
    required this.activePolygonLayer,
    required this.visiblePointDrafts,
    required this.visibleLineDrafts,
    required this.visiblePolygonDrafts,
    required this.isLoading,
    required this.showFloatingStatus,
  });

  factory LayerDataMap.fromStates({
    required LayerCubit layersCubit,
    required MapCubit mapCubit,
    required FeatureCubit featureCubit,
    required LayerState layersState,
    required MapState mapState,
    required FeatureState featureState,
    required ToolboxState toolboxState,
  }) {
    final currentTree = layersState.tree;
    final activeLayerIds = layersState.activeLayerIds;

    final allNodes = layersCubit.flattenAllNodes(tree: currentTree);

    final layersById = <String, LayerData>{
      for (final node in allNodes.where((e) => !e.isGroup)) node.id: node,
    };

    final orderedLeafIdsTopToBottom = layersCubit
        .flattenOrderedLeafIds(tree: currentTree)
        .where(activeLayerIds.contains)
        .toList(growable: false);

    final orderedActiveLayerIdsForMap =
    orderedLeafIdsTopToBottom.reversed.toList(growable: false);

    final visibleFeatures = <FeatureData>[];
    for (final layerId in orderedActiveLayerIdsForMap) {
      visibleFeatures.addAll(
        featureState.featuresByLayer[layerId] ?? const <FeatureData>[],
      );
    }

    final activePointLayer = mapCubit.getActiveDraftPointLayer(currentTree);
    final activeLineLayer = mapCubit.getActiveDraftLineLayer(currentTree);
    final activePolygonLayer = mapCubit.getActiveDraftPolygonLayer(currentTree);

    final isLoading = featureState.isAnyLoading ||
        featureState.isImportBusy ||
        layersState.isSaving ||
        layersState.isDeleting ||
        layersState.isRefreshingLayerData;

    final showFloatingStatus = StatusBar.shouldShow(
      editorState: mapState,
      measurementState: toolboxState,
      activePointLayer: activePointLayer,
      activeLineLayer: activeLineLayer,
      activePolygonLayer: activePolygonLayer,
    );

    return LayerDataMap(
      currentTree: currentTree,
      activeLayerIds: activeLayerIds,
      hasDataByLayer: layersState.hasDataByLayer,
      layersById: layersById,
      orderedLeafIdsTopToBottom: orderedLeafIdsTopToBottom,
      orderedActiveLayerIdsForMap: orderedActiveLayerIdsForMap,
      visibleFeatures: visibleFeatures,
      selectedFeatureKey: featureState.selected?.feature.selectionKey,
      activePointLayer: activePointLayer,
      activeLineLayer: activeLineLayer,
      activePolygonLayer: activePolygonLayer,
      visiblePointDrafts: mapCubit.buildVisiblePointDrafts(activeLayerIds),
      visibleLineDrafts: mapCubit.buildVisibleLineDrafts(activeLayerIds),
      visiblePolygonDrafts: mapCubit.buildVisiblePolygonDrafts(activeLayerIds),
      isLoading: isLoading,
      showFloatingStatus: showFloatingStatus,
    );
  }

  @override
  List<Object?> get props => [
    currentTree,
    activeLayerIds,
    hasDataByLayer,
    layersById,
    orderedLeafIdsTopToBottom,
    orderedActiveLayerIdsForMap,
    visibleFeatures,
    selectedFeatureKey,
    activePointLayer,
    activeLineLayer,
    activePolygonLayer,
    visiblePointDrafts,
    visibleLineDrafts,
    visiblePolygonDrafts,
    isLoading,
    showFloatingStatus,
  ];
}