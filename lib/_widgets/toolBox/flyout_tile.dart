import 'package:flutter/material.dart';
import 'package:siged/_widgets/toolBox/tool_dock.dart';

class FlyoutTile extends StatefulWidget {
  const FlyoutTile({
    required this.icon,
    required this.label,
    required this.hasSide,
    this.onTap,
    this.onHover,
  });

  final IconData icon;
  final String label;
  final bool hasSide;
  final VoidCallback? onTap;
  final VoidCallback? onHover;

  @override
  State<FlyoutTile> createState() => _FlyoutTileState();
}

class _FlyoutTileState extends State<FlyoutTile> {
  static const _hoverOrange = Color(0xFFFFA500); // borda laranja no hover
  static const _activeBlue  = Color(0xFF8CC8FF); // azul clarinho no clique

  bool _hover = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bg = _hover ? const Color(0x14FFFFFF) : Colors.transparent; // leve fill no hover
    final dx = _hover ? 0.5 : 0.0;

    // prioridade: pressed => azul, senão hover => laranja, senão sem borda
    final Color? borderColor = _pressed
        ? _activeBlue
        : (_hover ? _hoverOrange : null);
    final double borderWidth = (_pressed || _hover) ? 1 : 0;

    return MouseRegion(
      onEnter: (_) {
        setState(() => _hover = true);
        widget.onHover?.call(); // mantém/abre submenu no hover
      },
      onExit: (_) => setState(() { _hover = false; _pressed = false; }),
      child: Material(
        color: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          transform: Matrix4.identity()..translate(dx, 0.0),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(6),
            border: borderColor == null
                ? null
                : Border.all(color: borderColor, width: borderWidth),
          ),
          child: InkWell(
            onHighlightChanged: (v) => setState(() => _pressed = v),
            onTap: widget.onTap,
            splashColor: Colors.white.withOpacity(0.10),
            highlightColor: Colors.white.withOpacity(0.06),
            hoverColor: Colors.transparent, // usamos nosso bg animado
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 180),
              child: SizedBox(
                height: ToolDockState.kItemExtent,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Icon(widget.icon, color: Colors.white, size: 18),
                      const SizedBox(width: 10),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          widget.label,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      if (widget.hasSide)
                        const Icon(Icons.arrow_right, color: Colors.white70, size: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
