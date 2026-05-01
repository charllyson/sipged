import 'package:flutter/material.dart';

class MenuSubItem extends StatefulWidget {
  const MenuSubItem({super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  State<MenuSubItem> createState() => _MenuSubItemState();
}

class _MenuSubItemState extends State<MenuSubItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          color: _hover ? Colors.white10 : Colors.transparent,
          padding: const EdgeInsets.only(left: 48, right: 12),
          height: 44,
          alignment: Alignment.centerLeft,
          child: Text(
            widget.label,
            style: TextStyle(
              color: _hover ? Colors.white : Colors.white70,
              fontSize: 14,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}