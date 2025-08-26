import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:sisged/screens/commons/login/sign_in.dart';
import 'package:sisged/screens/menus/menu_list_page.dart';

import '_blocs/system/login/login_bloc.dart';
import '_blocs/system/user/user_repository.dart';
import '_blocs/system/user/user_data.dart';

class SisGed extends StatelessWidget {
  const SisGed({super.key});

  @override
  Widget build(BuildContext context) {
    final loginBloc = context.read<LoginBloc>();
    final userRepo  = context.read<UserRepository>();

    return MaterialApp(
      title: 'SIGED',
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<LoginState>(
        stream: loginBloc.outState,
        initialData: LoginState.loading,
        builder: (context, snapshot) {
          final state = snapshot.data;
          final firebaseUser = FirebaseAuth.instance.currentUser;

          if (state == LoginState.loading) {
            return const Scaffold(
              backgroundColor: Colors.white,
              body: Center(child: Text('Verificando os dados...')),
            );
          }

          if (state == LoginState.fail || firebaseUser == null) {
            return const SignIn();
          }

          // Estados de sucesso
          if ([
            LoginState.successProfileCommom,
            LoginState.successProfileGovernment,
            LoginState.successProfileCollaborator,
            LoginState.successProfileCompany,
          ].contains(state)) {
            // Busca o UserData no Firestore
            return FutureBuilder<UserData?>(
              future: userRepo.getById(firebaseUser.uid),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    backgroundColor: Colors.white,
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                final userData = userSnapshot.data;
                if (userData == null) {
                  // usuário logado mas sem documento no Firestore
                  return const SignIn();
                }

                // Injeta UserData no subtree — simples e sem precisar de UserProvider
                return Provider<UserData>.value(
                  value: userData,
                  child: const MenuListPage(),
                );
              },
            );
          }

          return const SignIn();
        },
      ),
    );
  }
}
