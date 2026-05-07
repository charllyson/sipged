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

    final rawFromSnap = user.userSnap?.data();

    if (rawFromSnap != null) {
      return UserPermissionData.fromMap(
        uid: uid,
        map: rawFromSnap,
      );
    }

    final rawFromUser = <String, dynamic>{
      if (user.baseRole != null && user.baseRole!.trim().isNotEmpty)
        'baseRole': user.baseRole!.trim(),
      if (user.baseProfile != null && user.baseProfile!.trim().isNotEmpty)
        'baseProfile': user.baseProfile!.trim(),
    };

    if (rawFromUser.isNotEmpty) {
      return UserPermissionData.fromMap(
        uid: uid,
        map: rawFromUser,
      );
    }

    return UserPermissionData(
      uid: uid,
    );
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

    return permissions.canModuleString(
      module: cleanModule,
      action: 'read',
      tenantId: cleanTenantId(tenantId),
    );
  }

  static bool canModule({
    required UserPermissionData? permissions,
    required String? module,
    required String action,
    required String? tenantId,
  }) {
    final cleanModule = module?.trim();
    final cleanAction = action.trim().toLowerCase();

    if (permissions == null ||
        cleanModule == null ||
        cleanModule.isEmpty ||
        cleanAction.isEmpty) {
      return false;
    }

    return permissions.canModuleString(
      module: cleanModule,
      action: cleanAction,
      tenantId: cleanTenantId(tenantId),
    );
  }
}