
import 'package:flutter/material.dart';

class BotaoFlutuanteHover extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  const BotaoFlutuanteHover({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.onPressed,
  });

  @override
  State<BotaoFlutuanteHover> createState() => _BotaoFlutuanteHoverState();
}

class _BotaoFlutuanteHoverState extends State<BotaoFlutuanteHover> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPressed,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: Colors.white, size: 20),
              if (_hovering) ...[
                const SizedBox(width: 8),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _hovering ? 1 : 0,
                  child: Text(
                    widget.label,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}