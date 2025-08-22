import 'package:flutter/material.dart';

import 'menu_drawer_sub_item.dart';

class MenuDrawerItemModel {
  final String label;
  final IconData icon;
  final List<MenuDrawerSubItem> subItems;

  MenuDrawerItemModel({
    required this.label,
    required this.icon,
    required this.subItems,
  });
}