import 'package:flutter/material.dart';

import 'package:sipged/_blocs/system/user/user_data.dart';
import 'package:sipged/screens/common/profile/legal/legal_settings_page.dart';
import 'package:sipged/screens/common/profile/login/login_security_settings_page.dart';
import 'package:sipged/screens/common/profile/widgets/modern_card.dart';
import 'package:sipged/screens/common/profile/notification/notifications_settings_page.dart';
import 'package:sipged/screens/common/profile/personal/personal_info_settings_page.dart';
import 'package:sipged/screens/common/profile/widgets/profile_settings_tile.dart';

class ProfileSettingsList extends StatelessWidget {
  const ProfileSettingsList({
    super.key,
    required this.user,
  });

  final UserData user;

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => page,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          ProfileSettingsTile(
            icon: Icons.person_rounded,
            title: 'Informações pessoais',
            subtitle: 'Editar nome, sobrenome, foto, telefone e dados cadastrais.',
            iconColor: Colors.blue.shade700,
            onTap: () {
              _open(
                context,
                PersonalInfoSettingsPage(initialUser: user),
              );
            },
          ),
          const SizedBox(height: 10),
          ProfileSettingsTile(
            icon: Icons.notifications_active_rounded,
            title: 'Notificações',
            subtitle: 'Preferências de avisos, alertas, e notificações do sistema.',
            iconColor: Colors.orange.shade700,
            onTap: () {
              _open(
                context,
                const NotificationsSettingsPage(),
              );
            },
          ),
          const SizedBox(height: 10),
          ProfileSettingsTile(
            icon: Icons.gavel_rounded,
            title: 'Jurídico',
            subtitle: 'Termos, políticas, consentimentos e informações legais.',
            iconColor: Colors.deepPurple.shade700,
            onTap: () {
              _open(
                context,
                const LegalSettingsPage(),
              );
            },
          ),
          const SizedBox(height: 10),
          ProfileSettingsTile(
            icon: Icons.lock_rounded,
            title: 'Login e segurança',
            subtitle: 'Senha, autenticação, acesso e proteção da conta.',
            iconColor: Colors.green.shade700,
            onTap: () {
              _open(
                context,
                const LoginSecuritySettingsPage(),
              );
            },
          ),
        ],
      ),
    );
  }
}