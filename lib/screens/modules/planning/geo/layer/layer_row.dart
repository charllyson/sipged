import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data.dart';
import 'package:sipged/_widgets/texts/marquee_text.dart';
import 'package:sipged/screens/modules/planning/geo/layer/layer_preview.dart';

class LayerRow extends StatelessWidget {
  final LayerData layer;
  final int depth;
  final double rowHeight;
  final bool isActive;
  final bool isSelected;
  final bool hasData;
  final String? currentUserId;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggleLayer;

  /// Enquadra (zoom) o mapa nas feições desta camada.
  ///
  /// Disparado por clique direito (desktop/web), duplo clique/toque ou
  /// clique/toque e segurar (mobile).
  final VoidCallback? onZoomToLayer;

  const LayerRow({
    super.key,
    required this.layer,
    required this.depth,
    required this.rowHeight,
    required this.isActive,
    required this.isSelected,
    required this.hasData,
    this.currentUserId,
    required this.onTap,
    required this.onToggleLayer,
    this.onZoomToLayer,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isSelected ? const Color(0xFF1976D2) : Colors.transparent;
    final textColor = isSelected ? Colors.white : Colors.black87;
    final primaryCheckboxColor = Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: onTap,
      onDoubleTap: onZoomToLayer,
      onLongPress: onZoomToLayer,
      onSecondaryTap: onZoomToLayer,
      child: SizedBox(
        height: rowHeight,
        child: ColoredBox(
          color: bgColor,
          child: Padding(
            padding: EdgeInsets.only(
              left: 8.0 + (depth * 16.0),
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
                  child: LayerPreview(
                    layer: layer,
                    isSelected: isSelected,
                    isActive: isActive,
                    hasData: hasData,
                    currentUserId: currentUserId,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: MarqueeText(
                    text: layer.title,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}