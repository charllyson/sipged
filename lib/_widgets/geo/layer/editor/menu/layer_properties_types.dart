import 'package:flutter/material.dart';

enum LayerPropertiesTab {
  general,
  symbology,
  labels,
  source,
  metadata,
}

class LayerPropertiesMenuItemData {
  final LayerPropertiesTab tab;
  final IconData icon;
  final String title;
  final String subtitle;

  const LayerPropertiesMenuItemData({
    required this.tab,
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}