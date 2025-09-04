import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_widgets/texts/divider_text.dart';
import 'package:siged/_widgets/drawer/menu_drawer_sub_item.dart';
import 'package:siged/_blocs/system/pages/pages_data.dart';
import 'package:siged/_blocs/system/user/user_data.dart';
import 'package:siged/_widgets/background/sisgeo_logo.dart';

// BLoC
import 'package:siged/_blocs/system/user/user_bloc.dart';
import 'package:siged/_blocs/system/user/user_event.dart';
import 'package:siged/_blocs/system/user/user_state.dart';

/// Estrutura interna para mesclar "PAINEL" com o próximo subitem de página.
class MergedSubItem {
  MergedSubItem({
    required this.label,
    required this.pageItem,
    required this.pagePermission,
    this.dashboardItem,
    this.dashboardPermission,
  });

  final String label;
  final MenuItem pageItem;
  final String pagePermission;

  final MenuItem? dashboardItem;
  final String? dashboardPermission;
}

class DrawerMenu extends StatefulWidget {
  final void Function(MenuItem) onTap;

  const DrawerMenu({super.key, required this.onTap});

  @override
  State<DrawerMenu> createState() => _DrawerMenuState();
}

class _DrawerMenuState extends State<DrawerMenu> {
  final User? _firebaseUser = FirebaseAuth.instance.currentUser;
  bool _didInit = false;

  @override
  void initState() {
    super.initState();
    // Garante que o BLoC inicialize a lista, ligue realtime e faça bind do usuário atual
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
            return const Center(child: Text('Não autenticado', style: TextStyle(color: Colors.white70)));
          }

          if (userData == null || state.isLoadingUsers) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: sigedLogo(fontSize: 40, heightLogo: 30, widthLogo: 30),
              ),
              const SizedBox(height: 20),

              DividerText(
                title: 'DOCUMENTOS',
                subtitle: 'do órgão',
                colorTitle: Colors.white38,
                subTitle: Colors.white24,
              ),
              ...PagesData.drawerDocuments
                  .map((item) => _maybeBuildExpandableItem(
                item.icon,
                item.label,
                item.subItems,
                userData,
              ))
                  .whereType<Widget>(),

              const SizedBox(height: 20),
              DividerText(
                title: 'SETORES',
                subtitle: 'do órgão',
                colorTitle: Colors.white38,
                subTitle: Colors.white24,
              ),
              const SizedBox(height: 20),
              ...PagesData.drawerDepartments
                  .map((item) => _maybeBuildExpandableItem(
                item.icon,
                item.label,
                item.subItems,
                userData,
              ))
                  .whereType<Widget>(),

              const SizedBox(height: 20),
              DividerText(
                title: 'ATIVOS',
                subtitle: 'do órgão',
                colorTitle: Colors.white38,
                subTitle: Colors.white24,
              ),
              const SizedBox(height: 20),
              ...PagesData.drawerActives
                  .map((item) => _maybeBuildExpandableItem(
                item.icon,
                item.label,
                item.subItems,
                userData,
              ))
                  .whereType<Widget>(),

              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  UserData? _resolveCurrentUserData(UserState state) {
    // Preferir o que o BLoC já “binda”
    if (state.current != null) return state.current;

    // Fallback: procurar pelo uid autenticado no mapa byId
    final uid = _firebaseUser?.uid;
    if (uid != null && uid.isNotEmpty) {
      return state.byId[uid];
    }
    return null;
  }

  Widget? _maybeBuildExpandableItem(
      IconData icon,
      String label,
      List<MenuDrawerSubItem> children,
      UserData user,
      ) {
    final merged = _mergeDashboardRows(children);

    // Só exibe se usuário tiver permissão na PÁGINA (não no painel).
    final visible = merged
        .where((m) => _hasReadPermissionByModule(user, m.pagePermission))
        .toList();
    if (visible.isEmpty) return null;

    return _buildExpandableMerged(icon, label, visible, user);
  }

  bool _hasReadPermissionByModule(UserData user, String moduleKey) {
    final perms = user.modulePermissions[moduleKey] ?? {};
    return perms['read'] == true;
    // Caso precise aplicar permissões herdadas + baseProfile, adapte aqui.
  }

  List<MergedSubItem> _mergeDashboardRows(List<MenuDrawerSubItem> items) {
    final out = <MergedSubItem>[];
    int i = 0;

    bool _isPainel(MenuDrawerSubItem s) =>
        s.label.trim().toUpperCase() == 'PAINEL';

    while (i < items.length) {
      final current = items[i];

      if (_isPainel(current)) {
        if (i + 1 < items.length && !_isPainel(items[i + 1])) {
          final page = items[i + 1];
          out.add(MergedSubItem(
            label: page.label,
            pageItem: page.menuItem,
            pagePermission: page.permissionModule,
            dashboardItem: current.menuItem,
            dashboardPermission: current.permissionModule,
          ));
          i += 2;
        } else {
          i += 1; // painel solto — ignora
        }
      } else {
        out.add(MergedSubItem(
          label: current.label,
          pageItem: current.menuItem,
          pagePermission: current.permissionModule,
        ));
        i += 1;
      }
    }

    return out;
  }

  Widget _buildExpandableMerged(
      IconData icon,
      String label,
      List<MergedSubItem> children,
      UserData user,
      ) {
    return Theme(
      data: ThemeData.dark().copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(label, style: const TextStyle(color: Colors.white)),
        iconColor: Colors.white,
        collapsedIconColor: Colors.white,
        children: children.map((m) => _buildMergedRow(m, user)).toList(),
      ),
    );
  }

  Widget _buildMergedRow(MergedSubItem m, UserData user) {
    final hasDashboard = m.dashboardItem != null &&
        m.dashboardPermission != null &&
        _hasReadPermissionByModule(user, m.dashboardPermission!);

    return _SubMenuRow(
      label: m.label,
      hasDashboard: hasDashboard,
      onTapPage: () => widget.onTap(m.pageItem),
      onTapDashboard: hasDashboard ? () => widget.onTap(m.dashboardItem!) : null,
    );
  }
}

