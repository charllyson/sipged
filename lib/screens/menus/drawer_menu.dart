import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/system/module/module_data.dart';
import 'package:sipged/_blocs/system/permission/permission_cubit.dart';
import 'package:sipged/_blocs/system/permission/permission_data.dart' as perm;
import 'package:sipged/_blocs/system/permission/permission_state.dart';
import 'package:sipged/_blocs/system/user/user_cubit.dart';
import 'package:sipged/_blocs/system/user/user_data.dart';
import 'package:sipged/_blocs/system/user/user_state.dart';

import 'package:sipged/_widgets/images/logos/sipged_logo.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots.dart';
import 'package:sipged/_widgets/menu/drawer/menu_drawer_item.dart';
import 'package:sipged/_widgets/menu/drawer/menu_drawer_sub_item.dart';
import 'package:sipged/_widgets/texts/divider_text.dart';

import 'package:sipged/screens/menus/drawer_palette.dart';
import 'package:sipged/screens/menus/menu_sub_item.dart';

class DrawerMenu extends StatefulWidget {
  const DrawerMenu({
    super.key,
    required this.onTap,
    this.onTapHome,
  });

  final void Function(ModuleItem) onTap;
  final VoidCallback? onTapHome;

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

      final uid = _firebaseUser?.uid.trim();

      if (uid != null && uid.isNotEmpty) {
        context.read<PermissionCubit>().watchByUid(uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserCubit, UserState>(
      builder: (context, userState) {
        return BlocBuilder<PermissionCubit, PermissionState>(
          builder: (context, permissionState) {
            final userData = _resolveCurrentUserData(userState);
            final bgPalette = UserData.drawerPaletteForUser(userData);

            return Drawer(
              width: 250,
              backgroundColor: bgPalette.background,
              child: _buildContent(
                context: context,
                userData: userData,
                userState: userState,
                permissionState: permissionState,
                palette: bgPalette,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildContent({
    required BuildContext context,
    required UserData? userData,
    required UserState userState,
    required PermissionState permissionState,
    required DrawerPalette palette,
  }) {
    if (_firebaseUser == null) {
      return const Center(
        child: Text(
          'Não autenticado',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    if (userData == null || userState.isLoadingUsers) {
      return const LoadingTreeDots(
        message: Text(
          'Carregando módulos',
          style: TextStyle(color: Colors.white),
        ),
        variant: LoadingTreeDotsVariant.white,
      );
    }

    final permissions = _permissionDataOf(
      userData: userData,
      permissionState: permissionState,
    );

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
          permissions: permissions,
          activeTenantId: permissionState.activeTenantId,
          colorTitle: palette.sectionTitle,
          colorSubTitle: palette.sectionSubtitle,
          items: [
            ...ModuleData.drawerDocuments,
            ...ModuleData.drawerDepartments,
          ],
        ),
        ..._buildSection(
          title: 'ATIVOS',
          permissions: permissions,
          activeTenantId: permissionState.activeTenantId,
          colorTitle: palette.sectionTitle,
          colorSubTitle: palette.sectionSubtitle,
          items: ModuleData.drawerActives,
        ),
      ],
    );
  }

  List<Widget> _buildSection({
    required String title,
    required perm.UserPermissionData permissions,
    required String? activeTenantId,
    required Color colorTitle,
    required Color colorSubTitle,
    required List<MenuDrawerItemModule> items,
  }) {
    final visibleGroups = items
        .map(
          (item) => _buildExpandableGroup(
        icon: item.icon,
        label: item.label,
        children: item.subItems,
        permissions: permissions,
        activeTenantId: activeTenantId,
      ),
    )
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
    required perm.UserPermissionData permissions,
    required String? activeTenantId,
  }) {
    final visible = children.where((sub) {
      return permissions.canModuleString(
        module: sub.permissionModule,
        action: 'read',
        tenantId: _cleanTenantId(activeTenantId),
      );
    }).toList();

    if (visible.isEmpty) return null;

    return Theme(
      data: ThemeData.dark().copyWith(
        dividerColor: Colors.transparent,
      ),
      child: ExpansionTile(
        leading: Icon(
          icon,
          color: Colors.white,
        ),
        title: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
        iconColor: Colors.white,
        collapsedIconColor: Colors.white,
        children: visible
            .map(
              (sub) => MenuSubItem(
            label: sub.label,
            onTap: () => widget.onTap(sub.menuItem),
          ),
        )
            .toList(),
      ),
    );
  }

  perm.UserPermissionData _permissionDataOf({
    required UserData userData,
    required PermissionState permissionState,
  }) {
    final uid = (userData.uid ?? '').trim();
    final current = permissionState.current;

    if (current != null && current.uid.trim() == uid) {
      return current;
    }

    final raw = userData.userSnap?.data();

    if (raw is Map<String, dynamic>) {
      return perm.UserPermissionData.fromMap(
        uid: uid,
        map: raw,
      );
    }

    return perm.UserPermissionData(
      uid: uid,
    );
  }

  String? _cleanTenantId(String? tenantId) {
    final id = tenantId?.trim();

    if (id == null || id.isEmpty) return null;

    return id;
  }

  UserData? _resolveCurrentUserData(UserState state) {
    if (state.current != null) return state.current;

    final uid = _firebaseUser?.uid;

    if (uid != null && uid.isNotEmpty) {
      return state.byId[uid];
    }

    return null;
  }
}