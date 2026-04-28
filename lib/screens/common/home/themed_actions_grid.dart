import 'package:flutter/material.dart';

import 'package:sipged/_blocs/system/module/module_data.dart';
import 'package:sipged/_blocs/system/module/module_permission.dart' as perms;
import 'package:sipged/_blocs/system/user/user_data.dart';
import 'package:sipged/_widgets/menu/drawer/menu_drawer_item.dart';
import 'package:sipged/screens/common/home/home_tip.dart';
import 'package:sipged/screens/common/home/module_data_item.dart';
import 'package:sipged/screens/common/home/module_empty.dart';
import 'package:sipged/screens/common/home/section_data.dart';
import 'package:sipged/screens/common/home/section_spec.dart';

class ThemedActionsGrid extends StatelessWidget {
  const ThemedActionsGrid({
    super.key,
    this.onSelect,
    required this.user,
  });

  final void Function(ModuleItem item)? onSelect;
  final UserData? user;

  bool _can(UserData? user, String module) {
    if (user == null) return false;

    return perms.userCanModule(
      user: user,
      module: module,
      action: 'read',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return const SizedBox.shrink();
    }

    final sections = ModuleData.homeGroups
        .map((group) => _fromGroup(group, user!))
        .where((section) => section.items.isNotEmpty)
        .toList();

    if (sections.isEmpty) {
      return ModuleEmpty(isDark: isDark);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeTip(isDark: isDark),
        const SizedBox(height: 22),

        for (int i = 0; i < sections.length; i++) ...[
          if (i > 0) const SizedBox(height: 34),
          SectionGrid<ModuleItem>(
            title: sections[i].title,
            items: sections[i].items,
            onSelect: onSelect,
            isDark: isDark,
          ),
        ],
      ],
    );
  }

  SectionData<ModuleItem> _fromGroup(
      MenuDrawerItemModule group,
      UserData user,
      ) {
    final items = <ModuleDataItem<ModuleItem>>[];

    for (final sub in group.subItems) {
      if (!_can(user, sub.permissionModule)) continue;

      items.add(
        ModuleDataItem<ModuleItem>(
          icon: sub.homeIcon ?? group.icon,
          title: _normalizeTitle(sub.label),
          color: sub.homeColor ?? _fallbackColor(sub.permissionModule),
          value: sub.menuItem,
        ),
      );
    }

    return SectionData<ModuleItem>(
      title: group.label.trim().toUpperCase(),
      items: items,
    );
  }

  String _normalizeTitle(String value) {
    final text = value.trim();
    if (text.isEmpty) return 'Módulo';

    return text;
  }

  Color _fallbackColor(String module) {
    final hash = module.codeUnits.fold<int>(0, (a, b) => a + b);
    final hue = (hash % 360).toDouble();

    return HSVColor.fromAHSV(1, hue, 0.54, 0.56).toColor();
  }
}