/// Linha customizada SEM seta inicial, com hover independente para linha e para ícone.
class _SubMenuRow extends StatefulWidget {
  const _SubMenuRow({
    required this.label,
    required this.onTapPage,
    required this.hasDashboard,
    this.onTapDashboard,
  });

  final String label;
  final VoidCallback onTapPage;
  final bool hasDashboard;
  final VoidCallback? onTapDashboard;

  @override
  State<_SubMenuRow> createState() => _SubMenuRowState();
}

class _SubMenuRowState extends State<_SubMenuRow> {
  bool _hoverRow = false;
  bool _hoverIcon = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hoverRow = true),
      onExit: (_) => setState(() => _hoverRow = false),
      child: Container(
        color: _hoverRow ? Colors.white10 : Colors.transparent,
        padding: const EdgeInsets.only(left: 48, right: 8),
        height: 44,
        child: Row(
          children: [
            // Texto clicável (página)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onTapPage,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      color: _hoverRow ? Colors.white : Colors.white70,
                      fontSize: 14,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ),

            // Ícone do dashboard (hover independente)
            if (widget.hasDashboard)
              MouseRegion(
                onEnter: (_) => setState(() => _hoverIcon = true),
                onExit: (_) => setState(() => _hoverIcon = false),
                child: Tooltip(
                  message: 'Abrir Dashboard de ${widget.label}',
                  waitDuration: const Duration(milliseconds: 300),
                  child: IconButton(
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    iconSize: 20,
                    splashRadius: 18,
                    onPressed: widget.onTapDashboard,
                    icon: Icon(
                      Icons.dashboard_customize_rounded,
                      color: _hoverIcon ? Colors.white : Colors.white70,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
