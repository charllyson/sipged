// lib/screens/admin/manager_permissions_users_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_blocs/system/pages/pages_data.dart';
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
import 'package:siged/_blocs/system/permitions/page_permission.dart' as pp;

class ManagerPermissionsUsersPage extends StatefulWidget {
  const ManagerPermissionsUsersPage({super.key});

  @override
  State<ManagerPermissionsUsersPage> createState() => _ManagerPermissionsUsersPageState();
}

class _ManagerPermissionsUsersPageState extends State<ManagerPermissionsUsersPage> {
  bool _didInit = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _didInit) return;
      _didInit = true;
      context.read<UserBloc>().add(const UsersEnsureLoadedRequested(listenRealtime: true));
    });
  }

  Future<void> _persistRole(UserData user, roles.BaseRole newRole) async {
    await roles.setUserRole(user, newRole);
    context.read<UserBloc>().add(const UsersEnsureLoadedRequested(listenRealtime: true));
  }

  /// Liga/desliga SOMENTE o "read" do módulo (override). Outras flags são preservadas.
  Future<void> _persistModuleRead(UserData user, String module, bool allow) async {
    final current = pp.getOverrideForUserModule(user, module);
    final updated = current.copyWith(read: allow);
    await pp.setOverrideForUserModule(user, module, updated);
    context.read<UserBloc>().add(const UsersEnsureLoadedRequested(listenRealtime: true));
  }

  /// Agrupa por prefixo antes do primeiro '-' (process / operation / planning / traffic / financial / active ...)
  Map<String, List<String>> _groupModules(Iterable<String> modules) {
    final map = <String, List<String>>{};
    for (final m in modules) {
      final dash = m.indexOf('-');
      final key = (dash > 0 ? m.substring(0, dash) : m).toUpperCase();
      map.putIfAbsent(key, () => []).add(m);
    }
    // ordena módulos de cada grupo para ficar bonito
    for (final k in map.keys) {
      map[k]!.sort();
    }
    // ordem opcional de grupos no UI
    final order = ['DOCUMENTS', 'OPERATION', 'PLANNING', 'TRAFFIC', 'FINANCIAL', 'ACTIVE'];
    final sorted = <String, List<String>>{};
    for (final k in order) {
      if (map.containsKey(k)) sorted[k] = map[k]!;
    }
    // quaisquer grupos extras
    for (final k in map.keys) {
      if (!sorted.containsKey(k)) sorted[k] = map[k]!;
    }
    return sorted;
  }

  /// Marca/Desmarca todos os módulos do grupo (apenas read)
  Future<void> _persistGroupRead(UserData user, List<String> modules, bool allow) async {
    for (final m in modules) {
      final current = pp.getOverrideForUserModule(user, m);
      final updated = current.copyWith(read: allow);
      await pp.setOverrideForUserModule(user, m, updated);
    }
    context.read<UserBloc>().add(const UsersEnsureLoadedRequested(listenRealtime: true));
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

        if (state.loadUsersError != null && (state.loadUsersError?.isNotEmpty ?? false)) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(72),
                child: Padding(
                  padding: const EdgeInsets.only(left: 12.0),
                  child: const UpBar(leading: BackCircleButton()),
                )),
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
                      onPressed: () => context
                          .read<UserBloc>()
                          .add(const UsersEnsureLoadedRequested(listenRealtime: true)),
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
                )),
            body: const Center(child: Text('Nenhum usuário encontrado.')),
          );
        }

        final groups = _groupModules(PagesData.module);

        return Scaffold(
          appBar: const PreferredSize(
            preferredSize: Size.fromHeight(72),
            child: UpBar(leading: Padding(
              padding: EdgeInsets.only(left: 12.0),
              child: BackCircleButton(),
            )),
          ),
          backgroundColor: Colors.white,
          body: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
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
                    // Header
                    // Header do card de usuário — faixa cinza até o fim em telas grandes
                    Container(
                      width: double.infinity, // garante faixa cinza até a borda do card
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
                          final isWide = maxW >= 720; // desktop/largo
                          final dropWidth = 300.0;

                          if (isWide) {
                            // ====== LARGO: linha única (avatar + nome à esquerda, dropdown à direita)
                            return Row(
                              children: [
                                PhotoCircle(userData: user),
                                const SizedBox(width: 12),
                                // Nome ocupa o “meio” e empurra o dropdown para a direita
                                Expanded(
                                  child: Text(
                                    '${user.name ?? '-'} ${user.surname ?? ''}'.trim(),
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                SizedBox(
                                  width: dropWidth,
                                  child: DropDownButtonChange(
                                    labelText: 'Tipo de Usuário:',
                                    items: roles.BaseRole.values.map((r) => roles.baseRoleLabel(r)).toList(),
                                    controller: TextEditingController(text: roles.baseRoleLabel(baseRole)),
                                    onChanged: (value) async {
                                      if (value == null) return;
                                      final picked = roles.BaseRole.values.firstWhere(
                                            (r) => roles.baseRoleLabel(r) == value,
                                        orElse: () => baseRole,
                                      );
                                      await _persistRole(user, picked);
                                    },
                                  ),
                                ),
                              ],
                            );
                          }

                          // ====== ESTREITO: quebra em blocos verticais
                          return Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              PhotoCircle(userData: user),
                              ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: maxW - 80, minWidth: 100),
                                child: Text(
                                  '${user.name ?? '-'} ${user.surname ?? ''}'.trim(),
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                  softWrap: true,
                                ),
                              ),
                              SizedBox(
                                width: maxW,
                                child: DropDownButtonChange(
                                  labelText: 'Tipo de Usuário:',
                                  items: roles.BaseRole.values.map((r) => roles.baseRoleLabel(r)).toList(),
                                  controller: TextEditingController(text: roles.baseRoleLabel(baseRole)),
                                  onChanged: (value) async {
                                    if (value == null) return;
                                    final picked = roles.BaseRole.values.firstWhere(
                                          (r) => roles.baseRoleLabel(r) == value,
                                      orElse: () => baseRole,
                                    );
                                    await _persistRole(user, picked);
                                  },
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
                        final groupLabel = entry.key; // já vem UPPERCASE
                        final mods = entry.value;

                        // estado do grupo (com base apenas no override.read)
                        int checkedCount = 0;
                        for (final m in mods) {
                          if (pp.getOverrideForUserModule(user, m).read) {
                            checkedCount++;
                          }
                        }
                        final all = checkedCount == mods.length && mods.isNotEmpty;
                        final none = checkedCount == 0;
                        final triValue = all ? true : (none ? false : null);

                        return Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.grey),
                          child: ExpansionTile(
                            collapsedBackgroundColor: Colors.white,
                            backgroundColor: Colors.grey.shade100,
                            title: Row(
                              children: [
                                // Checkbox do grupo (tri-state)
                                Checkbox(
                                  tristate: true,
                                  value: triValue,
                                  onChanged: (v) async {
                                    final target = (v ?? false);
                                    await _persistGroupRead(user, mods, target);
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
                              ...mods.map((module) {
                                final ov = pp.getOverrideForUserModule(user, module);
                                final checked = ov.read; // só override

                                return CheckboxListTile(
                                  dense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                                  controlAffinity: ListTileControlAffinity.leading,
                                  title: Text(
                                    module.toUpperCase(),
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  value: checked,
                                  onChanged: (v) async {
                                    if (v == null) return;
                                    await _persistModuleRead(user, module, v);
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
