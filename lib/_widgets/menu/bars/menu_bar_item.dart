import 'package:flutter/material.dart';

class MenuBarItem {
  final String label;
  final VoidCallback? onTap;
  final List<MenuBarItem> children;

  const MenuBarItem({
    required this.label,
    this.onTap,
    this.children = const [],
  });

  bool get hasChildren => children.isNotEmpty;
}
