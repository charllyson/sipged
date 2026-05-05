import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/system/module/module_data.dart';
import 'package:sipged/_blocs/system/permission/permission_cubit.dart';
import 'package:sipged/_blocs/system/permission/permission_data.dart' as perm;
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

  perm.UserPermissionData _fallbackPermissionFromUser(UserData user) {
    final uid = (user.uid ?? '').trim();
    final raw = user.userSnap?.data();

    if (raw is Map<String, dynamic>) {
      return perm.UserPermissionData.fromMap(
        uid: uid,
        map: raw,
      );
    }

    return perm.UserPermissionData(
      uid: uid,
    );
  }

  perm.UserPermissionData? _permissionDataOf(
      BuildContext context,
      UserData? user,
      ) {
    if (user == null) return null;

    final uid = (user.uid ?? '').trim();
    final permissionState = context.read<PermissionCubit>().state;
    final current = permissionState.current;

    if (current != null && current.uid.trim() == uid) {
      return current;
    }

    return _fallbackPermissionFromUser(user);
  }

  String? _activeTenantId(BuildContext context) {
    final id = context.read<PermissionCubit>().state.activeTenantId?.trim();

    if (id == null || id.isEmpty) return null;

    return id;
  }

  bool _can(
      BuildContext context,
      UserData? user,
      String module,
      ) {
    final permissions = _permissionDataOf(context, user);

    if (permissions == null) return false;

    return permissions.canModuleString(
      module: module,
      action: 'read',
      tenantId: _activeTenantId(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return const SizedBox.shrink();
    }

    return BlocBuilder<PermissionCubit, dynamic>(
      builder: (context, _) {
        final sections = ModuleData.homeGroups
            .map((group) => _fromGroup(context, group, user!))
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
      },
    );
  }

  SectionData<ModuleItem> _fromGroup(
      BuildContext context,
      MenuDrawerItemModule group,
      UserData user,
      ) {
    final items = <ModuleDataItem<ModuleItem>>[];

    for (final sub in group.subItems) {
      if (!_can(context, user, sub.permissionModule)) continue;

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