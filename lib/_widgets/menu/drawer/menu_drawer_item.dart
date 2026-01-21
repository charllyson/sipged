import 'package:flutter/material.dart';

import 'menu_drawer_sub_item.dart';

class MenuDrawerItemModule {
  final String label;
  final IconData icon;
  final List<MenuDrawerSubItem> subItems;

  MenuDrawerItemModule({
    required this.label,
    required this.icon,
    required this.subItems,
  });
}