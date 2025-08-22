import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sisged/_blocs/system/login/splash_page.dart';
import 'package:sisged/_blocs/system/user_provider.dart';

import 'package:sisged/_datas/system/user_data.dart';
import 'package:sisged/_repository/system/user_repository.dart';
import 'package:sisged/screens/commons/login/sign_in.dart';

/// Carrega o documento do usuário uma vez, ajusta no UserProvider e então libera a UI.
class BootstrapUser extends StatelessWidget {
  final Widget child;
  const BootstrapUser({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SignIn(); // defesa adicional

    final repo = context.read<UserRepository>();

    return FutureBuilder<UserData?>(
      future: repo.getById(user.uid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SplashPage();
        }

        final userData = snap.data;
        if (userData == null) {
          // Usuário autenticado mas sem doc -> leve para o SignIn/Onboarding
          return const SignIn();
        }

        // Evita setState no meio do build: faz o set no próximo frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final userProvider = context.read<UserProvider>();
          if (userProvider.userData?.id != userData.id) {
            userProvider.setUserData(userData);
          }
        });

        return child;
      },
    );
  }
}

