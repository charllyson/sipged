import 'package:flutter/material.dart';

class WorkspaceCloseButton extends StatefulWidget {
  const WorkspaceCloseButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  State<WorkspaceCloseButton> createState() => _WorkspaceCloseButtonState();
}

class _WorkspaceCloseButtonState extends State<WorkspaceCloseButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Remover widget',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: InkWell(
          onTap: widget.onPressed,
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: _hovered ? 0.98 : 0.94),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.black.withValues(alpha: _hovered ? 0.18 : 0.10),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.close,
              size: 16,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}