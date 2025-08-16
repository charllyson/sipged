import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sisged/_widgets/texts/divider_text.dart';
import '../../_blocs/system/user_bloc.dart';
import '../../_datas/system/pages_data.dart';
import '../../_datas/system/user_data.dart';
import '../../_widgets/background/sisgeo_logo.dart';

class DrawerItemModel {
  final String label;
  final IconData icon;
  final List<DrawerSubItem> subItems;

  DrawerItemModel({
    required this.label,
    required this.icon,
    required this.subItems,
  });
}

class DrawerSubItem {
  final String label;
  final MenuItem menuItem;
  final String permissionModule;
  final bool Function(UserData user)? hasPermissionOverride;

  DrawerSubItem({
    required this.label,
    required this.menuItem,
    required this.permissionModule,
    this.hasPermissionOverride,
  });
}

class DrawerMenu extends StatefulWidget {
  final void Function(MenuItem) onTap;

  const DrawerMenu({super.key, required this.onTap});

  @override
  State<DrawerMenu> createState() => _DrawerMenuState();
}

class _DrawerMenuState extends State<DrawerMenu> {
  late final UserBloc userBloc = UserBloc();
  final User? firebaseUser = FirebaseAuth.instance.currentUser;



  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 250,
      backgroundColor: const Color(0xFF1B2033),
      child: FutureBuilder<UserData?>(
        future: userBloc.getUserData(uid: firebaseUser?.uid ?? ''),
        builder: (context, snapshot) {
          final userData = snapshot.data;
          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: SisGedLogo(
                  fontSize: 40,
                  heightLogo: 30,
                  widthLogo: 30,
                ),
              ),
              const SizedBox(height: 20),
              DividerText(
                  title: 'DOCUMENTOS',
                  subtitle: 'do órgão',
                  colorTitle: Colors.white38,
                  subTitle: Colors.white24
              ),
              ...PagesData.drawerDocuments.map((item) {
                final visibleSubItems = item.subItems.where((sub) {
                  if (userData == null) return false;
                  final perms = userData.modulePermissions[sub.permissionModule] ?? {};
                  final hasPermission = perms['read'] ?? false;
                  return sub.hasPermissionOverride?.call(userData) ?? hasPermission;
                }).toList();

                if (visibleSubItems.isEmpty) return const SizedBox();

                return _buildExpandableItem(item.icon, item.label, visibleSubItems);
              }).toList(),
              const SizedBox(height: 20),
              DividerText(
                  title: 'SETORES',
                  subtitle: 'do órgão',
                  colorTitle: Colors.white38,
                  subTitle: Colors.white24
              ),
              const SizedBox(height: 20),
              ...PagesData.drawerDepartments.map((item) {
                final visibleSubItems = item.subItems.where((sub) {
                  if (userData == null) return false;
                  final perms = userData.modulePermissions[sub.permissionModule] ?? {};
                  final hasPermission = perms['read'] ?? false;
                  return sub.hasPermissionOverride?.call(userData) ?? hasPermission;
                }).toList();

                if (visibleSubItems.isEmpty) return const SizedBox();

                return _buildExpandableItem(item.icon, item.label, visibleSubItems);
              }).toList(),
              const SizedBox(height: 20),
              DividerText(
                  title: 'ATIVOS',
                  subtitle: 'do órgão',
                  colorTitle: Colors.white38,
                  subTitle: Colors.white24
              ),
              const SizedBox(height: 20),
              ...PagesData.drawerModals.map((item) {
                final visibleSubItems = item.subItems.where((sub) {
                  if (userData == null) return false;
                  final perms = userData.modulePermissions[sub.permissionModule] ?? {};
                  final hasPermission = perms['read'] ?? false;
                  return sub.hasPermissionOverride?.call(userData) ?? hasPermission;
                }).toList();

                if (visibleSubItems.isEmpty) return const SizedBox();

                return _buildExpandableItem(item.icon, item.label, visibleSubItems);
              }).toList(),
              const SizedBox(height: 20)
            ],
          );
        },
      ),
    );
  }

  Widget _buildExpandableItem(
      IconData icon,
      String label,
      List<DrawerSubItem> children,
      ) {
    return Theme(
      data: ThemeData.dark().copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(label, style: const TextStyle(color: Colors.white)),
        iconColor: Colors.white,
        collapsedIconColor: Colors.white,
        children: children.map(_buildSubItem).toList(),
      ),
    );
  }

  Widget _buildSubItem(DrawerSubItem sub) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 48, right: 16),
      leading: const Icon(Icons.chevron_right, color: Colors.white54, size: 20),
      title: Text(sub.label, style: const TextStyle(color: Colors.white70)),
      onTap: () => widget.onTap(sub.menuItem),
    );
  }
}
