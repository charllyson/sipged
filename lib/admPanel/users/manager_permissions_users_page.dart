import 'package:flutter/material.dart';
import 'package:sisged/_blocs/system/user_bloc.dart';
import 'package:sisged/_datas/system/user_data.dart';
import '../../_datas/system/pages_data.dart';
import '../../screens/commons/photoCircle/photo_circle.dart';

class ManagerPermissionsUsersPage extends StatefulWidget {
  const ManagerPermissionsUsersPage({super.key});

  @override
  State<ManagerPermissionsUsersPage> createState() => _ManagerPermissionsUsersPageState();
}

class _ManagerPermissionsUsersPageState extends State<ManagerPermissionsUsersPage> {
  final UserBloc _userBloc = UserBloc();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Permissões de Usuários',
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('Permissões de Usuários')),
        backgroundColor: Colors.white,
        body: FutureBuilder<List<UserData>>(
          future: _userBloc.getAllUsers(),
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
                            Row(
                              children: [
                                Text('Tipo de Usuário: '),
                                SizedBox(width: 20),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade800,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 12,),
                                  child: DropdownButton<String>(
                                    isDense: false,
                                    underline: Container(),
                                    value: UserData.profile.contains(user.baseProfile) ? user.baseProfile : null,
                                    hint: const Text("Selecione", style: TextStyle(color: Colors.white)),
                                    items: UserData.profile.map((profile) => DropdownMenuItem(
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
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Divider(),
                        for (var module in PagesData.module) ...[
                          Text(module.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                          Wrap(
                            children: UserData.permission.map((permission) {
                              final perms = user.modulePermissions[module] ?? {};
                              final hasPermission = perms[permission] ?? false;
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: FilterChip(
                                      label: Text(permission),
                                      labelStyle: TextStyle(color: hasPermission ? Colors.white : Colors.grey),
                                      shape: RoundedRectangleBorder(
                                          side: BorderSide(color: hasPermission ? Colors.green.shade700 : Colors.grey),
                                          borderRadius: BorderRadius.circular(4)),
                                      backgroundColor: hasPermission ? Colors.white : Colors.grey.withOpacity(0.1),
                                      checkmarkColor: hasPermission ? Colors.white : Colors.grey,
                                      selectedColor: Colors.green,
                                      surfaceTintColor: Colors.green.shade300,
                                      selected: hasPermission,
                                      onSelected: (value) {
                                        setState(() {
                                          final updatedPerms = Map<String, bool>.from(perms);
                                          updatedPerms[permission] = value;
                                          user.modulePermissions[module] = updatedPerms;
                                          _userBloc.saveUser(userData: user);
                                        });
                                      },
                                    ),
                                  ),
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
      ),
    );
  }
}