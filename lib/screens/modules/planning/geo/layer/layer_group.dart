import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data.dart';
import 'package:sipged/_widgets/draw/icons/icons_change_catalog.dart';
import 'package:sipged/_widgets/texts/marquee_text.dart';

class LayerGroup extends StatelessWidget {
  final LayerData group;
  final int depth;
  final double rowHeight;
  final bool isExpanded;
  final bool isSelected;
  final bool hoveringInside;
  final bool? checkboxValue;
  final VoidCallback onTap;
  final VoidCallback onToggleExpand;
  final VoidCallback onToggleGroupVisibility;

  /// Enquadra (zoom) o mapa nas feições de todas as camadas deste grupo.
  ///
  /// Disparado por clique direito (desktop/web), duplo clique/toque ou
  /// clique/toque e segurar (mobile).
  final VoidCallback? onZoomToGroup;

  const LayerGroup({
    super.key,
    required this.group,
    required this.depth,
    required this.rowHeight,
    required this.isExpanded,
    required this.isSelected,
    required this.hoveringInside,
    required this.checkboxValue,
    required this.onTap,
    required this.onToggleExpand,
    required this.onToggleGroupVisibility,
    this.onZoomToGroup,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = hoveringInside
        ? const Color(0xFFB3E5FC)
        : isSelected
        ? const Color(0xFF1976D2)
        : Colors.transparent;

    final textColor = isSelected ? Colors.white : Colors.black87;
    final iconColor = isSelected ? Colors.white : Colors.grey.shade800;
    final primaryCheckboxColor = Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: onTap,
      onDoubleTap: onZoomToGroup,
      onLongPress: onZoomToGroup,
      onSecondaryTap: onZoomToGroup,
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
                const SizedBox(width: 4),
                SizedBox(
                  width: 18,
                  height: 18,
                  child: Transform.scale(
                    scale: 0.82,
                    child: Checkbox(
                      value: checkboxValue,
                      tristate: true,
                      onChanged: (_) => onToggleGroupVisibility(),
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
                Icon(
                  IconsCatalog.iconFor(group.displayIconKey),
                  size: 18,
                  color: iconColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: MarqueeText(
                    text: group.title,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(
                  width: 28,
                  child: IconButton(
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    onPressed: onToggleExpand,
                    icon: Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_down
                          : Icons.chevron_right,
                      color: iconColor,
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