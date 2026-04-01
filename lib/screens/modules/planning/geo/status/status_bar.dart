import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/map/map_state.dart';
import 'package:sipged/_blocs/modules/planning/geo/toolbox/toolbox_state.dart';
import 'package:sipged/_widgets/cards/basic/basic_card.dart';

class StatusBar extends StatelessWidget {
  final MapState editorState;
  final ToolboxState measurementState;

  final LayerData? activePointLayer;
  final LayerData? activeLineLayer;
  final LayerData? activePolygonLayer;

  final VoidCallback onUndoDistanceMeasurementPoint;
  final VoidCallback onClearDistanceMeasurement;
  final VoidCallback onFinishDistanceMeasurement;

  final Future<bool> Function() onFinalizeCurrentPointEditing;
  final Future<void> Function() onCancelCurrentPointEditing;

  final Future<bool> Function() onFinalizeCurrentLineEditing;
  final Future<void> Function() onCancelCurrentLineEditing;

  final Future<bool> Function() onFinalizeCurrentPolygonEditing;
  final Future<void> Function() onCancelCurrentPolygonEditing;

  final VoidCallback? onClose;

  const StatusBar({
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
    this.onClose,
  });

  static bool shouldShow({
    required MapState editorState,
    required ToolboxState measurementState,
    required LayerData? activePointLayer,
    required LayerData? activeLineLayer,
    required LayerData? activePolygonLayer,
  }) {
    final isMeasuring =
        editorState.isMeasureDistanceToolSelected || !measurementState.isEmpty;

    final isEditingPoint = activePointLayer != null;
    final isEditingLine = activeLineLayer != null;
    final isEditingPolygon = activePolygonLayer != null;

    return isMeasuring || isEditingPoint || isEditingLine || isEditingPolygon;
  }

