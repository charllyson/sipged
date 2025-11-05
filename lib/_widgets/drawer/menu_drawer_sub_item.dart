
import 'package:flutter/material.dart';
import 'package:siged/_blocs/system/pages/pages_data.dart';
import 'package:siged/_blocs/system/user/user_data.dart';

class MenuDrawerSubItem {
  final String label;
  final MenuItem menuItem;
  final String permissionModule;

  /// Ícone exclusivo para o card da Home.
  /// Não é usado no Drawer (lá seguimos sem ícone por sub-item).
  final IconData? homeIcon;

  const MenuDrawerSubItem({
    required this.label,
    required this.menuItem,
    required this.permissionModule,
    this.homeIcon,
  });
}