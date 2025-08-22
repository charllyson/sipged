import 'package:flutter/material.dart';
import 'package:sisged/screens/commons/login/sign_in.dart';
import 'package:sisged/screens/menus/menu_list_page.dart';

import '_blocs/system/login/BootstrapUser.dart';
import '_blocs/system/login/auth_gate.dart';

class SisGed extends StatelessWidget {
  const SisGed({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SIGED',
      debugShowCheckedModeBanner: false,
      home: AuthGate(
        // Quando logado, primeiro garantimos UserData no Provider e só então abrimos a Home
        signedIn: BootstrapUser(child: const MenuListPage()),
        signedOut: const SignIn(),
      ),
    );
  }
}