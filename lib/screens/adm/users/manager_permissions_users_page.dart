import 'package:flutter/material.dart';
import 'package:sisgeo/_blocs/user/user_bloc.dart';
import 'package:sisgeo/_datas/user/user_data.dart';
import '../../commons/upBar/photo_circle.dart';

class ManagerPermissionsUsersPage extends StatefulWidget {
  const ManagerPermissionsUsersPage({super.key});

  @override
  State<ManagerPermissionsUsersPage> createState() => _ManagerPermissionsUsersPageState();
}

class _ManagerPermissionsUsersPageState extends State<ManagerPermissionsUsersPage> {
  final UserBloc _userBloc = UserBloc();
  final List<String> profiles = ['Leitor', 'Colaborador', 'Administrador'];
  final List<String> modules = ['contratos', 'cronograma', 'financeiro'];
  final List<String> permissionTypes = ['read', 'create', 'edit', 'delete'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Permissões de Usuários')),
      body: FutureBuilder<List<UserData>>(
        future: _userBloc.getAllUsers(context),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final users = snapshot.data!;
          return ListView.builder(
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
                      Row(
                        children: [
                          PhotoCircle(userData: user),
                          const SizedBox(width: 12),
                          Text('${user.name} ${user.surname}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          const Spacer(),
                          DropdownButton<String>(
                            value: profiles.contains(user.baseProfile) ? user.baseProfile : null,
                            hint: const Text("Perfil"),
                            items: profiles.map((profile) => DropdownMenuItem(
                              value: profile,
                              child: Text(profile),
                            )).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => user.baseProfile = value);
                                _userBloc.saveUser(userData: user);
                              }
                            },
                          ),
                        ],
                      ),
                      const Divider(),
                      for (var module in modules) ...[
                        Text(module.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                        Wrap(
                          children: permissionTypes.map((permission) {
                            final perms = user.modulePermissions[module] ?? {};
                            final hasPermission = perms[permission] ?? false;
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Checkbox(
                                  value: hasPermission,
                                  onChanged: (value) {
                                    setState(() {
                                      final updatedPerms = Map<String, bool>.from(perms);
                                      updatedPerms[permission] = value ?? false;
                                      user.modulePermissions[module] = updatedPerms;
                                      _userBloc.saveUser(userData: user);
                                    });
                                  },
                                ),
                                Text(permission),
                              ],
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
          );
        },
      ),
    );
  }
}