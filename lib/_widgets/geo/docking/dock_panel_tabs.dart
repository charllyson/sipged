import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/docking/dock_panel_data.dart';

class DockPanelTabs extends StatelessWidget {
  final DockPanelData group;
  final Color accent;
  final ValueChanged<String> onTabSelected;

  const DockPanelTabs({
    super.key,
    required this.group,
    required this.accent,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final activeId = group.activeItem?.id;

    return Align(
      alignment: Alignment.bottomLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 4, right: 4, top: 1),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: group.items.map((item) {
            final active = item.id == activeId;

            return PanelTab(
              title: item.title,
              active: active,
              accent: accent,
              onTap: () => onTabSelected(item.id),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class PanelTab extends StatefulWidget {
  final String title;
  final bool active;
  final Color accent;
  final VoidCallback onTap;

  const PanelTab({
    super.key,
    required this.title,
    required this.active,
    required this.accent,
    required this.onTap,
  });

  @override
  State<PanelTab> createState() => _PanelTabState();
}

class _PanelTabState extends State<PanelTab> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final inactiveTextColor = isDark
        ? Colors.white.withValues(alpha: 0.84)
        : Colors.black.withValues(alpha: 0.78);

    final bgColor = widget.active
        ? (isDark ? const Color(0xFF182033) : Colors.white)
        : (_hovered
        ? (isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.04))
        : Colors.transparent);

    final borderColor = widget.active
        ? widget.accent.withValues(alpha: 0.55)
        : (isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.10));

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
          ),
          onTap: widget.onTap,
          child: Container(
            height: 28,
            margin: const EdgeInsets.only(right: 2),
            constraints: const BoxConstraints(minWidth: 7),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
              border: Border(
                top: BorderSide(color: borderColor),
                left: BorderSide(color: borderColor),
                right: BorderSide(color: borderColor),
              ),
            ),
            child: Text(
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: widget.active ? FontWeight.w700 : FontWeight.w600,
                color: widget.active ? widget.accent : inactiveTextColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}