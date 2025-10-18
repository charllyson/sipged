// lib/_widgets/appbar/pop_up_photo_menu.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_blocs/system/login/login_bloc.dart';
import 'package:siged/_blocs/system/user/user_bloc.dart';
import 'package:siged/_blocs/system/user/user_data.dart';
import 'package:siged/_widgets/images/photo_circle/photo_circle.dart';
import 'package:siged/admPanel/settings_system_hub_page.dart';

// ✅ novo helper de papéis globais
import 'package:siged/_blocs/system/permitions/user_permission.dart' as roles;
import 'package:siged/screens/menus/profile_page.dart';

class PopUpPhotoMenu extends StatefulWidget {
  const PopUpPhotoMenu({super.key});

  @override
  State<PopUpPhotoMenu> createState() => _PopUpPhotoMenuState();
}

class _PopUpPhotoMenuState extends State<PopUpPhotoMenu> {
  late final LoginBloc _loginBloc;
  final User? firebaseUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loginBloc = LoginBloc();
    _loginBloc.outState.listen((_) {});
  }

  @override
  void dispose() {
    // se o LoginBloc tiver dispose(), chame aqui
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (firebaseUser == null) {
      return const SizedBox.shrink();
    }

    // Lê o usuário atual do UserBloc
    final userData = context.select<UserBloc, UserData?>(
          (b) => b.state.initialized ? b.state.current : null,
    );

    if (userData == null) {
      return const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),//
      );
    }

    // ✅ Usa o novo modelo para checar papel global
    final base = roles.roleForUser(userData); // BaseRole
    final isAdmin = base == roles.BaseRole.ADMINISTRADOR || base == roles.BaseRole.DESENVOLVEDOR;

    return PopupMenuButton<String>(
      color: Colors.white,
      onSelected: (value) {
        switch (value) {
          case 'administrador':
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => SettingsSystemHubPage()),
            );
            break;
          case 'sair':
            _loginBloc.signOut();
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          onTap: (){
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const UserProfilePage()),
            );
          },
          child: Column(
            children: [
              Text(
                'Olá, ${userData.name ?? ''}',
              ),
              Text(
                userData.baseProfile ?? '',
                style: TextStyle(color: Colors.grey, fontSize: 12),//
              ),
            ],
          ),
        ),
        if (isAdmin)
          const PopupMenuItem<String>(
            value: 'administrador',
            child: Row(
              children: [
                Icon(Icons.admin_panel_settings),
                SizedBox(width: 8),
                Text('Administrador'),
              ],
            ),
          ),
        const PopupMenuItem<String>(
          value: 'sair',
          child: Row(
            children: [
              Icon(Icons.logout, color: Colors.red),
              SizedBox(width: 8),
              Text('Sair', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.only(right: 16.0),
        child: PhotoCircle(userData: userData),
      ),
    );
  }
}
