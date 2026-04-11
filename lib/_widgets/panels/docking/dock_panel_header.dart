import 'package:flutter/material.dart';
import 'package:sipged/_blocs/system/panels/docking/dock_panel_data.dart';

class DockPanelHeader extends StatelessWidget {
  final DockPanelData group;
  final Color accent;
  final bool isFloating;
  final VoidCallback onToggleFloating;

  const DockPanelHeader({
    super.key,
    required this.group,
    required this.accent,
    required this.isFloating,
    required this.onToggleFloating,
  });

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

    return Container(
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
        ],
      ),
    );
  }
}