import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:sisged/_blocs/system/user_provider.dart';
import 'package:sisged/_datas/system/user_data.dart';

class UserGreeting extends StatelessWidget {
  final User? firebaseUser;

  const UserGreeting({
    super.key,
    required this.firebaseUser,
  });

  @override
  Widget build(BuildContext context) {
    if (firebaseUser == null) {
      return const Text(
        'Olá, Usuário',
        style: TextStyle(color: Colors.white, fontSize: 12),
      );
    }

    final uid = firebaseUser!.uid;

    return FutureBuilder<UserData?>(
      // 1) tenta o current do provider; 2) se null, busca por id (com cache interno)
      future: () async {
        final prov = context.read<UserProvider>();
        final current = prov.userData;
        if (current?.id == uid) return current;
        return prov.fetchById(uid);
      }(),
      builder: (context, snap) {
        final user = snap.data;
        final name = (user?.name?.isNotEmpty ?? false) ? user!.name! : 'Usuário';
        return Text(
          'Olá, $name',
          style: const TextStyle(color: Colors.white, fontSize: 12),
        );
      },
    );
  }
}
