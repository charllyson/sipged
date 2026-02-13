import 'package:flutter/material.dart';
import 'package:sipged/_blocs/system/module/module_data.dart';

class ActionItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final ModuleItem item;
  final String moduleKey;

  ActionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.item,
    required this.moduleKey,
  });
}
