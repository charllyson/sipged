import 'package:sipged/_blocs/system/tenant/tenant_data.dart';
import 'package:sipged/_blocs/system/user/user_data.dart';

import '_blocs/system/permission/permission_data.dart' as perm;

class StartupContext {
  const StartupContext({
    required this.userData,
    required this.permissionData,
    required this.availableTenants,
    required this.allowedTenants,
    required this.selectedTenantId,
  });

  final UserData userData;
  final perm.UserPermissionData permissionData;
  final List<TenantData> availableTenants;
  final List<TenantData> allowedTenants;
  final String? selectedTenantId;
}
