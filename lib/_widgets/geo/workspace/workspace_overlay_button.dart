import 'package:flutter/material.dart';

class WorkspaceOverlayButton extends StatefulWidget {
  const WorkspaceOverlayButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onTap,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;
  final GestureDragStartCallback onPanStart;
  final GestureDragUpdateCallback onPanUpdate;
  final GestureDragEndCallback onPanEnd;

  @override
  State<WorkspaceOverlayButton> createState() => _WorkspaceOverlayButtonState();
}

class _WorkspaceOverlayButtonState extends State<WorkspaceOverlayButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.move,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          onPanStart: widget.onPanStart,
          onPanUpdate: widget.onPanUpdate,
          onPanEnd: widget.onPanEnd,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: _hovered ? 0.98 : 0.94),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: primary.withValues(alpha: _hovered ? 0.45 : 0.22),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              widget.icon,
              size: 16,
              color: primary,
            ),
          ),
        ),
      ),
    );
  }
}