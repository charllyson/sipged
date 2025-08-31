
import 'package:siged/_blocs/system/pages/pages_data.dart';
import 'package:siged/_blocs/system/user/user_data.dart';

class MenuDrawerSubItem {
  final String label;
  final MenuItem menuItem;
  final String permissionModule;
  final bool Function(UserData user)? hasPermissionOverride;

  MenuDrawerSubItem({
    required this.label,
    required this.menuItem,
    required this.permissionModule,
    this.hasPermissionOverride,
  });
}