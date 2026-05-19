// lib/admPanel/system/users/manager_users.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/system/login/login_cubit.dart';
import 'package:sipged/_blocs/system/module/module_catalog.dart';
import 'package:sipged/_blocs/system/notification/local/notification_local_cubit.dart';
import 'package:sipged/_blocs/system/permission/permission_data.dart' as perm;
import 'package:sipged/_blocs/system/permission/permission_repository.dart';
import 'package:sipged/_blocs/system/tenant/tenant_cubit.dart';
import 'package:sipged/_blocs/system/tenant/tenant_data.dart';
import 'package:sipged/_blocs/system/tenant/tenant_state.dart';
import 'package:sipged/_blocs/system/user/user_cubit.dart';
import 'package:sipged/_blocs/system/user/user_data.dart';
import 'package:sipged/_blocs/system/user/user_repository.dart';
import 'package:sipged/_blocs/system/user/user_state.dart';

import 'package:sipged/_widgets/buttons/circle_button_change.dart';
import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots.dart';
import 'package:sipged/_widgets/menu/upBar/up_bar.dart';

import 'package:sipged/screens/common/login/sign_up/widgets/manager_users_error_panel.dart';
import 'package:sipged/admPanel/system/users/permission_user_card.dart';
import 'package:sipged/screens/common/login/sign_up/sign_up.dart';

class ManagerUsers extends StatefulWidget {
  const ManagerUsers({super.key});

  @override
  State<ManagerUsers> createState() => _ManagerUsersState();
}

class _ManagerUsersState extends State<ManagerUsers> {
  final PermissionRepository _permissionRepo = PermissionRepository();

  bool _didInit = false;
  bool _openingCreateUser = false;
  bool _loadingPermissions = false;

  String? _permissionsLoadError;

