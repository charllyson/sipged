import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_widgets/texts/divider_text.dart';
import 'package:siged/_widgets/drawer/menu_drawer_sub_item.dart';
import 'package:siged/_blocs/system/pages/pages_data.dart';
import 'package:siged/_blocs/system/user/user_data.dart';
import 'package:siged/_widgets/images/sisgeo_logo.dart';

// BLoC
import 'package:siged/_blocs/system/user/user_bloc.dart';
import 'package:siged/_blocs/system/user/user_event.dart';
import 'package:siged/_blocs/system/user/user_state.dart';

// Permissões centralizadas
import 'package:siged/_blocs/system/permitions/page_permission.dart' as perms;

class DrawerMenu extends StatefulWidget {
  final void Function(MenuItem) onTap;

  /// Novo: callback para ir para a Home (limpar seleção)
  final VoidCallback? onTapHome;

  const DrawerMenu({
    super.key,
    required this.onTap,
    this.onTapHome,
  });

  @override
  State<DrawerMenu> createState() => _DrawerMenuState();
}

class _DrawerMenuState extends State<DrawerMenu> {
  final User? _firebaseUser = FirebaseAuth.instance.currentUser;
  bool _didInit = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _didInit) return;
      _didInit = true;
      context.read<UserBloc>().add(const UserWarmupRequested(
        listenRealtime: true,
        bindCurrentUser: true,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 250,
      backgroundColor: const Color(0xFF1B2033),
      child: BlocBuilder<UserBloc, UserState>(
        builder: (context, state) {
          final userData = _resolveCurrentUserData(state);

          if (_firebaseUser == null) {
            return const Center(
              child: Text('Não autenticado', style: TextStyle(color: Colors.white70)),
            );
          }

          if (userData == null || state.isLoadingUsers) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: SiGedLogo(
                  fontSize: 40,
                  heightLogo: 30,
                  widthLogo: 30,
                  onTapHome: () {
                    // fecha o Drawer e avisa o pai pra ir pra Home
                    Navigator.of(context).maybePop();
                    widget.onTapHome?.call();
                  },
                ),
              ),
              const SizedBox(height: 12),

              // ====== DOCUMENTOS ======
              ...(() {
                final docsGroups = <Widget>[
                  ...PagesData.panelDashboard
                      .map((item) => _buildExpandableGroup(
                    icon: item.icon,
                    label: item.label,
                    children: item.subItems,
                    user: userData,
                  ))
                      .whereType<Widget>(),
                  ...PagesData.drawerDocuments
                      .map((item) => _buildExpandableGroup(
                    icon: item.icon,
                    label: item.label,
                    children: item.subItems,
                    user: userData,
                  ))
                      .whereType<Widget>(),
                ];
                if (docsGroups.isEmpty) return const <Widget>[];
                return <Widget>[
                  DividerText(
                    title: 'DOCUMENTOS',
                    colorTitle: Colors.white38,
                    subTitle: Colors.white24,
                  ),
                  const SizedBox(height: 8),
                  ...docsGroups,
                  const SizedBox(height: 12),
                ];
              })(),

              // ====== SETORES ======
              ...(() {
                final deptGroups = <Widget>[
                  ...PagesData.drawerDepartments
                      .map((item) => _buildExpandableGroup(
                    icon: item.icon,
                    label: item.label,
                    children: item.subItems,
                    user: userData,
                  ))
                      .whereType<Widget>(),
                ];
                if (deptGroups.isEmpty) return const <Widget>[];
                return <Widget>[
                  DividerText(
                    title: 'SETORES',
                    colorTitle: Colors.white38,
                    subTitle: Colors.white24,
                  ),
                  const SizedBox(height: 8),
                  ...deptGroups,
                  const SizedBox(height: 12),
                ];
              })(),

              // ====== ATIVOS ======
              ...(() {
                final activeGroups = <Widget>[
                  ...PagesData.drawerActives
                      .map((item) => _buildExpandableGroup(
                    icon: item.icon,
                    label: item.label,
                    children: item.subItems,
                    user: userData,
                  ))
                      .whereType<Widget>(),
                ];
                if (activeGroups.isEmpty) return const <Widget>[];
                return <Widget>[
                  DividerText(
                    title: 'ATIVOS',
                    colorTitle: Colors.white38,
                    subTitle: Colors.white24,
                  ),
                  const SizedBox(height: 8),
                  ...activeGroups,
                  const SizedBox(height: 20),
                ];
              })(),
            ],
          );
        },
      ),
    );
  }

  UserData? _resolveCurrentUserData(UserState state) {
    if (state.current != null) return state.current;
    final uid = _firebaseUser?.uid;
    if (uid != null && uid.isNotEmpty) return state.byId[uid];
    return null;
  }

  Widget? _buildExpandableGroup({
    required IconData icon,
    required String label,
    required List<MenuDrawerSubItem> children,
    required UserData user,
  }) {
    final visible = children
        .where((s) => perms.userCanModule(
      user: user,
      module: s.permissionModule,
      action: 'read',
    ))
        .toList();

    if (visible.isEmpty) return null;

    return Theme(
      data: ThemeData.dark().copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(label, style: const TextStyle(color: Colors.white)),
        iconColor: Colors.white,
        collapsedIconColor: Colors.white,
        children: visible
            .map((s) => _SubMenuRowSimple(
          label: s.label,
          onTap: () => widget.onTap(s.menuItem),
        ))
            .toList(),
      ),
    );
  }
}

class _SubMenuRowSimple extends StatefulWidget {
  const _SubMenuRowSimple({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  State<_SubMenuRowSimple> createState() => _SubMenuRowSimpleState();
}

class _SubMenuRowSimpleState extends State<_SubMenuRowSimple> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          color: _hover ? Colors.white10 : Colors.transparent,
          padding: const EdgeInsets.only(left: 48, right: 12),
          height: 44,
          alignment: Alignment.centerLeft,
          child: Text(
            widget.label,
            style: TextStyle(
              color: _hover ? Colors.white : Colors.white70,
              fontSize: 14,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}
