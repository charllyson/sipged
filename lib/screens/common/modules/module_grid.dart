// lib/screens/common/modules/module_grid.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/system/module/module_catalog.dart';
import 'package:sipged/_blocs/system/module/module_cubit.dart';
import 'package:sipged/_blocs/system/module/module_data.dart';

import 'package:sipged/_blocs/system/permission/permission_cubit.dart';
import 'package:sipged/_blocs/system/permission/permission_data.dart';
import 'package:sipged/_blocs/system/permission/permission_resolver.dart';
import 'package:sipged/_blocs/system/permission/permission_state.dart';

import 'package:sipged/_blocs/system/user/user_data.dart';

import 'package:sipged/screens/common/home/home_tip.dart';
import 'package:sipged/screens/common/modules/module_empty.dart';
import 'package:sipged/screens/common/modules/section_spec.dart';

class ModuleGrid extends StatelessWidget {
  const ModuleGrid({
    super.key,
    this.onSelect,
    required this.user,
  });

  final void Function(ModuleEnum item)? onSelect;
  final UserData? user;

  @override
  Widget build(BuildContext context) {
    final currentUser = user;

    if (currentUser == null) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<PermissionCubit, PermissionState>(
      buildWhen: (previous, current) {
        return previous.current != current.current ||
            previous.activeTenantId != current.activeTenantId ||
            previous.hasLoaded != current.hasLoaded ||
            previous.isLoading != current.isLoading;
      },
      builder: (context, permissionState) {
        final permissions = PermissionResolver.resolveForUser(
          user: currentUser,
          permissionState: permissionState,
        );

        final sections = _filterGroups(
          groups: ModuleCatalog.homeGroups,
          permissions: permissions,
          tenantId: permissionState.activeTenantId,
          upperCaseLabel: true,
        );

        _syncModuleCubit(
          context: context,
          user: currentUser,
          permissionState: permissionState,
        );

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
              SectionGrid(
                title: sections[i].labelSection,
                sectionIcon: sections[i].iconSection,
                sectionColor: _resolveSectionColor(sections[i]),
                items: sections[i].moduleItems,
                onSelect: onSelect,
                isDark: isDark,
              ),
            ],
          ],
        );
      },
    );
  }

  void _syncModuleCubit({
    required BuildContext context,
    required UserData user,
    required PermissionState permissionState,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;

      context.read<ModuleCubit>().refreshFromUserAndPermissions(
        user: user,
        permissionState: permissionState,
      );
    });
  }

  List<ModuleGroupData> _filterGroups({
    required List<ModuleGroupData> groups,
    required UserPermissionData? permissions,
    required String? tenantId,
    bool upperCaseLabel = false,
  }) {
    final visibleGroups = <ModuleGroupData>[];

    for (final group in groups) {
      final visibleItems = <ModuleData>[];

      for (final item in group.moduleItems) {
        final permissionModule = item.permissionModule.trim();

        if (permissionModule.isEmpty) continue;

        final canRead = PermissionResolver.canReadModule(
          permissions: permissions,
          module: permissionModule,
          tenantId: tenantId,
        );

        if (!canRead) continue;

        visibleItems.add(item);
      }

      if (visibleItems.isEmpty) continue;

      final label = group.labelSection.trim();

      visibleGroups.add(
        ModuleGroupData(
          labelSection: upperCaseLabel ? label.toUpperCase() : label,
          iconSection: group.iconSection,
          colorSectionLabel: group.colorSectionLabel,
          moduleItems: visibleItems,
        ),
      );
    }

    return visibleGroups;
  }

  Color _resolveSectionColor(ModuleGroupData section) {
    for (final item in section.moduleItems) {
      final color = item.homeModuleColor;

      if (color != null) {
        return color;
      }
    }

    if (section.moduleItems.isNotEmpty) {
      return _fallbackColor(
        section.moduleItems.first.permissionModule,
      );
    }

    return const Color(0xFF0EA5E9);
  }

  Color _fallbackColor(String module) {
    final cleanModule = module.trim();

    if (cleanModule.isEmpty) {
      return const Color(0xFF0EA5E9);
    }

    final hash = cleanModule.codeUnits.fold<int>(
      0,
          (previous, current) => previous + current,
    );

    final hue = (hash % 360).toDouble();

    return HSVColor.fromAHSV(
      1,
      hue,
      0.54,
      0.56,
    ).toColor();
  }
}