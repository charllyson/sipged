import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:sisged/screens/commons/photoCircle/photo_circle.dart';
import 'package:sisged/_blocs/system/login/login_bloc.dart';
import 'package:sisged/_datas/system/user_data.dart';
import 'package:sisged/admPanel/settings_system_page.dart';
import 'package:sisged/_blocs/system/user_provider.dart';

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

    // Vincula-se ao usuário atual (stream do provider)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<UserProvider>().bindCurrentUser();
      }
    });

    // (Opcional) Ouça mudanças do login, se necessário
    _loginBloc.outState.listen((state) {
      // trate estados se quiser mostrar algo na UI
    });
  }

  @override
  void dispose() {
    // _loginBloc não expõe dispose(); se expuser, chame aqui.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (firebaseUser == null) {
      return const SizedBox.shrink();
    }

    return Consumer<UserProvider>(
      builder: (context, userProv, _) {
        final UserData? userData = userProv.userData;

        // Enquanto não carregou o usuário corrente
        if (userData == null) {
          return const Center(
            child: SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
          );
        }

        final isAdmin = (userData.baseProfile ?? '').toLowerCase() == 'administrador';

        return PopupMenuButton<String>(
          color: Colors.black54,
          onSelected: (value) {
            switch (value) {
              case 'administrador':
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => SettingsSystemPage()),
                );
                break;
              case 'sair':
                _loginBloc.signOut();
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem<String>(
              enabled: false,
              child: Text(
                'Olá, ${userData.name ?? ''}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            if (isAdmin)
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
            child: PhotoCircle(userData: userData),
          ),
        );
      },
    );
  }
}
