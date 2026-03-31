import 'package:flutter/material.dart';
import 'package:sipged/_widgets/cards/basic/basic_card.dart';
import 'package:sipged/_widgets/tiles/tile_widget.dart';
import 'package:sipged/admPanel/system/manager_permissions_users_page.dart';

import '../../_widgets/buttons/back_circle_button.dart';
import '../../_widgets/menu/upBar/up_bar.dart';

class SettingsSystemPage extends StatelessWidget {
  const SettingsSystemPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final topSafe = MediaQuery.of(context).padding.top;
    const barHeight = 72.0;
    final topPadding = topSafe + barHeight + 12;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
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
          if (constraints.maxWidth >= 1200 && constraints.maxWidth < 1600) {
            maxW = 1000;
          }

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
                      MaterialPageRoute(
                        builder: (_) => const ManagerPermissionsUsersPage(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  BasicCard(
                    isDark: isDark,
                    padding: const EdgeInsets.all(12),
                    borderRadius: 12,
                    backgroundColor: Colors.amber.withValues(alpha: 0.08),
                    borderColor: Colors.amber.withValues(alpha: 0.25),
                    enableShadow: false,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 18,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Aqui você pode adicionar outras ferramentas específicas '
                                'do sistema, como auditoria, logs, preferências, temas '
                                'e dicionário de dados.',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.35,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
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