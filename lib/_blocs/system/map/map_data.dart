import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

import 'package:sipged/_blocs/modules/planning/geo/feature/feature_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/feature_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/feature_state.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_state.dart';
import 'package:sipged/_blocs/modules/planning/geo/toolbox/toolbox_state.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/workspace_filter.dart';
import 'package:sipged/_blocs/system/map/map_cubit.dart';
import 'package:sipged/_blocs/system/map/map_state.dart';
import 'package:sipged/screens/modules/planning/geo/status/status_bar.dart';

class MapDraftData extends Equatable {
  const MapDraftData({
    required this.layerId,
    required this.vertices,
    this.ownedTemporaryLayer = false,
  });

  final String layerId;
  final List<LatLng> vertices;
  final bool ownedTemporaryLayer;

  MapDraftData copyWith({
    String? layerId,
    List<LatLng>? vertices,
    bool? ownedTemporaryLayer,
  }) {
    return MapDraftData(
      layerId: layerId ?? this.layerId,
      vertices: vertices == null
          ? this.vertices
          : List<LatLng>.unmodifiable(vertices),
      ownedTemporaryLayer: ownedTemporaryLayer ?? this.ownedTemporaryLayer,
    );
  }

  @override
  List<Object?> get props => [
    layerId,
    vertices,
    ownedTemporaryLayer,
  ];
}

class MarkerDataChange extends Equatable {
  const MarkerDataChange({
    required this.id,
    required this.layerId,
    required this.point,
    this.properties = const <String, dynamic>{},
  });

  final String id;
  final String layerId;
  final LatLng point;
  final Map<String, dynamic> properties;

  @override
  List<Object?> get props => [
    id,
    layerId,
    point,
    properties,
  ];
}

class PolylineDataChange extends Equatable {
  const PolylineDataChange({
    required this.id,
    required this.layerId,
    required this.points,
    this.properties = const <String, dynamic>{},
  });

  final String id;
  final String layerId;
  final List<LatLng> points;
  final Map<String, dynamic> properties;

  @override
  List<Object?> get props => [
    id,
    layerId,
    points,
    properties,
  ];
}

class PolygonDataChange extends Equatable {
  const PolygonDataChange({
    required this.id,
    required this.layerId,
    required this.points,
    this.properties = const <String, dynamic>{},
  });

  final String id;
  final String layerId;
  final List<LatLng> points;
  final Map<String, dynamic> properties;

  @override
  List<Object?> get props => [
    id,
    layerId,
    points,
    properties,
  ];
}

class LayerDataMap extends Equatable {
  const LayerDataMap({
    required this.currentTree,
    required this.activeLayerIds,
    required this.hasDataByLayer,
    required this.layersById,
    required this.orderedLeafIdsTopToBottom,
    required this.orderedActiveLayerIdsForMap,
    required this.visibleFeatures,
    required this.selectedFeatureKey,
    required this.workspaceFilter,
    required this.activePointLayer,
    required this.activeLineLayer,
    required this.activePolygonLayer,
    required this.visiblePointDrafts,
    required this.visibleLineDrafts,
    required this.visiblePolygonDrafts,
    required this.isLoading,
    required this.showFloatingStatus,
    required this.hasDataSignature,
  });

  final List<LayerData> currentTree;
  final Set<String> activeLayerIds;
  final Map<String, bool> hasDataByLayer;

  final Map<String, LayerData> layersById;
  final List<String> orderedLeafIdsTopToBottom;
  final List<String> orderedActiveLayerIdsForMap;

  /// Feições já filtradas conforme:
  /// - camadas ativas;
  /// - filtro ativo da área de trabalho, quando existir.
  final List<FeatureData> visibleFeatures;

  final String? selectedFeatureKey;

  /// Filtro atual vindo dos widgets da Área de Trabalho.
  final WorkspaceFilter? workspaceFilter;

  final LayerData? activePointLayer;
  final LayerData? activeLineLayer;
  final LayerData? activePolygonLayer;

  final Map<String, List<LatLng>> visiblePointDrafts;
  final Map<String, List<LatLng>> visibleLineDrafts;
  final Map<String, List<LatLng>> visiblePolygonDrafts;

