import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

import 'package:sipged/_blocs/modules/planning/geo/feature/geo_feature_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/geo_feature_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/geo_feature_state.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_state.dart';
import 'package:sipged/_blocs/modules/planning/geo/map/geo_map_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/map/geo_map_state.dart';
import 'package:sipged/_blocs/modules/planning/geo/toolbox/geo_toolbox_state.dart';
import 'package:sipged/_widgets/geo/status/pop_up_status_bar.dart';

class GeoMapData extends Equatable {
  final List<GeoLayersData> currentTree;
  final Set<String> activeLayerIds;
  final Map<String, bool> hasDataByLayer;

  final Map<String, GeoLayersData> layersById;
  final List<String> orderedLeafIdsTopToBottom;
  final List<String> orderedActiveLayerIdsForMap;

  final List<GeoFeatureData> visibleFeatures;
  final String? selectedFeatureKey;

  final GeoLayersData? activePointLayer;
  final GeoLayersData? activeLineLayer;
  final GeoLayersData? activePolygonLayer;

  final Map<String, List<LatLng>> visiblePointDrafts;
  final Map<String, List<LatLng>> visibleLineDrafts;
  final Map<String, List<LatLng>> visiblePolygonDrafts;

  final bool isLoading;
  final bool showFloatingStatus;

  const GeoMapData({
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

  factory GeoMapData.fromStates({
    required GeoLayersCubit layersCubit,
    required GeoMapCubit mapCubit,
    required GeoFeatureCubit featureCubit,
    required GeoLayersState layersState,
    required GeoMapState mapState,
    required GeoFeatureState featureState,
    required GeoToolboxState toolboxState,
  }) {
    final currentTree = layersState.tree;
    final activeLayerIds = layersState.activeLayerIds;

    final allNodes = layersCubit.flattenAllNodes(tree: currentTree);

    final layersById = <String, GeoLayersData>{
      for (final node in allNodes.where((e) => !e.isGroup)) node.id: node,
    };

    final orderedLeafIdsTopToBottom = layersCubit
        .flattenOrderedLeafIds(tree: currentTree)
        .where(activeLayerIds.contains)
        .toList(growable: false);

    final orderedActiveLayerIdsForMap =
    orderedLeafIdsTopToBottom.reversed.toList(growable: false);

    final visibleFeatures = <GeoFeatureData>[];
    for (final layerId in orderedActiveLayerIdsForMap) {
      visibleFeatures.addAll(
        featureState.featuresByLayer[layerId] ?? const <GeoFeatureData>[],
      );
    }

    final activePointLayer = mapCubit.getActiveDraftPointLayer(currentTree);
    final activeLineLayer = mapCubit.getActiveDraftLineLayer(currentTree);
    final activePolygonLayer = mapCubit.getActiveDraftPolygonLayer(currentTree);

    final isLoading = featureState.isAnyLoading ||
        featureState.isImportBusy ||
        layersState.isSaving ||
        layersState.isRefreshingLayerData;

    final showFloatingStatus = PopUpStatusBar.shouldShow(
      editorState: mapState,
      measurementState: toolboxState,
      activePointLayer: activePointLayer,
      activeLineLayer: activeLineLayer,
      activePolygonLayer: activePolygonLayer,
    );

    return GeoMapData(
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