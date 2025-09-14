import 'package:flutter/material.dart';
import 'package:siged/admPanel/manager_permissions_users_page.dart';

import '../_widgets/buttons/back_circle_button.dart';
import '../_widgets/upBar/up_bar.dart';

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
                  _tile(
                    context,
                    title: 'Gerenciar permissões de usuário',
                    subtitle: 'Perfis base + permissões granulares por módulo',
                    icon: Icons.security_outlined,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ManagerPermissionsUsersPage()),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const _Info(
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

// ---------------- helpers UI ----------------

Widget _tile(
    BuildContext context, {
      required String title,
      required String subtitle,
      required IconData icon,
      required VoidCallback onTap,
      Color? tileColor,
    }) {
  final bg = tileColor ?? Colors.white10;
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        hoverColor: Colors.black.withOpacity(0.04), // hover (web/desktop)
        splashColor: Colors.black.withOpacity(0.08),
        child: Container(
          color: Colors.black12,
          child: ListTile(
            leading: Icon(icon),
            title: Text(title),
            subtitle: Text(subtitle),
            trailing: const Icon(Icons.arrow_forward_ios),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    ),
  );
}

class _Info extends StatelessWidget {
  const _Info({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: Colors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
