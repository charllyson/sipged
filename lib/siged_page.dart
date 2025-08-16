import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sisged/screens/commons/login/sign_in.dart';
import 'package:sisged/screens/menus/side_menu_page.dart';

import '_blocs/system/login_bloc.dart';
import '_blocs/system/user_bloc.dart';
import '_datas/system/user_data.dart';
import '_provider/user/user_provider.dart';

class SisGed extends StatelessWidget {
  const SisGed({super.key});
  @override
  Widget build(BuildContext context) {
    final loginBloc = Provider.of<LoginBloc>(context, listen: false);
    final userBloc = Provider.of<UserBloc>(context, listen: false);
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

          if ([
            LoginState.successProfileCommom,
            LoginState.successProfileGovernment,
            LoginState.successProfileCollaborator,
            LoginState.successProfileCompany,
          ].contains(state)) {
            return FutureBuilder<UserData?>(
              future: userBloc.getUserData(uid: firebaseUser.uid),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) {
                  return const Scaffold(
                      backgroundColor: Colors.white,
                      body: Center(child: CircularProgressIndicator()));
                }

                final userData = userSnapshot.data!;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final userProvider = context.read<UserProvider>();
                  if (userProvider.userData?.id != userData.id) { // <- ajuste aqui
                    userProvider.setUserData(userData);
                  }
                });
                return SideMenuPage();
              },
            );
          }

          return const SignIn();
        },
      ),
    );
  }
}
