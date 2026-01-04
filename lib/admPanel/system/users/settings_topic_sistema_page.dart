import 'package:flutter/material.dart';
import 'package:siged/_widgets/tiles/tile_widget.dart';
import 'package:siged/admPanel/firebase/settings_topic_firebase_page.dart';
import 'package:siged/admPanel/system/users/manager_permissions_users_page.dart';
import 'package:siged/_widgets/info/info_widget.dart';

import '../../../_widgets/buttons/back_circle_button.dart';
import '../../../_widgets/menu/upBar/up_bar.dart';

class SettingsTopicSistemaPage extends StatelessWidget {
  const SettingsTopicSistemaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final topSafe = MediaQuery.of(context).padding.top;
    const barHeight = 72.0; // mantenha igual ao usado na página Firebase
    final topPadding = topSafe + barHeight + 12;

    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        flexibleSpace: SafeArea(
          bottom: false,
          child: UpBar(
            leading: const Padding(
              padding: EdgeInsets.only(left: 12.0),
              child: BackCircleButton(),
            ),
          ),
        ),
        toolbarHeight: barHeight,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          double maxW = constraints.maxWidth;
          if (constraints.maxWidth >= 1600) maxW = 1100;
          if (constraints.maxWidth >= 1200 && constraints.maxWidth < 1600) maxW = 1000;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxW),
              child: ListView(
                padding: EdgeInsets.fromLTRB(16, topPadding, 16, 24),
                children: [
                  TileWidget(
                    title: 'Gerenciar permissões de usuário',
                    subtitle: 'Perfis base + permissões granulares por módulo',
                    leading: Icons.security_outlined,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ManagerPermissionsUsersPage()),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const info(
                    text:
                    'Aqui você pode adicionar outras ferramentas específicas do sistema '
                        '(auditoria, logs, preferências, temas, dicionário de dados, etc.).',
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
