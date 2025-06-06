import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sisgeo/screens/commons/upBar/photo_circle.dart';
import '../../../_blocs/login/login_bloc.dart';
import '../../../_blocs/user/user_bloc.dart';
import '../../../_datas/user/user_data.dart';

class PopUpMenu extends StatefulWidget {
  const PopUpMenu({super.key});

  @override
  State<PopUpMenu> createState() => _PopUpMenuState();
}

class _PopUpMenuState extends State<PopUpMenu> {
  late LoginBloc _loginBloc;
  late UserBloc _userBloc = UserBloc();
  User? firebaseUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    _userBloc = UserBloc();
    _loginBloc = LoginBloc();
    _loginBloc.outState.listen((state) {
      switch (state) {
        case LoginState.successProfileCommom:
          break;
        case LoginState.successProfileGovernment:
          break;
        case LoginState.successProfileCollaborator:
          break;
        case LoginState.successProfileCompany:
          break;
        case LoginState.fail:
          break;
        case LoginState.loading:
        case LoginState.idle:
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _userBloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (firebaseUser == null) {
      return const SizedBox.shrink(); // ou algum loader
    }

    return FutureBuilder<UserData?>(
      future: _userBloc.getUserData(uid: firebaseUser!.uid),
      builder: (context, userData) {
        if (!userData.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.grey),
          );
        }

        return PopupMenuButton<String>(
          color: Colors.black54,
          onSelected: (value) {
            switch (value) {
              case 'perfil':
                Navigator.pushNamed(context, '/perfil');
                break;
              case 'configuracoes':
                Navigator.pushNamed(context, '/configuracoes');
                break;
              case 'administrador':
                Navigator.pushReplacementNamed(context, '/admPage');
                break;
              case 'sair':
                _loginBloc.signOut();
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem<String>(
              enabled: false,
              child: Text('Olá, ${userData.data?.name ?? ''}', style: const TextStyle(color: Colors.white)),
            ),
            const PopupMenuItem<String>(
              value: 'perfil',
              child: Row(
                children: [
                  Icon(Icons.person, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Perfil', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'configuracoes',
              child: Row(
                children: [
                  Icon(Icons.settings, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Configurações', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'administrador',
              child: Row(
                children: [
                  Icon(Icons.admin_panel_settings, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Administrador', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'sair',
              child: Row(
                children: [
                  Icon(Icons.logout, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Sair', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ],
          child: Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: PhotoCircle(userData: userData.data),
          ),
        );

      },
    );
  }
}