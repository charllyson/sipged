// lib/_blocs/system/module/module_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/system/permission/permission_data.dart';
import 'package:sipged/_blocs/system/permission/permission_resolver.dart';
import 'package:sipged/_blocs/system/permission/permission_state.dart';
import 'package:sipged/_blocs/system/user/user_data.dart';

import 'module_catalog.dart';
import 'module_data.dart';
import 'module_state.dart';

class ModuleCubit extends Cubit<ModuleState> {
  ModuleCubit() : super(ModuleState.initial());

  void refreshFromUserAndPermissions({
    required UserData? user,
    required PermissionState permissionState,
  }) {
    final permissions = PermissionResolver.resolveForUser(
      user: user,
      permissionState: permissionState,
    );

    refreshFromPermissions(
      permissions: permissions,
      tenantId: permissionState.activeTenantId,
    );
  }

  void refreshFromPermissions({
    required UserPermissionData? permissions,
    required String? tenantId,
  }) {
    final drawerMainGroups = <ModuleGroupData>[
      ...ModuleCatalog.drawerDocuments,
      ...ModuleCatalog.drawerDepartments,
    ];

    emit(
      state.copyWith(
        visibleHomeGroups: _filterGroups(
          groups: ModuleCatalog.homeGroups,
          permissions: permissions,
          tenantId: tenantId,
          upperCaseLabel: true,
        ),
        visibleDrawerMainGroups: _filterGroups(
          groups: drawerMainGroups,
          permissions: permissions,
          tenantId: tenantId,
        ),
        visibleDrawerActiveGroups: _filterGroups(
          groups: ModuleCatalog.drawerActives,
          permissions: permissions,
          tenantId: tenantId,
        ),
        clearDeniedMessage: true,
      ),
    );
  }

  bool selectModule({
    required ModuleEnum item,
    required UserPermissionData? permissions,
    required String? tenantId,
  }) {
    final permissionModule = ModuleCatalog.permissionModuleOf(item);

    final canRead = PermissionResolver.canReadModule(
      permissions: permissions,
      module: permissionModule,
      tenantId: tenantId,
    );

    if (!canRead) {
      emit(
        state.copyWith(
          deniedMessage: 'Você não possui permissão para abrir este módulo.',
        ),
      );

      return false;
    }

    emit(
      state.copyWith(
        selectedItem: item,
        clearDeniedMessage: true,
      ),
    );

    return true;
  }

  void goHome() {
    emit(
      state.copyWith(
        clearSelectedItem: true,
        clearDeniedMessage: true,
      ),
    );
  }

  void clearDeniedMessage() {
    if (state.deniedMessage == null) return;

    emit(
      state.copyWith(
        clearDeniedMessage: true,
      ),
    );
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
}