  final bool isLoading;
  final bool showFloatingStatus;
  final int hasDataSignature;

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

    final allVisibleFeatures = <FeatureData>[];

    for (final layerId in orderedActiveLayerIdsForMap) {
      final features = featureState.featuresByLayer[layerId];

      if (features != null && features.isNotEmpty) {
        allVisibleFeatures.addAll(features);
      }
    }

    final filteredVisibleFeatures = _applyWorkspaceFilterToFeatures(
      features: allVisibleFeatures,
      filter: mapState.workspaceFilter,
    );

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

    final hasDataSignature = Object.hashAll(
      layersState.hasDataByLayer.entries.map(
            (e) => Object.hash(e.key, e.value),
      ),
    );

    return LayerDataMap(
      currentTree: currentTree,
      activeLayerIds: activeLayerIds,
      hasDataByLayer: layersState.hasDataByLayer,
      layersById: layersById,
      orderedLeafIdsTopToBottom: orderedLeafIdsTopToBottom,
      orderedActiveLayerIdsForMap: orderedActiveLayerIdsForMap,
      visibleFeatures: List<FeatureData>.unmodifiable(filteredVisibleFeatures),
      selectedFeatureKey: featureState.selected?.feature.selectionKey,
      workspaceFilter: mapState.workspaceFilter,
      activePointLayer: activePointLayer,
      activeLineLayer: activeLineLayer,
      activePolygonLayer: activePolygonLayer,
      visiblePointDrafts: mapCubit.buildVisiblePointDrafts(activeLayerIds),
      visibleLineDrafts: mapCubit.buildVisibleLineDrafts(activeLayerIds),
      visiblePolygonDrafts: mapCubit.buildVisiblePolygonDrafts(activeLayerIds),
      isLoading: isLoading,
      showFloatingStatus: showFloatingStatus,
      hasDataSignature: hasDataSignature,
    );
  }

  static List<FeatureData> _applyWorkspaceFilterToFeatures({
    required List<FeatureData> features,
    required WorkspaceFilter? filter,
  }) {
    if (filter == null || !filter.isValid) {
      return features;
    }

    final sourceLayerId = filter.sourceLayerId.trim();
    final sourceField = filter.sourceField.trim();

    if (sourceLayerId.isEmpty || sourceField.isEmpty) {
      return features;
    }

    return features.where((feature) {
      final featureLayerId = (feature.layerId ?? '').trim();

      /// Mantém as outras camadas visíveis.
      ///
      /// O clique no gráfico filtra apenas a camada que alimenta aquele gráfico.
      if (featureLayerId != sourceLayerId) {
        return true;
      }

      return _featureMatchesWorkspaceFilter(
        feature: feature,
        filter: filter,
      );
    }).toList(growable: false);
  }

  static bool _featureMatchesWorkspaceFilter({
    required FeatureData feature,
    required WorkspaceFilter filter,
  }) {
    final rawValue = _featureWorkspaceFilterValue(
      feature,
      filter.sourceField,
    );

    final normalizedFeatureValue = _normalizeFilterValue(rawValue);
    final normalizedFilterLabel = _normalizeFilterValue(filter.label);

    return normalizedFeatureValue == normalizedFilterLabel;
  }

  static dynamic _featureWorkspaceFilterValue(
      FeatureData feature,
      String field,
      ) {
    if (feature.editedProperties.containsKey(field)) {
      return feature.editedProperties[field];
    }

    return feature.originalProperties[field];
  }

  static String _normalizeFilterValue(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? 'Sem rótulo' : text;
  }

  Object get workspaceFilterToken {
    final filter = workspaceFilter;

    if (filter == null || !filter.isValid) {
      return 'no_workspace_filter';
    }

    return Object.hash(
      filter.sourceItemId,
      filter.sourceLayerId,
      filter.sourceField,
      filter.label,
      filter.value,
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
    workspaceFilter,
    activePointLayer,
    activeLineLayer,
    activePolygonLayer,
    visiblePointDrafts,
    visibleLineDrafts,
    visiblePolygonDrafts,
    isLoading,
    showFloatingStatus,
    hasDataSignature,
  ];
}