import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data.dart';
import 'package:sipged/_blocs/system/docking/dock_panel_data.dart';

class MapState extends Equatable {
  final List<DockPanelData> panelGroups;

  final String? selectedToolId;
  final String? selectedLayerPanelItemId;

  final String? activeEditingPointLayerId;
  final String? activeEditingLineLayerId;
  final String? activeEditingPolygonLayerId;

  final Set<String> draftOwnedTemporaryLayerIds;

  final Map<String, List<LatLng>> draftPointLayers;
  final Map<String, List<LatLng>> draftLineLayers;
  final Map<String, List<LatLng>> draftPolygonLayers;

  const MapState({
    this.panelGroups = const [],
    this.selectedToolId,
    this.selectedLayerPanelItemId,
    this.activeEditingPointLayerId,
    this.activeEditingLineLayerId,
    this.activeEditingPolygonLayerId,
    this.draftOwnedTemporaryLayerIds = const <String>{},
    this.draftPointLayers = const <String, List<LatLng>>{},
    this.draftLineLayers = const <String, List<LatLng>>{},
    this.draftPolygonLayers = const <String, List<LatLng>>{},
  });

  factory MapState.initial() {
    return const MapState(
      panelGroups: [
        DockPanelData(
          id: 'group_area_trabalho',
          title: 'Área de trabalho',
          area: DockArea.bottom,
          crossSpan: DockCrossSpan.full,
          visible: true,
          dockExtent: 260,
          dockWeight: 1.0,
          icon: Icons.space_dashboard_outlined,
          shrinkWrapOnMainAxis: false,
          items: [
            DockPanelData(
              id: 'workspace_area_main',
              title: 'Área de trabalho',
              icon: Icons.space_dashboard_outlined,
              contentPadding: EdgeInsets.zero,
              child: SizedBox.shrink(),
            ),
          ],
          activeItemId: 'workspace_area_main',
        ),
      ],
    );
  }

  bool get isPointToolSelected => selectedToolId == 'tool_point';
  bool get isLineToolSelected => selectedToolId == 'tool_line';
  bool get isPolygonToolSelected => selectedToolId == 'tool_polygon';
  bool get isMeasureDistanceToolSelected =>
      selectedToolId == 'tool_measure_distance';
  bool get isMeasureAreaToolSelected => selectedToolId == 'tool_measure_area';

  bool get hasPointDraftInProgress => activeEditingPointLayerId != null;
  bool get hasLineDraftInProgress => activeEditingLineLayerId != null;
  bool get hasPolygonDraftInProgress => activeEditingPolygonLayerId != null;

  bool get hasAnyVectorEditingInProgress =>
      hasPointDraftInProgress ||
          hasLineDraftInProgress ||
          hasPolygonDraftInProgress;

  MouseCursor get mapCursor {
    switch (selectedToolId) {
      case 'tool_point':
      case 'tool_line':
      case 'tool_polygon':
      case 'tool_measure_distance':
      case 'tool_measure_area':
        return SystemMouseCursors.precise;
      default:
        return SystemMouseCursors.basic;
    }
  }

  String? activeEditingLayerIdFor(LayerGeometryKind kind) {
    switch (kind) {
      case LayerGeometryKind.point:
        return activeEditingPointLayerId;
      case LayerGeometryKind.line:
        return activeEditingLineLayerId;
      case LayerGeometryKind.polygon:
        return activeEditingPolygonLayerId;
      case LayerGeometryKind.mixed:
      case LayerGeometryKind.unknown:
        return null;
    }
  }

  Map<String, List<LatLng>> draftsFor(LayerGeometryKind kind) {
    switch (kind) {
      case LayerGeometryKind.point:
        return draftPointLayers;
      case LayerGeometryKind.line:
        return draftLineLayers;
      case LayerGeometryKind.polygon:
        return draftPolygonLayers;
      case LayerGeometryKind.mixed:
      case LayerGeometryKind.unknown:
        return const <String, List<LatLng>>{};
    }
  }

  Map<String, List<LatLng>> buildVisibleDrafts(
      LayerGeometryKind kind,
      Set<String> activeLayerIds,
      ) {
    final source = draftsFor(kind);
    final out = <String, List<LatLng>>{};

    for (final entry in source.entries) {
      if (activeLayerIds.contains(entry.key) && entry.value.isNotEmpty) {
        out[entry.key] = entry.value;
      }
    }

    return out;
  }

  MapState copyWith({
    List<DockPanelData>? panelGroups,
    String? selectedToolId,
    bool clearSelectedTool = false,
    String? selectedLayerPanelItemId,
    bool clearSelectedLayerPanelItem = false,
    String? activeEditingPointLayerId,
    bool clearActiveEditingPointLayerId = false,
    String? activeEditingLineLayerId,
    bool clearActiveEditingLineLayerId = false,
    String? activeEditingPolygonLayerId,
    bool clearActiveEditingPolygonLayerId = false,
    Set<String>? draftOwnedTemporaryLayerIds,
    Map<String, List<LatLng>>? draftPointLayers,
    Map<String, List<LatLng>>? draftLineLayers,
    Map<String, List<LatLng>>? draftPolygonLayers,
  }) {
    return MapState(
      panelGroups: panelGroups ?? this.panelGroups,
      selectedToolId:
      clearSelectedTool ? null : (selectedToolId ?? this.selectedToolId),
      selectedLayerPanelItemId: clearSelectedLayerPanelItem
          ? null
          : (selectedLayerPanelItemId ?? this.selectedLayerPanelItemId),
      activeEditingPointLayerId: clearActiveEditingPointLayerId
          ? null
          : (activeEditingPointLayerId ?? this.activeEditingPointLayerId),
      activeEditingLineLayerId: clearActiveEditingLineLayerId
          ? null
          : (activeEditingLineLayerId ?? this.activeEditingLineLayerId),
      activeEditingPolygonLayerId: clearActiveEditingPolygonLayerId
          ? null
          : (activeEditingPolygonLayerId ?? this.activeEditingPolygonLayerId),
      draftOwnedTemporaryLayerIds:
      draftOwnedTemporaryLayerIds ?? this.draftOwnedTemporaryLayerIds,
      draftPointLayers: draftPointLayers ?? this.draftPointLayers,
      draftLineLayers: draftLineLayers ?? this.draftLineLayers,
      draftPolygonLayers: draftPolygonLayers ?? this.draftPolygonLayers,
    );
  }

  @override
  List<Object?> get props => [
    panelGroups,
    selectedToolId,
    selectedLayerPanelItemId,
    activeEditingPointLayerId,
    activeEditingLineLayerId,
    activeEditingPolygonLayerId,
    draftOwnedTemporaryLayerIds,
    draftPointLayers,
    draftLineLayers,
    draftPolygonLayers,
  ];
}