  @override
  Widget build(BuildContext context) {
    final status = _resolveStatus();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: BasicCard(
            isDark: isDark,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            borderRadius: 16,
            useGlassEffect: true,
            blurSigmaX: 14,
            blurSigmaY: 14,
            backgroundColor: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.16),
            borderColor: isDark
                ? Colors.white.withValues(alpha: 0.16)
                : Colors.white.withValues(alpha: 0.42),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.10),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                Colors.white.withValues(alpha: 0.10),
                Colors.white.withValues(alpha: 0.03),
              ]
                  : [
                Colors.white.withValues(alpha: 0.26),
                Colors.white.withValues(alpha: 0.08),
              ],
            ),
            child: Row(
              children: [
                _LeadingIcon(
                  icon: status.headerIcon,
                  accentColor: status.accentColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ...status.texts.map(
                              (text) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _StatusInlineChip(
                              label: text,
                              accentColor: status.accentColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (status.actions.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ...status.actions.map(
                            (action) => Padding(
                          padding: const EdgeInsets.only(left: 2),
                          child: _IconOnlyActionButton(
                            tooltip: action.tooltip,
                            icon: action.icon,
                            onPressed: action.onPressed,
                            color: action.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (onClose != null) ...[
                  const SizedBox(width: 4),
                  _CloseStatusButton(onPressed: onClose!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  _ToolboxResolvedStatus _resolveStatus() {
    final measurement = _buildMeasurementStatus();
    if (measurement != null) return measurement;

    final point = _buildPointEditingStatus();
    if (point != null) return point;

    final line = _buildLineEditingStatus();
    if (line != null) return line;

    final polygon = _buildPolygonEditingStatus();
    if (polygon != null) return polygon;

    return const _ToolboxResolvedStatus(
      headerIcon: Icons.check_circle_outline_rounded,
      accentColor: Color(0xFF4B5563),
      texts: ['Pronto'],
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
      'Medição',
      'Pontos: $pointCount',
      'Trechos: $segmentCount',
      'Total: ${measurementState.totalDistanceLabel}',
      if (measurementState.hasSegments)
        'Último: ${measurementState.lastSegmentLabel}',
    ];

    final actions = <_ToolboxStatusAction>[
      _ToolboxStatusAction(
        tooltip: 'Desfazer último ponto',
        icon: Icons.undo_rounded,
        onPressed: pointCount > 0 ? onUndoDistanceMeasurementPoint : null,
        color: const Color(0xFF334155),
      ),
      _ToolboxStatusAction(
        tooltip: 'Limpar medição',
        icon: Icons.delete_sweep_rounded,
        onPressed: pointCount > 0 ? onClearDistanceMeasurement : null,
        color: const Color(0xFFDC2626),
      ),
      _ToolboxStatusAction(
        tooltip: 'Concluir medição',
        icon: Icons.check_rounded,
        onPressed: onFinishDistanceMeasurement,
        color: const Color(0xFF16A34A),
      ),
    ];

    return _ToolboxResolvedStatus(
      headerIcon: Icons.straighten_rounded,
      accentColor: const Color(0xFF2563EB),
      texts: texts,
      actions: actions,
    );
  }

  _ToolboxResolvedStatus? _buildPointEditingStatus() {
    if (activePointLayer == null) return null;

    final pointCount =
        editorState.draftPointLayers[activePointLayer!.id]?.length ?? 0;

    return _ToolboxResolvedStatus(
      headerIcon: Icons.location_on_rounded,
      accentColor: const Color(0xFF7C3AED),
      texts: [
        'Pontos',
        'Camada: ${activePointLayer!.title}',
        'Em edição: $pointCount',
      ],
      actions: [
        _ToolboxStatusAction(
          tooltip: 'Concluir edição',
          icon: Icons.check_rounded,
          onPressed:
          pointCount > 0 ? () => onFinalizeCurrentPointEditing() : null,
          color: const Color(0xFF16A34A),
        ),
        _ToolboxStatusAction(
          tooltip: 'Cancelar edição',
          icon: Icons.close_rounded,
          onPressed: onCancelCurrentPointEditing,
          color: const Color(0xFFDC2626),
        ),
      ],
    );
  }

  _ToolboxResolvedStatus? _buildLineEditingStatus() {
    if (activeLineLayer == null) return null;

    final vertexCount =
        editorState.draftLineLayers[activeLineLayer!.id]?.length ?? 0;

    return _ToolboxResolvedStatus(
      headerIcon: Icons.timeline_rounded,
      accentColor: const Color(0xFF0F766E),
      texts: [
        'Linha',
        'Camada: ${activeLineLayer!.title}',
        'Vértices: $vertexCount',
        'Mín.: 2',
      ],
      actions: [
        _ToolboxStatusAction(
          tooltip: 'Concluir linha',
          icon: Icons.check_rounded,
          onPressed:
          vertexCount >= 2 ? () => onFinalizeCurrentLineEditing() : null,
          color: const Color(0xFF16A34A),
        ),
        _ToolboxStatusAction(
          tooltip: 'Cancelar edição',
          icon: Icons.close_rounded,
          onPressed: onCancelCurrentLineEditing,
          color: const Color(0xFFDC2626),
        ),
      ],
    );
  }

  _ToolboxResolvedStatus? _buildPolygonEditingStatus() {
    if (activePolygonLayer == null) return null;

    final vertexCount =
        editorState.draftPolygonLayers[activePolygonLayer!.id]?.length ?? 0;

    return _ToolboxResolvedStatus(
      headerIcon: Icons.hexagon_rounded,
      accentColor: const Color(0xFFEA580C),
      texts: [
        'Polígono',
        'Camada: ${activePolygonLayer!.title}',
        'Vértices: $vertexCount',
        'Mín.: 3',
      ],
      actions: [
        _ToolboxStatusAction(
          tooltip: 'Concluir polígono',
          icon: Icons.check_rounded,
          onPressed: vertexCount >= 3
              ? () => onFinalizeCurrentPolygonEditing()
              : null,
          color: const Color(0xFF16A34A),
        ),
        _ToolboxStatusAction(
          tooltip: 'Cancelar edição',
          icon: Icons.close_rounded,
          onPressed: onCancelCurrentPolygonEditing,
          color: const Color(0xFFDC2626),
        ),
      ],
    );
  }
}

class _ToolboxResolvedStatus {
  final IconData headerIcon;
  final Color accentColor;
  final List<String> texts;
  final List<_ToolboxStatusAction> actions;

  const _ToolboxResolvedStatus({
    required this.headerIcon,
    required this.accentColor,
    required this.texts,
    required this.actions,
  });
}

class _ToolboxStatusAction {
  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;

  const _ToolboxStatusAction({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    required this.color,
  });
}

class _LeadingIcon extends StatelessWidget {
  final IconData icon;
  final Color accentColor;

  const _LeadingIcon({
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.18),
        ),
      ),
      child: Icon(
        icon,
        size: 17,
        color: accentColor,
      ),
    );
  }
}

class _StatusInlineChip extends StatelessWidget {
  final String label;
  final Color accentColor;

  const _StatusInlineChip({
    required this.label,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.10)
            : Colors.white.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.10),
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : const Color(0xFF1F2937),
        ),
      ),
    );
  }
}

class _IconOnlyActionButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;

  const _IconOnlyActionButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    return Tooltip(
      message: tooltip,
      child: Opacity(
        opacity: enabled ? 1 : 0.34,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 28,
              height: 28,
              child: Center(
                child: Icon(
                  icon,
                  size: 18,
                  color: enabled ? color : Theme.of(context).disabledColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CloseStatusButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _CloseStatusButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Tooltip(
      message: 'Fechar',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 28,
            height: 28,
            child: Center(
              child: Icon(
                Icons.close_rounded,
                size: 18,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
            ),
          ),
        ),
      ),
    );
  }
}