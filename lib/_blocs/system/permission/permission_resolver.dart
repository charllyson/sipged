// lib/_blocs/system/permission/permission_resolver.dart

import 'package:sipged/_blocs/system/permission/permission_data.dart';
import 'package:sipged/_blocs/system/permission/permission_state.dart';
import 'package:sipged/_blocs/system/user/user_data.dart';

class PermissionResolver {
  const PermissionResolver._();

  static String? cleanTenantId(String? tenantId) {
    final id = tenantId?.trim();

    if (id == null || id.isEmpty) {
      return null;
    }

    return id;
  }

  static UserPermissionData? resolveForUser({
    required UserData? user,
    required PermissionState permissionState,
  }) {
    if (user == null) {
      return null;
    }

    final uid = user.uid?.trim();

    if (uid == null || uid.isEmpty) {
      return null;
    }

    final current = permissionState.current;

    if (current != null && current.uid.trim() == uid) {
      return current;
    }

    return UserPermissionData(
      uid: uid,
    );
  }

  static bool canAccessTenant({
    required UserPermissionData? permissions,
    required String? tenantId,
  }) {
    final cleanTenant = cleanTenantId(tenantId);

    if (permissions == null || cleanTenant == null) {
      return false;
    }

    return permissions.canAccessTenant(cleanTenant);
  }

  static bool canReadModule({
    required UserPermissionData? permissions,
    required String? module,
    required String? tenantId,
  }) {
    final cleanModule = module?.trim();

    if (permissions == null || cleanModule == null || cleanModule.isEmpty) {
      return false;
    }

    return permissions.canModule(
      module: cleanModule,
      action: PermissionType.read,
      tenantId: cleanTenantId(tenantId),
    );
  }

  static bool canModule({
    required UserPermissionData? permissions,
    required String? module,
    required PermissionType action,
    required String? tenantId,
  }) {
    final cleanModule = module?.trim();

    if (permissions == null || cleanModule == null || cleanModule.isEmpty) {
      return false;
    }

    return permissions.canModule(
      module: cleanModule,
      action: action,
      tenantId: cleanTenantId(tenantId),
    );
  }

  static bool canModuleString({
    required UserPermissionData? permissions,
    required String? module,
    required String action,
    required String? tenantId,
  }) {
    final cleanModule = module?.trim();
    final parsedAction = PermissionActionCodec.tryParse(action);

    if (permissions == null ||
        cleanModule == null ||
        cleanModule.isEmpty ||
        parsedAction == null) {
      return false;
    }

    return permissions.canModule(
      module: cleanModule,
      action: parsedAction,
      tenantId: cleanTenantId(tenantId),
    );
  }
}