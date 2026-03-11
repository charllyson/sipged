import 'package:flutter/material.dart';

class ToolButtons {
  final String id;
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final Widget Function(VoidCallback close)? sideBuilder;
  final bool sideOpenToLeft; // não é mais usado para direcionar – mantido por compat
  final double sideMaxHeight;

  const ToolButtons({
    required this.id,
    required this.icon,
    required this.tooltip,
    this.onTap,
    this.sideBuilder,
    this.sideOpenToLeft = true,
    this.sideMaxHeight = 320,
  });
}
