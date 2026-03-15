import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/map/geo_map_state.dart';
import 'package:sipged/_blocs/modules/planning/geo/toolbox/geo_toolbox_state.dart';
import 'package:sipged/_widgets/geo/toolbox/toolbox_action_item.dart';
import 'package:sipged/_widgets/geo/toolbox/toolbox_panel.dart';
import 'package:sipged/_widgets/geo/toolbox/toolbox_status.dart';

class ToolboxContent extends StatelessWidget {
  final void Function(String message) onToolSelected;
  final ValueChanged<String?>? onSelectedTool;
  final List<ToolboxSectionData>? sections;
  final String? selectedToolId;

  final LayerGeometryKind? selectedLayerGeometryKind;
  final bool selectedItemIsGroup;

  final bool pointEditingActive;
  final bool lineEditingActive;
  final bool polygonEditingActive;

  final GeoMapState editorState;
  final GeoToolboxState measurementState;

  final GeoLayersData? activePointLayer;
  final GeoLayersData? activeLineLayer;
  final GeoLayersData? activePolygonLayer;

  final VoidCallback onUndoDistanceMeasurementPoint;
  final VoidCallback onClearDistanceMeasurement;
  final VoidCallback onFinishDistanceMeasurement;

  final Future<bool> Function() onFinalizeCurrentPointEditing;
  final Future<void> Function() onCancelCurrentPointEditing;

  final Future<bool> Function() onFinalizeCurrentLineEditing;
  final Future<void> Function() onCancelCurrentLineEditing;

  final Future<bool> Function() onFinalizeCurrentPolygonEditing;
  final Future<void> Function() onCancelCurrentPolygonEditing;

  const ToolboxContent({
    super.key,
    required this.onToolSelected,
    this.onSelectedTool,
    this.sections,
    this.selectedToolId,
    this.selectedLayerGeometryKind,
    this.selectedItemIsGroup = false,
    this.pointEditingActive = false,
    this.lineEditingActive = false,
    this.polygonEditingActive = false,
    required this.editorState,
    required this.measurementState,
    required this.activePointLayer,
    required this.activeLineLayer,
    required this.activePolygonLayer,
    required this.onUndoDistanceMeasurementPoint,
    required this.onClearDistanceMeasurement,
    required this.onFinishDistanceMeasurement,
    required this.onFinalizeCurrentPointEditing,
    required this.onCancelCurrentPointEditing,
    required this.onFinalizeCurrentLineEditing,
    required this.onCancelCurrentLineEditing,
    required this.onFinalizeCurrentPolygonEditing,
    required this.onCancelCurrentPolygonEditing,
  });

  bool get _hasSelectedEditableLayer =>
      !selectedItemIsGroup &&
          (selectedLayerGeometryKind == LayerGeometryKind.point ||
              selectedLayerGeometryKind == LayerGeometryKind.line ||
              selectedLayerGeometryKind == LayerGeometryKind.polygon);

  bool _isGeometryEnabled(LayerGeometryKind geometryKind) {
    if (!_hasSelectedEditableLayer) return true;
    return selectedLayerGeometryKind == geometryKind;
  }

  bool _showEditBadge(LayerGeometryKind geometryKind) {
    switch (geometryKind) {
      case LayerGeometryKind.point:
        return pointEditingActive;
      case LayerGeometryKind.line:
        return lineEditingActive;
      case LayerGeometryKind.polygon:
        return polygonEditingActive;
      default:
        return false;
    }
  }

  List<ToolboxSectionData> _defaultSections() {
    return [
      ToolboxSectionData(
        id: 'navigation',
        actions: [
          ToolboxActionItem(
            id: 'tool_measure',
            tooltip: 'Medir distância',
            icon: Icons.straighten_outlined,
            children: [
              ToolboxActionItem(
                id: 'tool_measure_distance',
                tooltip: 'Medir Distância',
                icon: Icons.route_outlined,
                onTap: () => onToolSelected(
                  'Ferramenta "Medir distância" selecionada.',
                ),
              ),
              ToolboxActionItem(
                id: 'tool_measure_area',
                tooltip: 'Medir Área',
                icon: Icons.square_foot_outlined,
                onTap: () => onToolSelected(
                  'Ferramenta "Medir área" selecionada.',
                ),
              ),
            ],
          ),
        ],
      ),
      ToolboxSectionData(
        id: 'drawing',
        actions: [
          ToolboxActionItem(
            id: 'tool_point',
            tooltip: _showEditBadge(LayerGeometryKind.point)
                ? 'Editar pontos'
                : 'Adicionar pontos',
            icon: Icons.location_on_outlined,
            geometryKind: LayerGeometryKind.point,
            enabled: _isGeometryEnabled(LayerGeometryKind.point),
            showEditBadge: _showEditBadge(LayerGeometryKind.point),
            onTap: () => onToolSelected(
              _showEditBadge(LayerGeometryKind.point)
                  ? 'Modo edição de pontos ativado para a camada selecionada.'
                  : 'Ferramenta "Ponto" ativada. Clique no mapa para criar uma nova camada de pontos.',
            ),
          ),
          ToolboxActionItem(
            id: 'tool_line',
            tooltip: _showEditBadge(LayerGeometryKind.line)
                ? 'Editar linhas'
                : 'Criar linhas',
            icon: Icons.polyline_outlined,
            geometryKind: LayerGeometryKind.line,
            enabled: _isGeometryEnabled(LayerGeometryKind.line),
            showEditBadge: _showEditBadge(LayerGeometryKind.line),
            onTap: () => onToolSelected(
              _showEditBadge(LayerGeometryKind.line)
                  ? 'Modo edição de linhas ativado para a camada selecionada.'
                  : 'Ferramenta "Nova linha" selecionada.',
            ),
          ),
          ToolboxActionItem(
            id: 'tool_polygon',
            tooltip: _showEditBadge(LayerGeometryKind.polygon)
                ? 'Editar polígonos'
                : 'Criar polígonos',
            icon: Icons.pentagon_outlined,
            geometryKind: LayerGeometryKind.polygon,
            enabled: _isGeometryEnabled(LayerGeometryKind.polygon),
            showEditBadge: _showEditBadge(LayerGeometryKind.polygon),
            onTap: () => onToolSelected(
              _showEditBadge(LayerGeometryKind.polygon)
                  ? 'Modo edição de polígonos ativado para a camada selecionada.'
                  : 'Ferramenta "Novo polígono" selecionada.',
            ),
          ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ToolboxPanel(
            sections: sections ?? _defaultSections(),
            selectedToolId: selectedToolId,
            onSelected: onSelectedTool,
            iconSize: 20,
            buttonSize: 40,
          ),
        ),
        ToolboxStatus(
          editorState: editorState,
          measurementState: measurementState,
          activePointLayer: activePointLayer,
          activeLineLayer: activeLineLayer,
          activePolygonLayer: activePolygonLayer,
          onUndoDistanceMeasurementPoint: onUndoDistanceMeasurementPoint,
          onClearDistanceMeasurement: onClearDistanceMeasurement,
          onFinishDistanceMeasurement: onFinishDistanceMeasurement,
          onFinalizeCurrentPointEditing: onFinalizeCurrentPointEditing,
          onCancelCurrentPointEditing: onCancelCurrentPointEditing,
          onFinalizeCurrentLineEditing: onFinalizeCurrentLineEditing,
          onCancelCurrentLineEditing: onCancelCurrentLineEditing,
          onFinalizeCurrentPolygonEditing: onFinalizeCurrentPolygonEditing,
          onCancelCurrentPolygonEditing: onCancelCurrentPolygonEditing,
        ),
      ],
    );
  }
}