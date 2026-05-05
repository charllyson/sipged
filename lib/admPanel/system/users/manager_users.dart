import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/system/login/login_cubit.dart';
import 'package:sipged/_blocs/system/module/module_data.dart';
import 'package:sipged/_blocs/system/notification/local/notification_local_cubit.dart';
import 'package:sipged/_blocs/system/permission/permission_cubit.dart';
import 'package:sipged/_blocs/system/permission/permission_data.dart' as perm;
import 'package:sipged/_blocs/system/permission/permission_repository.dart';
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

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _didInit) return;

      _didInit = true;

      context.read<UserCubit>().ensureLoaded(
        listenRealtime: true,
      );
    });
  }

  Future<void> _reloadUsers() async {
    if (!mounted) return;

    await context.read<UserCubit>().ensureLoaded(
      listenRealtime: true,
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
        await _reloadUsers();
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
      await _reloadUsers();
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

  String? _activeTenantId() {
    final id = context.read<PermissionCubit>().state.activeTenantId?.trim();

    if (id == null || id.isEmpty) return null;

    return id;
  }

  perm.UserPermissionData _permissionsOf(UserData user) {
    final uid = (user.uid ?? '').trim();
    final raw = user.userSnap?.data();

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

  Future<void> _persistRole(
      UserData user,
      perm.SystemUserRole newRole,
      ) async {
    final uid = (user.uid ?? '').trim();

    if (uid.isEmpty) return;

    final tenantId = _activeTenantId();

    if (tenantId == null) {
      await _permissionRepo.setGlobalRole(
        uid: uid,
        role: newRole,
      );
    } else {
      await _permissionRepo.setTenantRole(
        uid: uid,
        tenantId: tenantId,
        role: newRole,
      );
    }

    await _reloadUsers();
  }

  perm.PermissionSet _copyPermissionByAction({
    required perm.PermissionSet current,
    required String action,
    required bool value,
  }) {
    switch (action.trim().toLowerCase()) {
      case 'read':
        return current.copyWith(read: value);

      case 'create':
        return current.copyWith(create: value);

      case 'edit':
        return current.copyWith(edit: value);

      case 'delete':
        return current.copyWith(delete: value);

      case 'approve':
        return current.copyWith(approve: value);

      default:
        return current;
    }
  }

  Future<void> _persistModulePermission({
    required UserData user,
    required String module,
    required String action,
    required bool allow,
  }) async {
    final uid = (user.uid ?? '').trim();
    final cleanModule = module.trim();

    if (uid.isEmpty || cleanModule.isEmpty) return;

    final tenantId = _activeTenantId();
    final permissions = _permissionsOf(user);

    final currentOverride = permissions.moduleOverride(
      module: cleanModule,
      tenantId: tenantId,
    );

    final updated = _copyPermissionByAction(
      current: currentOverride,
      action: action,
      value: allow,
    );

    if (tenantId == null) {
      await _permissionRepo.setGlobalModuleOverride(
        uid: uid,
        module: cleanModule,
        permissions: updated,
      );
    } else {
      await _permissionRepo.setTenantModuleOverride(
        uid: uid,
        tenantId: tenantId,
        module: cleanModule,
        permissions: updated,
      );
    }

    await _reloadUsers();
  }

  Future<void> _persistGroupRead({
    required UserData user,
    required List<String> modules,
    required bool allow,
  }) async {
    final uid = (user.uid ?? '').trim();

    if (uid.isEmpty || modules.isEmpty) return;

    final tenantId = _activeTenantId();
    final permissions = _permissionsOf(user);

    final futures = <Future<void>>[];

    for (final rawModule in modules) {
      final module = rawModule.trim();

      if (module.isEmpty) continue;

      final currentOverride = permissions.moduleOverride(
        module: module,
        tenantId: tenantId,
      );

      final updated = currentOverride.copyWith(
        read: allow,
      );

      if (tenantId == null) {
        futures.add(
          _permissionRepo.setGlobalModuleOverride(
            uid: uid,
            module: module,
            permissions: updated,
          ),
        );
      } else {
        futures.add(
          _permissionRepo.setTenantModuleOverride(
            uid: uid,
            tenantId: tenantId,
            module: module,
            permissions: updated,
          ),
        );
      }
    }

    await Future.wait(futures);
    await _reloadUsers();
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
              onRetry: _reloadUsers,
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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserCubit, UserState>(
      builder: (context, state) {
        if (state.isLoadingUsers && state.all.isEmpty) {
          return _buildLoadingPage();
        }

        final loadError = state.loadUsersError?.trim();

        if (loadError != null && loadError.isNotEmpty) {
          return _buildErrorPage(
            'Erro ao carregar usuários:\n$loadError',
          );
        }

        final users = state.all;

        if (users.isEmpty) {
          return _buildEmptyPage();
        }

        final tenantId = _activeTenantId();
        final groups = ModuleData.permissionModulesByDrawerGroup();

        return Scaffold(
          floatingActionButton: _buildAddUserButton(),
          appBar: UpBar(
            leading: const Padding(
              padding: EdgeInsets.only(left: 12),
              child: CircleButtonChange(),
            ),
            titleWidgets: [
              Text(
                tenantId == null
                    ? 'Permissões globais do sistema'
                    : 'Permissões da empresa',
                style: const TextStyle(
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
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 90),
                    sliver: SliverList.separated(
                      itemCount: users.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 18),
                      itemBuilder: (context, index) {
                        final user = users[index];
                        final userPermissions = _permissionsOf(user);

                        final baseRole = userPermissions.roleForTenant(
                          tenantId,
                        );

                        final isSuper = userPermissions.isSuperUserForTenant(
                          tenantId,
                        );

                        final nameText =
                        '${user.name ?? '-'} ${user.surname ?? ''}'
                            .trim()
                            .replaceAll(RegExp(r'\s+'), ' ');

                        return PermissionUserCard(
                          user: user,
                          nameText: nameText,
                          baseRole: baseRole,
                          isSuper: isSuper,
                          userPermissions: userPermissions,
                          tenantId: tenantId,
                          groups: groups,

                          // ESSA LINHA FAZ O BOTÃO DE EDITAR APARECER.
                          onEditUser: () {
                            return _openEditUserPage(user);
                          },

                          onPickRole: (picked) {
                            return _persistRole(
                              user,
                              picked,
                            );
                          },
                          onPersistGroupRead: ({
                            required List<String> modules,
                            required bool allow,
                          }) {
                            return _persistGroupRead(
                              user: user,
                              modules: modules,
                              allow: allow,
                            );
                          },
                          onPersistModulePermission: ({
                            required String module,
                            required String action,
                            required bool allow,
                          }) {
                            return _persistModulePermission(
                              user: user,
                              module: module,
                              action: action,
                              allow: allow,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}