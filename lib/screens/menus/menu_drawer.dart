import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:sisged/_widgets/texts/divider_text.dart';
import 'package:sisged/_datas/system/menu_drawer_sub_item.dart';
import 'package:sisged/_datas/system/pages_data.dart';
import 'package:sisged/_datas/system/user_data.dart';
import 'package:sisged/_widgets/background/sisgeo_logo.dart';
import 'package:sisged/_blocs/system/user_provider.dart';

class DrawerMenu extends StatefulWidget {
  final void Function(MenuItem) onTap;

  const DrawerMenu({super.key, required this.onTap});

  @override
  State<DrawerMenu> createState() => _DrawerMenuState();
}

class _DrawerMenuState extends State<DrawerMenu> {
  final User? firebaseUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 250,
      backgroundColor: const Color(0xFF1B2033),
      child: Consumer<UserProvider>(
        builder: (_, userProvider, __) {
          final UserData? userData = userProvider.userData;

          // Loading/sem usuário
          if (userData == null || firebaseUser == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: SisGedLogo(fontSize: 40, heightLogo: 30, widthLogo: 30),
              ),
              const SizedBox(height: 20),

              DividerText(
                title: 'DOCUMENTOS',
                subtitle: 'do órgão',
                colorTitle: Colors.white38,
                subTitle: Colors.white24,
              ),
              ...PagesData.drawerDocuments
                  .map((item) => _maybeBuildExpandableItem(item.icon, item.label, item.subItems, userData))
                  .whereType<Widget>()
                  ,

              const SizedBox(height: 20),
              DividerText(
                title: 'SETORES',
                subtitle: 'do órgão',
                colorTitle: Colors.white38,
                subTitle: Colors.white24,
              ),
              const SizedBox(height: 20),
              ...PagesData.drawerDepartments
                  .map((item) => _maybeBuildExpandableItem(item.icon, item.label, item.subItems, userData))
                  .whereType<Widget>()
                  ,

              const SizedBox(height: 20),
              DividerText(
                title: 'ATIVOS',
                subtitle: 'do órgão',
                colorTitle: Colors.white38,
                subTitle: Colors.white24,
              ),
              const SizedBox(height: 20),
              ...PagesData.drawerModals
                  .map((item) => _maybeBuildExpandableItem(item.icon, item.label, item.subItems, userData))
                  .whereType<Widget>()
                  ,

              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  /// Filtra subitens pelo permissionamento do usuário; retorna null se não houver itens visíveis.
  Widget? _maybeBuildExpandableItem(
      IconData icon,
      String label,
      List<MenuDrawerSubItem> children,
      UserData user,
      ) {
    final visible = children.where((sub) => _hasReadPermission(user, sub)).toList();
    if (visible.isEmpty) return null;
    return _buildExpandableItem(icon, label, visible);
  }

  bool _hasReadPermission(UserData user, MenuDrawerSubItem sub) {
    // Se houver override customizado, aplica.
    if (sub.hasPermissionOverride != null) {
      return sub.hasPermissionOverride!(user);
    }
    // Senão, aplica regra padrão: módulo precisa ter 'read' = true.
    final perms = user.modulePermissions[sub.permissionModule] ?? {};
    return perms['read'] == true;
  }

  Widget _buildExpandableItem(
      IconData icon,
      String label,
      List<MenuDrawerSubItem> children,
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

  Widget _buildSubItem(MenuDrawerSubItem sub) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 48, right: 16),
      leading: const Icon(Icons.chevron_right, color: Colors.white54, size: 20),
      title: Text(sub.label, style: const TextStyle(color: Colors.white70)),
      onTap: () => widget.onTap(sub.menuItem),
    );
  }
}
