import 'package:flutter/material.dart';
import 'package:siged/_blocs/system/pages/pages_data.dart';

class MenuDrawerSubItem {
  final String label;
  final MenuItem menuItem;
  final String permissionModule;

  /// Ícone exclusivo do card da Home (se null, herda do grupo no ThemedActionsGrid)
  final IconData? homeIcon;

  /// Subtítulo do card da Home (se null, usa fallback no ThemedActionsGrid)
  final String? homeSubtitle;

  /// Cor do card da Home (se null, usa fallback no ThemedActionsGrid)
  final Color? homeColor;

  const MenuDrawerSubItem({
    required this.label,
    required this.menuItem,
    required this.permissionModule,
    this.homeIcon,
    this.homeSubtitle,
    this.homeColor,
  });
}
