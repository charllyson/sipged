import 'package:flutter/material.dart';
import 'package:sisged/_blocs/system/user_bloc.dart';
import 'package:sisged/_datas/system/user_data.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserGreeting extends StatelessWidget {
  final UserBloc userBloc;
  final User? firebaseUser;

  const UserGreeting({
    super.key,
    required this.userBloc,
    required this.firebaseUser,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserData?>(
      future: userBloc.getUserData(uid: firebaseUser?.uid ?? ''),
      builder: (context, snapshot) {
        final userData = snapshot.data;
        return Text(
          userData != null ? 'Olá, ${userData.name}' : 'Olá, Usuário',
          style: const TextStyle(color: Colors.white, fontSize: 12),
        );
      },
    );
  }
}
