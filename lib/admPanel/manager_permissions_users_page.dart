import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_blocs/system/pages/pages_data.dart';
import 'package:siged/_blocs/system/user/user_data.dart';
import 'package:siged/_widgets/photoCircle/photo_circle.dart';

// Bloc de usuário
import 'package:siged/_blocs/system/user/user_bloc.dart';
import 'package:siged/_blocs/system/user/user_event.dart';
import 'package:siged/_blocs/system/user/user_state.dart';

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
    // Garante usuários carregados + realtime
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _didInit) return;
      _didInit = true;
      context.read<UserBloc>().add(const UsersEnsureLoadedRequested(listenRealtime: true));
    });
  }

  Future<void> _saveUser(UserData user) async {
    // Preferimos passar pelo Bloc para atualizar cache local
    context.read<UserBloc>().add(UserSaveRequested(user));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserBloc, UserState>(
      builder: (context, state) {
        // Estados de carregamento/erro/vazio
        if (state.isLoadingUsers && state.all.isEmpty) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state.loadUsersError != null && (state.loadUsersError?.isNotEmpty ?? false)) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(title: const Text('Permissões de Usuários')),
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
            appBar: AppBar(title: const Text('Permissões de Usuários')),
            body: const Center(child: Text('Nenhum usuário encontrado.')),
          );
        }

        // Lista de usuários
        return Scaffold(
          appBar: AppBar(title: const Text('Permissões de Usuários')),
          backgroundColor: Colors.white,
          body: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          PhotoCircle(userData: user),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${user.name ?? '-'} ${user.surname ?? ''}'.trim(),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Tipo de usuário
                          Row(
                            children: [
                              const Text('Tipo de Usuário:'),
                              const SizedBox(width: 12),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    isDense: false,
                                    value: UserData.permissionProfile.contains(user.baseProfile)
                                        ? user.baseProfile
                                        : null,
                                    hint: const Text('Selecione'),
                                    items: UserData.permissionProfile
                                        .map((profile) => DropdownMenuItem(
                                      value: profile,
                                      child: Text(profile),
                                    ))
                                        .toList(),
                                    onChanged: (value) async {
                                      if (value == null) return;
                                      setState(() => user.baseProfile = value);
                                      await _saveUser(user);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const Divider(),

                      // Permissões por módulo
                      for (final module in PagesData.module) ...[
                        Text(
                          module.toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),

                        Wrap(
                          children: UserData.permissionType.map((permission) {
                            final current = Map<String, bool>.from(
                              user.modulePermissions[module] ?? const {},
                            );
                            final has = current[permission] == true;

                            return Padding(
                              padding: const EdgeInsets.all(6.0),
                              child: FilterChip(
                                label: Text(permission),
                                labelStyle: TextStyle(
                                  color: has ? Colors.white : Colors.black54,
                                ),
                                backgroundColor:
                                has ? Colors.green : Colors.grey.withOpacity(0.1),
                                selectedColor: Colors.green,
                                checkmarkColor: Colors.white,
                                selected: has,
                                onSelected: (value) async {
                                  setState(() {
                                    current[permission] = value;
                                    user.modulePermissions[module] = current;
                                  });
                                  await _saveUser(user);
                                },
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  side: BorderSide(
                                    color: has ? Colors.green.shade700 : Colors.grey,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
