import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:sisged/_datas/system/pages_data.dart';
import 'package:sisged/_datas/system/user_data.dart';
import 'package:sisged/screens/commons/photoCircle/photo_circle.dart';
import 'package:sisged/_blocs/system/user_provider.dart';
import 'package:sisged/_repository/system/user_repository.dart'; // serviço p/ salvar

class ManagerPermissionsUsersPage extends StatefulWidget {
  const ManagerPermissionsUsersPage({super.key});

  @override
  State<ManagerPermissionsUsersPage> createState() => _ManagerPermissionsUsersPageState();
}

class _ManagerPermissionsUsersPageState extends State<ManagerPermissionsUsersPage> {
  bool _didInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;
    // carrega usuários e opcionalmente assina realtime
    // se não quiser realtime, passe listenRealtime: false
    context.read<UserProvider>().ensureLoaded(listenRealtime: true);
  }

  Future<void> _saveUser(BuildContext context, UserData user) async {
    // persiste direto no repositório
    await context.read<UserRepository>().save(user);
    // o UserProvider assinado em realtime vai refletir a mudança;
    // se não estiver em realtime, você pode chamar ensureLoaded() de novo.
  }

  @override
  Widget build(BuildContext context) {
    final users = context.watch<UserProvider>().userDataList; // lista imutável

    return Scaffold(
      appBar: AppBar(title: const Text('Permissões de Usuários')),
      backgroundColor: Colors.white,
      body: users.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
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
                                value: UserData.profile.contains(user.baseProfile)
                                    ? user.baseProfile
                                    : null,
                                hint: const Text('Selecione'),
                                items: UserData.profile
                                    .map((profile) => DropdownMenuItem(
                                  value: profile,
                                  child: Text(profile),
                                ))
                                    .toList(),
                                onChanged: (value) async {
                                  if (value == null) return;
                                  setState(() => user.baseProfile = value);
                                  await _saveUser(context, user);
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
                      children: UserData.permission.map((permission) {
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
                              await _saveUser(context, user);
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
  }
}
