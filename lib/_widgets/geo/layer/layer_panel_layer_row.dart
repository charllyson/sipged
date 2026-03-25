import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data.dart';
import 'package:sipged/_widgets/geo/layer/layer_action.dart';
import 'package:sipged/_widgets/geo/layer/layer_symbol_stack_preview.dart';

class LayerPanelLayerRow extends StatelessWidget {
  final GeoLayersData layer;
  final int depth;
  final double rowHeight;
  final double trailingActionSlot;
  final bool isActive;
  final bool isSelected;
  final bool canConnect;
  final LayerActionVisual visual;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggleLayer;
  final VoidCallback onActionTap;
  final VoidCallback onActionTapDown;

  const LayerPanelLayerRow({
    super.key,
    required this.layer,
    required this.depth,
    required this.rowHeight,
    required this.trailingActionSlot,
    required this.isActive,
    required this.isSelected,
    required this.canConnect,
    required this.visual,
    required this.onTap,
    required this.onToggleLayer,
    required this.onActionTap,
    required this.onActionTapDown,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isSelected ? const Color(0xFF1976D2) : Colors.transparent;
    final textColor = isSelected ? Colors.white : Colors.black87;

    final actionIconColor = isSelected
        ? Colors.white
        : (visual.hasData ? Colors.blue : Colors.grey.shade500);

    final primaryCheckboxColor = Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: rowHeight,
        child: ColoredBox(
          color: bgColor,
          child: Padding(
            padding: EdgeInsets.only(
              left: 8.0 + depth * 16.0,
              right: 8.0,
            ),
            child: Row(
              children: [
                const SizedBox(width: 14),
                SizedBox(
                  width: 18,
                  height: 18,
                  child: Transform.scale(
                    scale: 0.82,
                    child: Checkbox(
                      value: isActive,
                      onChanged: (v) => onToggleLayer(v ?? false),
                      activeColor: primaryCheckboxColor,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: const VisualDensity(
                        horizontal: -4,
                        vertical: -4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                RepaintBoundary(
                  child: LayerSymbolStackPreview(
                    layer: layer,
                    isSelected: isSelected,
                    isActive: isActive,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    layer.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
                SizedBox(
                  width: trailingActionSlot,
                  child: canConnect
                      ? Tooltip(
                    message: visual.tooltip,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (_) => onActionTapDown(),
                      onTap: onActionTap,
                      child: Center(
                        child: Icon(
                          visual.icon,
                          size: 18,
                          color: actionIconColor,
                        ),
                      ),
                    ),
                  )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}