  final Map<String, perm.UserPermissionData> _permissionsByUid =
  <String, perm.UserPermissionData>{};

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _didInit) return;

      _didInit = true;

      await _reloadAll();
    });
  }

  Future<void> _reloadUsers() async {
    if (!mounted) return;

    await context.read<UserCubit>().ensureLoaded(
      listenRealtime: true,
    );

    if (!mounted) return;

    final users = context.read<UserCubit>().state.all;

    await _reloadPermissionsForUsers(users);
  }


  Future<void> _reloadAll() async {
    if (!mounted) return;

    final userCubit = context.read<UserCubit>();
    final tenantCubit = context.read<TenantCubit>();

    await Future.wait([
      userCubit.ensureLoaded(
        listenRealtime: true,
      ),
      tenantCubit.ensureAvailableTenantsLoaded(),
    ]);

    if (!mounted) return;

    await _reloadPermissionsForUsers(userCubit.state.all);
  }

  Future<void> _reloadPermissionsForUsers(List<UserData> users) async {
    if (!mounted) return;

    final uids = users
        .map((user) => (user.uid ?? '').trim())
        .where((uid) => uid.isNotEmpty)
        .toSet()
        .toList();

    if (uids.isEmpty) {
      setState(() {
        _permissionsByUid.clear();
        _permissionsLoadError = null;
        _loadingPermissions = false;
      });
      return;
    }

    setState(() {
      _loadingPermissions = true;
      _permissionsLoadError = null;
    });

    try {
      final entries = await Future.wait(
        uids.map(
              (uid) async {
            final data = await _permissionRepo.loadUserPermissions(uid);

            return MapEntry<String, perm.UserPermissionData>(
              uid,
              data ??
                  perm.UserPermissionData(
                    uid: uid,
                  ),
            );
          },
        ),
      );

      if (!mounted) return;

      setState(() {
        _permissionsByUid
          ..clear()
          ..addEntries(entries);

        _loadingPermissions = false;
        _permissionsLoadError = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingPermissions = false;
        _permissionsLoadError = e.toString();
      });
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  Future<void> _openCreateUserPage() async {
    if (!mounted || _openingCreateUser) return;

    setState(() {
      _openingCreateUser = true;
    });

    try {
      final loginCubit = context.read<LoginCubit>();
      final userCubit = context.read<UserCubit>();
      final userRepository = context.read<UserRepository>();
      final notificationLocalCubit = context.read<NotificationLocalCubit>();

      final created = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) {
            return MultiRepositoryProvider(
              providers: [
                RepositoryProvider<UserRepository>.value(
                  value: userRepository,
                ),
              ],
              child: MultiBlocProvider(
                providers: [
                  BlocProvider<LoginCubit>.value(
                    value: loginCubit,
                  ),
                  BlocProvider<UserCubit>.value(
                    value: userCubit,
                  ),
                  BlocProvider<NotificationLocalCubit>.value(
                    value: notificationLocalCubit,
                  ),
                ],
                child: SignUp(
                  userData: UserData(),
                  mode: SignUpMode.adminCreateUser,
                ),
              ),
            );
          },
        ),
      );

      if (!mounted) return;

      if (created == true) {
        await _reloadAll();
      }
    } finally {
      if (mounted) {
        setState(() {
          _openingCreateUser = false;
        });
      }
    }
  }

  Future<void> _openEditUserPage(UserData user) async {
    if (!mounted) return;

    final loginCubit = context.read<LoginCubit>();
    final userCubit = context.read<UserCubit>();
    final userRepository = context.read<UserRepository>();
    final notificationLocalCubit = context.read<NotificationLocalCubit>();

    final edited = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) {
          return MultiRepositoryProvider(
            providers: [
              RepositoryProvider<UserRepository>.value(
                value: userRepository,
              ),
            ],
            child: MultiBlocProvider(
              providers: [
                BlocProvider<LoginCubit>.value(
                  value: loginCubit,
                ),
                BlocProvider<UserCubit>.value(
                  value: userCubit,
                ),
                BlocProvider<NotificationLocalCubit>.value(
                  value: notificationLocalCubit,
                ),
              ],
              child: SignUp(
                userData: user,
                mode: SignUpMode.editUser,
              ),
            ),
          );
        },
      ),
    );

    if (!mounted) return;

    if (edited == true) {
      await _reloadAll();
    }
  }

  Widget _buildAddUserButton() {
    return FloatingActionButton.extended(
      heroTag: 'manager-users-add-user',
      backgroundColor: const Color(0xFF2563EB),
      foregroundColor: Colors.white,
      elevation: 4,
      icon: _openingCreateUser
          ? const SizedBox(
        width: 18,
        height: 18,
        child: LoadingTreeDots(
          size: 18,
          strokeWidth: 2,
          color: Colors.white,
          centered: false,
        ),
      )
          : const Icon(Icons.person_add_alt_1_rounded),
      label: Text(
        _openingCreateUser ? 'Abrindo...' : 'Novo usuário',
        style: const TextStyle(
          fontWeight: FontWeight.w800,
        ),
      ),
      onPressed: _openingCreateUser ? null : _openCreateUserPage,
    );
  }

  perm.UserPermissionData _permissionsOf(UserData user) {
    final uid = (user.uid ?? '').trim();

    if (uid.isEmpty) {
      return const perm.UserPermissionData.empty();
    }

    return _permissionsByUid[uid] ??
        perm.UserPermissionData(
          uid: uid,
        );
  }

  List<String> _tenantIdsOf(UserData user) {
    final permissions = _permissionsOf(user);

    return permissions.enabledTenantIds;
  }

  String _tenantLabel(TenantData tenant) {
    final companyName = (tenant.companyName ?? '').trim();

    if (companyName.isNotEmpty) {
      return companyName;
    }

    final fantasyName = (tenant.fantasyName ?? '').trim();

    if (fantasyName.isNotEmpty) {
      return fantasyName;
    }

    final label = tenant.label.trim();

    if (label.isNotEmpty) {
      return label;
    }

    return tenant.id;
  }

  String? _tenantLabelById(String tenantId) {
    final cleanTenantId = tenantId.trim();

    if (cleanTenantId.isEmpty) {
      return null;
    }

    final tenants = context.read<TenantCubit>().state.availableTenants;

    for (final tenant in tenants) {
      if (tenant.id.trim() == cleanTenantId) {
        return _tenantLabel(tenant);
      }
    }

    return null;
  }

  Future<void> _ensureUserTenantAccess({
    required UserData user,
    required String tenantId,
    perm.PermissionUser role = perm.PermissionUser.leitor,
  }) async {
    final uid = (user.uid ?? '').trim();
    final cleanTenantId = tenantId.trim();

    if (uid.isEmpty || cleanTenantId.isEmpty) {
      return;
    }

    final current = _permissionsOf(user);
    final existingTenant = current.tenantPermission(cleanTenantId);

    if (existingTenant?.enabled == true) {
      return;
    }

    await _permissionRepo.setTenantAccess(
      uid: uid,
      tenantId: cleanTenantId,
      enabled: true,
      role: existingTenant?.role ?? role,
      label: existingTenant?.label ?? _tenantLabelById(cleanTenantId),
    );
  }

  Future<void> _persistRole({
    required UserData user,
    required String tenantId,
    required perm.PermissionUser picked,
  }) async {
    final uid = (user.uid ?? '').trim();
    final cleanTenantId = tenantId.trim();

    if (uid.isEmpty || cleanTenantId.isEmpty) {
      _showMessage('Selecione uma empresa antes de alterar o tipo de usuário.');
      return;
    }

    try {
      await _permissionRepo.setTenantAccess(
        uid: uid,
        tenantId: cleanTenantId,
        enabled: true,
        role: picked,
        label: _tenantLabelById(cleanTenantId),
      );

      await _reloadUsers();
    } catch (e) {
      _showMessage('Erro ao alterar tipo de usuário: $e');
    }
  }

  perm.PermissionSet _copyPermissionByAction({
    required perm.PermissionSet current,
    required String action,
    required bool value,
  }) {
    final parsedAction = perm.PermissionActionCodec.tryParse(action);

    if (parsedAction == null) {
      return current;
    }

    switch (parsedAction) {
      case perm.PermissionType.read:
        return current.copyWith(read: value);

      case perm.PermissionType.create:
        return current.copyWith(create: value);

      case perm.PermissionType.edit:
        return current.copyWith(edit: value);

      case perm.PermissionType.delete:
        return current.copyWith(delete: value);

      case perm.PermissionType.approve:
        return current.copyWith(approve: value);
    }
  }

  Future<void> _persistModulePermission({
    required UserData user,
    required String tenantId,
    required String module,
    required String action,
    required bool allow,
  }) async {
    final uid = (user.uid ?? '').trim();
    final cleanTenantId = tenantId.trim();
    final cleanModule = module.trim();

    if (uid.isEmpty || cleanTenantId.isEmpty || cleanModule.isEmpty) {
      _showMessage('Selecione uma empresa antes de alterar permissões.');
      return;
    }

    final parsedAction = perm.PermissionActionCodec.tryParse(action);

    if (parsedAction == null) {
      _showMessage('Ação de permissão inválida.');
      return;
    }

    try {
      await _ensureUserTenantAccess(
        user: user,
        tenantId: cleanTenantId,
      );

      final permissions = _permissionsOf(user);

      final currentPermission = permissions
          .tenantPermission(cleanTenantId)
          ?.permissionForModule(cleanModule) ??
          perm.PermissionSet.none;

      final updated = _copyPermissionByAction(
        current: currentPermission,
        action: perm.PermissionActionCodec.serialize(parsedAction),
        value: allow,
      );

      await _permissionRepo.setTenantModuleOverride(
        uid: uid,
        tenantId: cleanTenantId,
        module: cleanModule,
        permissions: updated,
      );

      await _reloadUsers();
    } catch (e) {
      _showMessage('Erro ao alterar permissão do módulo: $e');
    }
  }

  Future<void> _persistGroupRead({
    required UserData user,
    required String tenantId,
    required List<String> modules,
    required bool allow,
  }) async {
    final uid = (user.uid ?? '').trim();
    final cleanTenantId = tenantId.trim();

    if (uid.isEmpty || cleanTenantId.isEmpty || modules.isEmpty) {
      _showMessage('Selecione uma empresa antes de alterar permissões.');
      return;
    }

    try {
      await _ensureUserTenantAccess(
        user: user,
        tenantId: cleanTenantId,
      );

      final permissions = _permissionsOf(user);
      final futures = <Future<void>>[];

      for (final rawModule in modules) {
        final module = rawModule.trim();

        if (module.isEmpty) {
          continue;
        }

        final currentPermission = permissions
            .tenantPermission(cleanTenantId)
            ?.permissionForModule(module) ??
            perm.PermissionSet.none;

        final updated = currentPermission.copyWith(
          read: allow,
        );

        futures.add(
          _permissionRepo.setTenantModuleOverride(
            uid: uid,
            tenantId: cleanTenantId,
            module: module,
            permissions: updated,
          ),
        );
      }

      await Future.wait(futures);
      await _reloadUsers();
    } catch (e) {
      _showMessage('Erro ao alterar permissões do grupo: $e');
    }
  }

  Future<void> _persistTenantAccess({
    required UserData user,
    required String tenantId,
    required bool allow,
  }) async {
    final uid = (user.uid ?? '').trim();
    final cleanTenantId = tenantId.trim();

    if (uid.isEmpty || cleanTenantId.isEmpty) {
      return;
    }

    try {
      if (allow) {
        final current = _permissionsOf(user);
        final existingTenant = current.tenantPermission(cleanTenantId);

        await _permissionRepo.setTenantAccess(
          uid: uid,
          tenantId: cleanTenantId,
          enabled: true,
          role: existingTenant?.role ?? perm.PermissionUser.leitor,
          label: existingTenant?.label ?? _tenantLabelById(cleanTenantId),
        );
      } else {
        await _permissionRepo.removeTenantAccess(
          uid: uid,
          tenantId: cleanTenantId,
        );
      }

      await _reloadUsers();
    } catch (e) {
      _showMessage('Erro ao alterar acesso à empresa: $e');
    }
  }

  Widget _buildLoadingPage() {
    return const Scaffold(
      body: Stack(
        children: [
          BackgroundChange(),
          Center(
            child: LoadingTreeDots(size: 110),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorPage(String message) {
    return Scaffold(
      appBar: const UpBar(
        leading: CircleButtonChange(),
      ),
      floatingActionButton: _buildAddUserButton(),
      body: Stack(
        children: [
          const BackgroundChange(),
          Center(
            child: ManagerUsersErrorPanel(
              message: message,
              onRetry: _reloadAll,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPage() {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: const UpBar(
        leading: CircleButtonChange(),
      ),
      floatingActionButton: _buildAddUserButton(),
      body: const Stack(
        children: [
          BackgroundChange(),
          Center(
            child: Text('Nenhum usuário encontrado.'),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsLoadingOverlay() {
    if (!_loadingPermissions) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          color: Colors.white.withValues(alpha: 0.20),
          child: const Center(
            child: LoadingTreeDots(size: 90),
          ),
        ),
      ),
    );
  }

  Widget _buildContent({
    required UserState userState,
    required TenantState tenantState,
  }) {
    final users = userState.all;
    final tenants = tenantState.availableTenants;

    if (users.isEmpty) {
      return _buildEmptyPage();
    }

    final groups = ModuleCatalog.permissionModulesByDrawerGroup();

    return Scaffold(
      floatingActionButton: _buildAddUserButton(),
      appBar: const UpBar(
        leading: Padding(
          padding: EdgeInsets.only(left: 12),
          child: CircleButtonChange(),
        ),
        titleWidgets: [
          Text(
            'Usuários, empresas e permissões por módulo',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          const BackgroundChange(),
          CustomScrollView(
            slivers: [
              if (_permissionsLoadError != null &&
                  _permissionsLoadError!.trim().isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  sliver: SliverToBoxAdapter(
                    child: ManagerUsersErrorPanel(
                      message:
                      'Erro ao carregar permissões:\n$_permissionsLoadError',
                      onRetry: _reloadAll,
                    ),
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
                sliver: SliverList.separated(
                  itemCount: users.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final userPermissions = _permissionsOf(user);

                    final nameText = '${user.name ?? '-'} ${user.surname ?? ''}'
                        .trim()
                        .replaceAll(RegExp(r'\s+'), ' ');

                    final userTenantIds = _tenantIdsOf(user);

                    return PermissionUserCard(
                      user: user,
                      nameText: nameText,
                      userPermissions: userPermissions,
                      groups: groups,
                      availableTenants: tenants,
                      userTenantIds: userTenantIds,
                      tenantLabelBuilder: _tenantLabel,
                      onEditUser: () {
                        return _openEditUserPage(user);
                      },
                      onPickRole: ({
                        required String tenantId,
                        required perm.PermissionUser picked,
                      }) {
                        return _persistRole(
                          user: user,
                          tenantId: tenantId,
                          picked: picked,
                        );
                      },
                      onPersistGroupRead: ({
                        required String tenantId,
                        required List<String> modules,
                        required bool allow,
                      }) {
                        return _persistGroupRead(
                          user: user,
                          tenantId: tenantId,
                          modules: modules,
                          allow: allow,
                        );
                      },
                      onPersistModulePermission: ({
                        required String tenantId,
                        required String module,
                        required String action,
                        required bool allow,
                      }) {
                        return _persistModulePermission(
                          user: user,
                          tenantId: tenantId,
                          module: module,
                          action: action,
                          allow: allow,
                        );
                      },
                      onPersistTenantAccess: ({
                        required String tenantId,
                        required bool allow,
                      }) {
                        return _persistTenantAccess(
                          user: user,
                          tenantId: tenantId,
                          allow: allow,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          _buildPermissionsLoadingOverlay(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserCubit, UserState>(
      builder: (context, userState) {
        return BlocBuilder<TenantCubit, TenantState>(
          builder: (context, tenantState) {
            final loadingUsers =
                userState.isLoadingUsers && userState.all.isEmpty;

            final loadingTenants =
                tenantState.isLoading && !tenantState.hasLoadedAvailableTenants;

            final loadingInitialPermissions =
                _loadingPermissions && _permissionsByUid.isEmpty;

            if (loadingUsers || loadingTenants || loadingInitialPermissions) {
              return _buildLoadingPage();
            }

            final loadUsersError = userState.loadUsersError?.trim();

            if (loadUsersError != null && loadUsersError.isNotEmpty) {
              return _buildErrorPage(
                'Erro ao carregar usuários:\n$loadUsersError',
              );
            }

            final tenantError = tenantState.error?.trim();

            if (tenantError != null && tenantError.isNotEmpty) {
              return _buildErrorPage(
                'Erro ao carregar empresas:\n$tenantError',
              );
            }

            return _buildContent(
              userState: userState,
              tenantState: tenantState,
            );
          },
        );
      },
    );
  }
}