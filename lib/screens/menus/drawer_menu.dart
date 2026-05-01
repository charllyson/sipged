import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sipged/_widgets/menu/drawer/menu_drawer_item.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots.dart';

import 'package:sipged/_widgets/texts/divider_text.dart';
import 'package:sipged/_widgets/menu/drawer/menu_drawer_sub_item.dart';
import 'package:sipged/_blocs/system/module/module_data.dart';
import 'package:sipged/_blocs/system/user/user_data.dart';
import 'package:sipged/_widgets/images/logos/sipged_logo.dart';

// Cubit
import 'package:sipged/_blocs/system/user/user_cubit.dart';
import 'package:sipged/_blocs/system/user/user_state.dart';

// Permissões centralizadas
import 'package:sipged/_blocs/system/module/module_permission.dart'
as perms;
import 'package:sipged/screens/menus/drawer_palette.dart';
import 'package:sipged/screens/menus/menu_sub_item.dart';

class DrawerMenu extends StatefulWidget {
  final void Function(ModuleItem) onTap;
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
      context.read<UserCubit>().warmup(
        listenRealtime: true,
        bindCurrentUser: true,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserCubit, UserState>(
      builder: (context, state) {
        final userData = _resolveCurrentUserData(state);
        final bgPalette = UserData.drawerPaletteForUser(userData);

        return Drawer(
          width: 250,
          backgroundColor: bgPalette.background,
          child: _buildContent(context, userData, state, bgPalette),
        );
      },
    );
  }

  Widget _buildContent(
      BuildContext context,
      UserData? userData,
      UserState state,
      DrawerPalette palette,
      ) {
    if (_firebaseUser == null) {
      return const Center(
        child: Text(
          'Não autenticado',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    if (userData == null || state.isLoadingUsers) {
      return const LoadingTreeDots(
        message: Text('Carregando módulos', style: TextStyle(color: Colors.white)),
        variant: LoadingTreeDotsVariant.white,
      );
    }

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: SipgedLogo(
            fontSize: 40,
            heightLogo: 30,
            widthLogo: 30,
            onTapHome: () {
              Navigator.of(context).maybePop();
              widget.onTapHome?.call();
            },
          ),
        ),
        const SizedBox(height: 12),
        ..._buildSection(
          title: 'MÓDULOS',
          user: userData,
          colorTitle: palette.sectionTitle,
          colorSubTitle: palette.sectionSubtitle,
          items: [
            ...ModuleData.drawerDocuments,
            ...ModuleData.drawerDepartments,
          ],
        ),
        ..._buildSection(
          title: 'ATIVOS',
          user: userData,
          colorTitle: palette.sectionTitle,
          colorSubTitle: palette.sectionSubtitle,
          items: ModuleData.drawerActives,
        ),
      ],
    );
  }

  List<Widget> _buildSection({
    required String title,
    required UserData user,
    required Color colorTitle,
    required Color colorSubTitle,
    required List<MenuDrawerItemModule> items,
  }) {
    final visibleGroups = items
        .map((item) => _buildExpandableGroup(
      icon: item.icon,
      label: item.label,
      children: item.subItems,
      user: user,
    ))
        .whereType<Widget>()
        .toList();

    if (visibleGroups.isEmpty) return const <Widget>[];

    return [
      DividerText(
        text: title,
        colorTitle: colorTitle,
        subTitle: colorSubTitle,
      ),
      const SizedBox(height: 8),
      ...visibleGroups,
      const SizedBox(height: 12),
    ];
  }

  Widget? _buildExpandableGroup({
    required IconData icon,
    required String label,
    required List<MenuDrawerSubItem> children,
    required UserData user,
  }) {
    final visible = children
        .where(
          (s) => perms.userCanModule(
        user: user,
        module: s.permissionModule,
        action: 'read',
      ),
    )
        .toList();

    if (visible.isEmpty) return null;

    return Theme(
      data: ThemeData.dark().copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        iconColor: Colors.white,
        collapsedIconColor: Colors.white,
        children: visible
            .map(
              (s) => MenuSubItem(
            label: s.label,
            onTap: () => widget.onTap(s.menuItem),
          ),
        )
            .toList(),
      ),
    );
  }

  UserData? _resolveCurrentUserData(UserState state) {
    if (state.current != null) return state.current;
    final uid = _firebaseUser?.uid;
    if (uid != null && uid.isNotEmpty) return state.byId[uid];
    return null;
  }
}

