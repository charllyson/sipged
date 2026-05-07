// lib/_blocs/system/module/module_access_guard.dart

import 'package:flutter/material.dart';

import 'package:sipged/_blocs/system/module/module_catalog.dart';
import 'package:sipged/_blocs/system/module/module_data.dart';

import 'package:sipged/_blocs/system/permission/permission_data.dart';
import 'package:sipged/_blocs/system/permission/permission_resolver.dart';

import 'package:sipged/screens/common/modules/module_access_denied.dart';

class ModuleAccessGuard {
  const ModuleAccessGuard._();

  static String permissionModuleOf(ModuleEnum item) {
    return ModuleCatalog.permissionModuleOf(item);
  }

  static bool canRead({
    required ModuleEnum item,
    required UserPermissionData? permissions,
    required String? tenantId,
  }) {
    return PermissionResolver.canReadModule(
      permissions: permissions,
      module: permissionModuleOf(item),
      tenantId: tenantId,
    );
  }

  static String titleOf(ModuleEnum item) {
    return ModuleCatalog.labelModuleOf(item);
  }

  static Widget deniedPage({
    required ModuleEnum item,
    String? message,
  }) {
    return ModuleAccessDeniedPage(
      title: titleOf(item),
      message: message,
    );
  }
}