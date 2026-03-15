import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/map/geo_map_state.dart';
import 'package:sipged/_blocs/modules/planning/geo/toolbox/geo_toolbox_state.dart';

class ToolboxStatus extends StatelessWidget {
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

  const ToolboxStatus({
    super.key,
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

  @override
  Widget build(BuildContext context) {
    final status = _resolveStatus(context);
    final hasActions = status.actions.isNotEmpty;

    return Material(
      color: const Color(0xFFF1F1F1),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
          8,
          hasActions ? 6 : 4,
          8,
          hasActions ? 6 : 4,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F1F1),
          border: Border(
            top: BorderSide(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.55),
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 22,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: status.texts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      status.texts[index],
                      maxLines: 1,
                      overflow: TextOverflow.visible,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.black87,
                      ),
                    ),
                  );
                },
              ),
            ),
            if (hasActions) ...[
              const SizedBox(height: 6),
              SizedBox(
                height: 28,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: status.actions.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (context, index) {
                    final action = status.actions[index];
                    return _MiniSquareButton(
                      tooltip: action.tooltip,
                      icon: action.icon,
                      onPressed: action.onPressed,
                      iconColor: action.iconColor,
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  _ToolboxResolvedStatus _resolveStatus(BuildContext context) {
    final measurement = _buildMeasurementStatus();
    if (measurement != null) return measurement;

    final point = _buildPointEditingStatus();
    if (point != null) return point;

    final line = _buildLineEditingStatus();
    if (line != null) return line;

    final polygon = _buildPolygonEditingStatus();
    if (polygon != null) return polygon;

    return const _ToolboxResolvedStatus(
      texts: ['Pronto para editar.'],
      actions: [],
    );
  }

  _ToolboxResolvedStatus? _buildMeasurementStatus() {
    if (!editorState.isMeasureDistanceToolSelected && measurementState.isEmpty) {
      return null;
    }

    final pointCount = measurementState.points.length;
    final segmentCount = measurementState.segmentDistancesMeters.length;

    final texts = <String>[
      'Medição de distância',
      'Pontos: $pointCount',
      'Trechos: $segmentCount',
      'Total: ${measurementState.totalDistanceLabel}',
      if (measurementState.hasSegments)
        'Último trecho: ${measurementState.lastSegmentLabel}',
    ];

    final actions = <_ToolboxStatusAction>[
      _ToolboxStatusAction(
        tooltip: 'Desfazer último ponto',
        icon: Icons.undo,
        onPressed: pointCount > 0 ? onUndoDistanceMeasurementPoint : null,
      ),
      _ToolboxStatusAction(
        tooltip: 'Limpar medição',
        icon: Icons.delete_sweep_outlined,
        onPressed: pointCount > 0 ? onClearDistanceMeasurement : null,
      ),
      _ToolboxStatusAction(
        tooltip: 'Concluir medição',
        icon: Icons.check,
        iconColor: Colors.green.shade700,
        onPressed: onFinishDistanceMeasurement,
      ),
    ];

    return _ToolboxResolvedStatus(
      texts: texts,
      actions: actions,
    );
  }

  _ToolboxResolvedStatus? _buildPointEditingStatus() {
    if (activePointLayer == null) return null;

    final pointCount =
        editorState.draftPointLayers[activePointLayer!.id]?.length ?? 0;

    return _ToolboxResolvedStatus(
      texts: [
        'Editando pontos',
        'Camada: ${activePointLayer!.title}',
        'Pontos em edição: $pointCount',
      ],
      actions: [
        _ToolboxStatusAction(
          tooltip: 'Concluir edição',
          icon: Icons.check,
          iconColor: Colors.green.shade700,
          onPressed:
          pointCount > 0 ? () => onFinalizeCurrentPointEditing() : null,
        ),
        _ToolboxStatusAction(
          tooltip: 'Cancelar edição',
          icon: Icons.close,
          onPressed: onCancelCurrentPointEditing,
        ),
      ],
    );
  }

  _ToolboxResolvedStatus? _buildLineEditingStatus() {
    if (activeLineLayer == null) return null;

    final vertexCount =
        editorState.draftLineLayers[activeLineLayer!.id]?.length ?? 0;

    return _ToolboxResolvedStatus(
      texts: [
        'Editando linha',
        'Camada: ${activeLineLayer!.title}',
        'Vértices em edição: $vertexCount',
        'Mínimo para concluir: 2',
      ],
      actions: [
        _ToolboxStatusAction(
          tooltip: 'Concluir linha',
          icon: Icons.check,
          iconColor: Colors.green.shade700,
          onPressed:
          vertexCount >= 2 ? () => onFinalizeCurrentLineEditing() : null,
        ),
        _ToolboxStatusAction(
          tooltip: 'Cancelar edição',
          icon: Icons.close,
          onPressed: onCancelCurrentLineEditing,
        ),
      ],
    );
  }

  _ToolboxResolvedStatus? _buildPolygonEditingStatus() {
    if (activePolygonLayer == null) return null;

    final vertexCount =
        editorState.draftPolygonLayers[activePolygonLayer!.id]?.length ?? 0;

    return _ToolboxResolvedStatus(
      texts: [
        'Editando polígono',
        'Camada: ${activePolygonLayer!.title}',
        'Vértices em edição: $vertexCount',
        'Mínimo para concluir: 3',
      ],
      actions: [
        _ToolboxStatusAction(
          tooltip: 'Concluir polígono',
          icon: Icons.check,
          iconColor: Colors.green.shade700,
          onPressed: vertexCount >= 3
              ? () => onFinalizeCurrentPolygonEditing()
              : null,
        ),
        _ToolboxStatusAction(
          tooltip: 'Cancelar edição',
          icon: Icons.close,
          onPressed: onCancelCurrentPolygonEditing,
        ),
      ],
    );
  }
}

class _ToolboxResolvedStatus {
  final List<String> texts;
  final List<_ToolboxStatusAction> actions;

  const _ToolboxResolvedStatus({
    required this.texts,
    required this.actions,
  });
}

class _ToolboxStatusAction {
  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? iconColor;

  const _ToolboxStatusAction({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.iconColor,
  });
}

class _MiniSquareButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? iconColor;

  const _MiniSquareButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;
    final borderColor =
    Theme.of(context).dividerColor.withValues(alpha: 0.70);
    final disabledColor =
    Theme.of(context).disabledColor.withValues(alpha: 0.90);

    return Tooltip(
      message: tooltip,
      child: Opacity(
        opacity: isEnabled ? 1 : 0.45,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(2),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F7),
                border: Border.all(color: borderColor),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 16,
                  color: isEnabled
                      ? (iconColor ?? Colors.black87)
                      : disabledColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}