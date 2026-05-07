// lib/screens/menus/drawer_menu.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/system/module/module_data.dart';
import 'package:sipged/_blocs/system/module/module_catalog.dart';

import 'package:sipged/_blocs/system/permission/permission_cubit.dart';
import 'package:sipged/_blocs/system/permission/permission_data.dart' as perm;
import 'package:sipged/_blocs/system/permission/permission_resolver.dart';
import 'package:sipged/_blocs/system/permission/permission_state.dart';

import 'package:sipged/_blocs/system/user/user_cubit.dart';
import 'package:sipged/_blocs/system/user/user_data.dart';
import 'package:sipged/_blocs/system/user/user_state.dart';

import 'package:sipged/_widgets/images/logos/sipged_logo.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots.dart';
import 'package:sipged/_widgets/texts/divider_text.dart';

import 'package:sipged/screens/menus/menu_sub_item.dart';

class DrawerMenu extends StatefulWidget {
  const DrawerMenu({
    super.key,
    required this.onTap,
    this.onTapHome,
  });

  final void Function(ModuleEnum) onTap;
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
    return BlocSelector<
        UserCubit,
        UserState,
        ({
        UserData? user,
        bool isLoading,
        })>(
      selector: (state) {
        return (
        user: _resolveCurrentUserDataFromState(state),
        isLoading: state.isLoadingUsers,
        );
      },
      builder: (context, userView) {
        return BlocSelector<
            PermissionCubit,
            PermissionState,
            ({
            perm.UserPermissionData? permissions,
            String? activeTenantId,
            })>(
          selector: (state) {
            return (
            permissions: PermissionResolver.resolveForUser(
              user: userView.user,
              permissionState: state,
            ),
            activeTenantId: PermissionResolver.cleanTenantId(
              state.activeTenantId,
            ),
            );
          },
          builder: (context, permissionView) {
            return Drawer(
              width: 250,
              backgroundColor: const Color(0xFF1B2033),
              child: _buildContent(
                context: context,
                userData: userView.user,
                isLoadingUser: userView.isLoading,
                permissions: permissionView.permissions,
                activeTenantId: permissionView.activeTenantId,
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
    required bool isLoadingUser,
    required perm.UserPermissionData? permissions,
    required String? activeTenantId,
  }) {
    if (_firebaseUser == null) {
      return const Center(
        child: Text(
          'Não autenticado',
          style: TextStyle(
            color: Colors.white70,
          ),
        ),
      );
    }

    if (userData == null || isLoadingUser) {
      return const LoadingTreeDots(
        message: Text(
          'Carregando módulos',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        variant: LoadingTreeDotsVariant.white,
      );
    }

    if (permissions == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(18),
          child: Text(
            'Permissões não encontradas.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    final drawerMainGroups = <ModuleGroupData>[
      ...ModuleCatalog.drawerDocuments,
      ...ModuleCatalog.drawerDepartments,
    ];

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 16),
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
          activeTenantId: activeTenantId,
          groups: drawerMainGroups,
        ),
        ..._buildSection(
          title: 'ATIVOS',
          permissions: permissions,
          activeTenantId: activeTenantId,
          groups: ModuleCatalog.drawerActives,
        ),
      ],
    );
  }

  List<Widget> _buildSection({
    required String title,
    required perm.UserPermissionData permissions,
    required String? activeTenantId,
    required List<ModuleGroupData> groups,
  }) {
    final visibleGroups = groups
        .map(
          (group) => _buildExpandableGroup(
        icon: group.iconSection,
        label: group.labelSection,
        sectionLabelColor: group.colorSectionLabel,
        children: group.moduleItems,
        permissions: permissions,
        activeTenantId: activeTenantId,
      ),
    )
        .whereType<Widget>()
        .toList(growable: false);

    if (visibleGroups.isEmpty) {
      return const <Widget>[];
    }

    return [
      DividerText(
        text: title,
        colorTitle: Colors.white70,
        subTitle: Colors.white38,
      ),
      const SizedBox(height: 8),
      ...visibleGroups,
      const SizedBox(height: 12),
    ];
  }

  Widget? _buildExpandableGroup({
    required IconData icon,
    required String label,
    required Color sectionLabelColor,
    required List<ModuleData> children,
    required perm.UserPermissionData permissions,
    required String? activeTenantId,
  }) {
    final visible = children.where((module) {
      return PermissionResolver.canReadModule(
        permissions: permissions,
        module: module.permissionModule,
        tenantId: activeTenantId,
      );
    }).toList(growable: false);

    if (visible.isEmpty) {
      return null;
    }

    return Theme(
      data: ThemeData.dark().copyWith(
        dividerColor: Colors.transparent,
      ),
      child: ExpansionTile(
        key: PageStorageKey<String>('drawer-group-${label.trim()}'),
        leading: Icon(
          icon,
          color: sectionLabelColor,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: sectionLabelColor,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconColor: sectionLabelColor,
        collapsedIconColor: sectionLabelColor,
        children: visible
            .map(
              (module) => MenuSubItem(
            label: module.labelModule,
            onTap: () {
              Navigator.of(context).maybePop();
              widget.onTap(module.menuModuleItem);
            },
          ),
        )
            .toList(growable: false),
      ),
    );
  }

  UserData? _resolveCurrentUserDataFromState(UserState state) {
    if (state.current != null) {
      return state.current;
    }

    final uid = _firebaseUser?.uid;

    if (uid != null && uid.isNotEmpty) {
      return state.byId[uid];
    }

    return null;
  }
}