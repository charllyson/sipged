import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/system/login/login_cubit.dart';
import 'package:sipged/_blocs/system/user/user_cubit.dart';
import 'package:sipged/_blocs/system/user/user_data.dart';
import 'package:sipged/_widgets/images/photo_circle/photo_circle.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots_grey.dart';
import 'package:sipged/admPanel/system_hub_page.dart';
import 'package:sipged/_blocs/system/permitions/user_permission.dart' as roles;
import 'package:sipged/screens/common/profile/profile_page.dart';

class PopUpPhotoMenu extends StatelessWidget {
  final double photoSize;

  const PopUpPhotoMenu({
    super.key,
    this.photoSize = 40,
  });

  @override
  Widget build(BuildContext context) {
    final userData = context.select<UserCubit, UserData?>(
          (c) => c.state.initialized ? c.state.current : null,
    );

    if (userData == null) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: LoadingTreeDots(
          size: 20,
          strokeWidth: 2,
          centered: false,
        ),
      );
    }

    final base = roles.roleForUser(userData);
    final isAdmin = base == roles.UserProfile.administrador ||
        base == roles.UserProfile.desenvolvedor;

    return PopupMenuButton<String>(
      color: Colors.white,
      padding: EdgeInsets.zero,
      menuPadding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 180),
      onSelected: (value) async {
        switch (value) {
          case 'perfil':
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const UserProfilePage(),
              ),
            );
            break;

          case 'administrador':
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const SystemHubPage(),
              ),
            );
            break;

          case 'sair':
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
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
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
              Text(
                'Sair',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
      ],
      child: SizedBox.square(
        dimension: photoSize,
        child: PhotoCircle(
          userData: userData,
          size: photoSize,
        ),
      ),
    );
  }
}