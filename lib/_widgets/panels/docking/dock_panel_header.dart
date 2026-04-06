import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/docking/dock_panel_data.dart';

class DockPanelHeader extends StatelessWidget {
  final DockPanelData group;
  final Color accent;
  final bool isFloating;
  final VoidCallback onToggleFloating;
  final VoidCallback onHide;
  final VoidCallback? onMinimize;

  const DockPanelHeader({
    super.key,
    required this.group,
    required this.accent,
    required this.isFloating,
    required this.onToggleFloating,
    required this.onHide,
    this.onMinimize,
  });

  bool get _canCollapseToRail {
    if (group.floatingAsDialog) return false;

    if (group.area == DockArea.left || group.area == DockArea.right) {
      return true;
    }

    if (group.lastDockArea == DockArea.left ||
        group.lastDockArea == DockArea.right) {
      return true;
    }

    return false;
  }

  bool get _showMinimizeButton {
    return !isFloating &&
        !group.floatingAsDialog &&
        group.id == 'group_area_trabalho' &&
        group.visible;
  }

  IconData _collapseIcon() {
    final anchor = group.area == DockArea.left || group.area == DockArea.right
        ? group.area
        : group.lastDockArea;

    if (anchor == DockArea.left) return Icons.first_page;
    return Icons.last_page;
  }

  String _collapseTooltip() {
    return 'Recolher';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final headerColor =
    isDark ? const Color(0xFF2A2F3A) : const Color(0xFFF2F3F5);

    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.08);

    final textColor = isDark
        ? Colors.white.withValues(alpha: 0.90)
        : Colors.black.withValues(alpha: 0.85);

    final buttonColor =
    isDark ? Colors.white.withValues(alpha: 0.75) : Colors.black54;

    final isExpandedView = group.floatingAsDialog;

    return MouseRegion(
      cursor: group.floatingAsDialog
          ? SystemMouseCursors.basic
          : SystemMouseCursors.grab,
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: headerColor,
          border: Border(
            bottom: BorderSide(color: borderColor),
          ),
        ),
        child: Row(
          children: [
            if (group.icon != null) ...[
              const SizedBox(width: 3),
              Icon(group.icon, size: 16, color: textColor),
            ],
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                group.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            if (_showMinimizeButton && onMinimize != null)
              IconButton(
                tooltip: 'Minimizar',
                visualDensity: VisualDensity.compact,
                onPressed: onMinimize,
                icon: Icon(
                  Icons.remove,
                  size: 18,
                  color: buttonColor,
                ),
              ),
            IconButton(
              tooltip: isExpandedView ? 'Fechar' : 'Ampliar',
              visualDensity: VisualDensity.compact,
              onPressed: onToggleFloating,
              icon: Icon(
                isExpandedView ? Icons.close_fullscreen : Icons.open_in_full,
                size: 14,
                color: buttonColor,
              ),
            ),
            if (_canCollapseToRail)
              IconButton(
                tooltip: _collapseTooltip(),
                visualDensity: VisualDensity.compact,
                onPressed: onHide,
                icon: Icon(
                  _collapseIcon(),
                  size: 18,
                  color: buttonColor,
                ),
              ),
          ],
        ),
      ),
    );
  }
}