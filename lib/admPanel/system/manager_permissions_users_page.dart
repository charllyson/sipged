import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_blocs/system/module/module_data.dart';
import 'package:siged/_blocs/system/user/user_data.dart';
import 'package:siged/_widgets/buttons/back_circle_button.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart';
import 'package:siged/_widgets/images/photo_circle/photo_circle.dart';
import 'package:siged/_widgets/menu/upBar/up_bar.dart';

// Bloc de usuário
import 'package:siged/_blocs/system/user/user_bloc.dart';
import 'package:siged/_blocs/system/user/user_event.dart';
import 'package:siged/_blocs/system/user/user_state.dart';

// ✅ helpers centralizados
import 'package:siged/_blocs/system/permitions/user_permission.dart' as roles;
import 'package:siged/_blocs/system/permitions/module_permission.dart' as pp;

class ManagerPermissionsUsersPage extends StatefulWidget {
  const ManagerPermissionsUsersPage({super.key});

  @override
  State<ManagerPermissionsUsersPage> createState() =>
      _ManagerPermissionsUsersPageState();
}

class _ManagerPermissionsUsersPageState
    extends State<ManagerPermissionsUsersPage> {
  bool _didInit = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _didInit) return;
      _didInit = true;
      context
          .read<UserBloc>()
          .add(const UsersEnsureLoadedRequested(listenRealtime: true));
    });
  }

  Future<void> _reloadUsers() async {
    if (!mounted) return;
    context
        .read<UserBloc>()
        .add(const UsersEnsureLoadedRequested(listenRealtime: true));
  }

  Future<void> _persistRole(UserData user, roles.UserProfile newRole) async {
    await roles.setUserRole(user, newRole);
    await _reloadUsers();
  }

  bool _isSuperUser(roles.UserProfile role) =>
      role == roles.UserProfile.ADMINISTRADOR ||
          role == roles.UserProfile.DESENVOLVEDOR;

  /// Liga/desliga SOMENTE o "read" do módulo (override). Outras flags são preservadas.
  Future<void> _persistModuleRead(
      UserData user,
      String module,
      bool allow,
      ) async {
    final current = pp.getOverrideForUserModule(user, module);
    final updated = current.copyWith(read: allow);
    await pp.setOverrideForUserModule(user, module, updated);
    await _reloadUsers();
  }

  /// Marca/Desmarca todos os módulos do grupo (apenas read)
  Future<void> _persistGroupRead(
      UserData user,
      List<String> modules,
      bool allow,
      ) async {
    if (modules.isEmpty) return;

    // otimiza: dispara todas as gravações em paralelo
    final futures = <Future<void>>[];
    for (final m in modules) {
      final current = pp.getOverrideForUserModule(user, m);
      final updated = current.copyWith(read: allow);
      futures.add(pp.setOverrideForUserModule(user, m, updated));
    }
    await Future.wait(futures);

    await _reloadUsers();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserBloc, UserState>(
      builder: (context, state) {
        if (state.isLoadingUsers && state.all.isEmpty) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state.loadUsersError != null &&
            (state.loadUsersError?.isNotEmpty ?? false)) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(72),
              child: Padding(
                padding: const EdgeInsets.only(left: 12.0),
                child: const UpBar(leading: BackCircleButton()),
              ),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 40),
                    const SizedBox(height: 12),
                    Text(
                      'Erro ao carregar usuários:\n${state.loadUsersError}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<UserBloc>().add(
                        const UsersEnsureLoadedRequested(
                            listenRealtime: true),
                      ),
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final users = state.all;
        if (users.isEmpty) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(72),
              child: Padding(
                padding: const EdgeInsets.only(left: 12.0),
                child: const UpBar(leading: BackCircleButton()),
              ),
            ),
            body: const Center(
                child: Text('Nenhum usuário encontrado.')),
          );
        }

        // ✅ fonte única: grupos e itens exatamente como no drawer/home
        final groups = ModuleData.permissionModulesByDrawerGroup();

        return Scaffold(
          appBar: const PreferredSize(
            preferredSize: Size.fromHeight(72),
            child: UpBar(
              leading: Padding(
                padding: EdgeInsets.only(left: 12.0),
                child: BackCircleButton(),
              ),
            ),
          ),
          backgroundColor: Colors.white,
          body: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];

              // ✅ papel base normalizado
              final baseRole = roles.roleForUser(user);
              final isSuper = _isSuperUser(baseRole);

              final nameText =
              '${user.name ?? '-'} ${user.surname ?? ''}'.trim();

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header do card de usuário
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final maxW = constraints.maxWidth;
                          final isWide = maxW >= 720;
                          final dropWidth = 300.0;

                          if (isWide) {
                            return Row(
                              children: [
                                PhotoCircle(userData: user),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        nameText,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      const SizedBox(height: 2),
                                      if (isSuper)
                                        const Text(
                                          'Acesso total (Administrador/Desenvolvedor)',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.black54,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                SizedBox(
                                  width: dropWidth,
                                  child: _RoleDropdown(
                                    baseRole: baseRole,
                                    onPick: (picked) =>
                                        _persistRole(user, picked),
                                  ),
                                ),
                              ],
                            );
                          }

                          // layout estreito
                          return Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              PhotoCircle(userData: user),
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: maxW - 80,
                                  minWidth: 100,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      nameText,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                      softWrap: true,
                                    ),
                                    if (isSuper)
                                      const Padding(
                                        padding: EdgeInsets.only(top: 2),
                                        child: Text(
                                          'Acesso total (Administrador/Desenvolvedor)',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.black54,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: maxW,
                                child: _RoleDropdown(
                                  baseRole: baseRole,
                                  onPick: (picked) =>
                                      _persistRole(user, picked),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                    Container(
                      height: 1,
                      color: Colors.grey,
                      width: double.infinity,
                    ),

                    // ===== Acesso aos MÓDULOS agrupados =====
                    Column(
                      children: groups.entries.map((entry) {
                        final groupLabel = entry.key; // já vem em upper do helper
                        final items = entry.value;

                        // módulos válidos e não vazios
                        final modules = items
                            .map((e) => e.module.trim())
                            .where((m) => m.isNotEmpty)
                            .toList(growable: false);

                        // estado do grupo (override.read)
                        int checkedCount = 0;
                        for (final m in modules) {
                          if (pp.getOverrideForUserModule(user, m).read) {
                            checkedCount++;
                          }
                        }

                        final all =
                            checkedCount == modules.length && modules.isNotEmpty;
                        final none = checkedCount == 0;
                        final triValue = all ? true : (none ? false : null);

                        return Theme(
                          data: Theme.of(context)
                              .copyWith(dividerColor: Colors.grey),
                          child: ExpansionTile(
                            collapsedBackgroundColor: Colors.white,
                            backgroundColor: Colors.grey.shade100,
                            title: Row(
                              children: [
                                Checkbox(
                                  tristate: true,
                                  value: isSuper ? true : triValue,
                                  onChanged: isSuper
                                      ? null
                                      : (v) async {
                                    final target = (v ?? false);
                                    await _persistGroupRead(
                                        user, modules, target);
                                  },
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    groupLabel,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: .5,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            children: [
                              ...items.map((it) {
                                final moduleId = it.module.trim();
                                if (moduleId.isEmpty) {
                                  return const SizedBox.shrink();
                                }

                                final ov =
                                pp.getOverrideForUserModule(user, moduleId);
                                final checked = isSuper ? true : ov.read;

                                return CheckboxListTile(
                                  dense: true,
                                  contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                                  controlAffinity:
                                  ListTileControlAffinity.leading,
                                  title: Text(
                                    it.label.trim().toUpperCase(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    moduleId,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  value: checked,
                                  onChanged: isSuper
                                      ? null
                                      : (v) async {
                                    if (v == null) return;
                                    await _persistModuleRead(
                                        user, moduleId, v);
                                  },
                                );
                              }),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// ✅ resolve controller no build: cria 1x e atualiza quando baseRole mudar.
class _RoleDropdown extends StatefulWidget {
  const _RoleDropdown({
    required this.baseRole,
    required this.onPick,
  });

  final roles.UserProfile baseRole;
  final Future<void> Function(roles.UserProfile picked) onPick;

  @override
  State<_RoleDropdown> createState() => _RoleDropdownState();
}

class _RoleDropdownState extends State<_RoleDropdown> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: roles.UserRoleCodec.label(widget.baseRole),
    );
  }

  @override
  void didUpdateWidget(covariant _RoleDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.baseRole != widget.baseRole) {
      final next = roles.UserRoleCodec.label(widget.baseRole);
      if (_ctrl.text != next) _ctrl.text = next;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DropDownButtonChange(
      labelText: 'Tipo de Usuário:',
      items: roles.UserProfile.values
          .map((r) => roles.UserRoleCodec.label(r))
          .toList(),
      controller: _ctrl,
      onChanged: (value) async {
        if (value == null) return;

        final picked = roles.UserProfile.values.firstWhere(
              (r) => roles.UserRoleCodec.label(r) == value,
          orElse: () => widget.baseRole,
        );

        if (picked == widget.baseRole) return;
        await widget.onPick(picked);
      },
    );
  }
}
