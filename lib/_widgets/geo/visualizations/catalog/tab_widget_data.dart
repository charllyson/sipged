
import 'package:flutter/material.dart';

class TabWidgetsCatalog {
  final String id;
  final String title;
  final IconData icon;
  final String category;
  final String? description;

  const TabWidgetsCatalog({
    required this.id,
    required this.title,
    required this.icon,
    required this.category,
    this.description,
  });
}