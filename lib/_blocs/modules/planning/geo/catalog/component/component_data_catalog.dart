import 'package:flutter/material.dart';

@immutable
class ComponentDataCatalog {
  final String id;
  final String title;
  final IconData icon;
  final String category;
  final String? description;

  const ComponentDataCatalog({
    required this.id,
    required this.title,
    required this.icon,
    required this.category,
    this.description,
  });
}