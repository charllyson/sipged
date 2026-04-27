import 'package:flutter/material.dart';

class ModuleDataItem<T> {
  final String title;
  final IconData icon;
  final Color color;
  final T value;

  const ModuleDataItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.value,
  });
}
