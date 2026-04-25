import 'package:flutter/material.dart';

class ModuleDataItem<T> {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final T value;

  const ModuleDataItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.value,
  });
}
