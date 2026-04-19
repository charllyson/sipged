import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/system/login/login_cubit.dart';
import 'package:sipged/_blocs/system/user/user_bloc.dart';
import 'package:sipged/_blocs/system/user/user_data.dart';
import 'package:sipged/_widgets/images/photo_circle/photo_circle.dart';
import 'package:sipged/admPanel/system_hub_page.dart';

// ✅ helper de papéis globais
import 'package:sipged/_blocs/system/permitions/user_permission.dart' as roles;
import 'package:sipged/screens/common/profile/profile_page.dart';

class PopUpPhotoMenu extends StatelessWidget {
  const PopUpPhotoMenu({super.key});

  @override
  Widget build(BuildContext context) {
    // Lê o usuário atual do UserBloc (se ainda não carregou, mostra loading)
    final userData = context.select<UserBloc, UserData?>(
          (b) => b.state.initialized ? b.state.current : null,
    );

    if (userData == null) {
      return const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    // ✅ Usa o novo modelo para checar papel global
    final base = roles.roleForUser(userData); // BaseRole
    final isAdmin =
        base == roles.UserProfile.administrador || base == roles.UserProfile.desenvolvedor;

    return PopupMenuButton<String>(
      color: Colors.white,
      onSelected: (value) async {
        switch (value) {
          case 'perfil':
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const UserProfilePage()),
            );
            break;

          case 'administrador':
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => SystemHubPage()),
            );
            break;

          case 'sair':
          // ✅ Login agora é Cubit (não criar instância manual)
            await context.read<LoginCubit>().signOut();
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'perfil',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Olá, ${userData.name ?? ''}'),
              const SizedBox(height: 2),
              Text(
                userData.baseProfile ?? '',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
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
