// lib/screens/system/manager_permissions_users_page.dart
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

  Future<void> _persistRole(UserData user, roles.UserProfile newRole) async {
    // Se você implementou o setUserRole com flag legado, pode ligar:
    // await roles.setUserRole(user, newRole, writeLegacyBaseProfile: true);
    await roles.setUserRole(user, newRole);

    if (!mounted) return;
    context
        .read<UserBloc>()
        .add(const UsersEnsureLoadedRequested(listenRealtime: true));
  }

  /// Liga/desliga SOMENTE o "read" do módulo (override). Outras flags são preservadas.
  Future<void> _persistModuleRead(
      UserData user, String module, bool allow) async {
    final current = pp.getOverrideForUserModule(user, module);
    final updated = current.copyWith(read: allow);
    await pp.setOverrideForUserModule(user, module, updated);

    if (!mounted) return;
    context
        .read<UserBloc>()
        .add(const UsersEnsureLoadedRequested(listenRealtime: true));
  }

  /// Marca/Desmarca todos os módulos do grupo (apenas read)
  Future<void> _persistGroupRead(
      UserData user, List<String> modules, bool allow) async {
    for (final m in modules) {
      final current = pp.getOverrideForUserModule(user, m);
      final updated = current.copyWith(read: allow);
      await pp.setOverrideForUserModule(user, m, updated);
    }

    if (!mounted) return;
    context
        .read<UserBloc>()
        .add(const UsersEnsureLoadedRequested(listenRealtime: true));
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
            body: const Center(child: Text('Nenhum usuário encontrado.')),
          );
        }

        // ✅ vem do menu real
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

              // ✅ IMPORTANTE: baseRole deve ser derivado com normalização
              final baseRole = roles.roleForUser(user);

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

                          final nameText =
                          '${user.name ?? '-'} ${user.surname ?? ''}'.trim();

                          if (isWide) {
                            return Row(
                              children: [
                                PhotoCircle(userData: user),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    nameText,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
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
                                constraints:
                                BoxConstraints(maxWidth: maxW - 80, minWidth: 100),
                                child: Text(
                                  nameText,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                  softWrap: true,
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
                        height: 1, color: Colors.grey, width: double.infinity),

                    // ===== Acesso aos MÓDULOS agrupados =====
                    Column(
                      children: groups.entries.map((entry) {
                        final groupLabel = entry.key;
                        final items = entry.value;
                        final modules = items.map((e) => e.module).toList();

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
                                  value: triValue,
                                  onChanged: (v) async {
                                    final target = (v ?? false);
                                    await _persistGroupRead(
                                        user, modules, target);
                                  },
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  groupLabel,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: .5,
                                  ),
                                ),
                              ],
                            ),
                            children: [
                              ...items.map((it) {
                                final ov = pp.getOverrideForUserModule(
                                    user, it.module);
                                final checked = ov.read;

                                return CheckboxListTile(
                                  dense: true,
                                  contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                                  controlAffinity:
                                  ListTileControlAffinity.leading,
                                  title: Text(
                                    it.label.toUpperCase(),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: Text(
                                    it.module,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  value: checked,
                                  onChanged: (v) async {
                                    if (v == null) return;
                                    await _persistModuleRead(
                                        user, it.module, v);
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
      // ✅ Ajuste: label centralizado no codec
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

        // ✅ mantém compatibilidade com DropDownButtonChange (que retorna label),
        // mas usa o codec como fonte única.
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
