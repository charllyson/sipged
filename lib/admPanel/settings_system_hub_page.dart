import 'package:flutter/material.dart';
import 'package:siged/_widgets/buttons/back_circle_button.dart';
import 'package:siged/_widgets/upBar/up_bar.dart';

// Páginas por tópico
import 'package:siged/admPanel/settings_topic_sistema_page.dart';
import 'settings_topic_firebase_page.dart';
import 'settings_topic_conversores_page.dart';
import 'settings_topic_migracoes_page.dart';

class SettingsSystemHubPage extends StatelessWidget {
  const SettingsSystemHubPage({super.key});

  int _gridCountForWidth(double w) {
    if (w >= 1400) return 4;
    if (w >= 1000) return 3;
    if (w >= 650)  return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final cards = <_HubCard>[
      _HubCard(
        title: 'Firebase',
        subtitle: 'Firestore, Storage, manutenção',
        icon: Icons.cloud_outlined,
        color: Colors.blueGrey.shade700,
        builder: (_) => const SettingsTopicFirebasePage(),
      ),
      _HubCard(
        title: 'Sistema',
        subtitle: 'Usuários & permissões',
        icon: Icons.manage_accounts_outlined,
        color: Colors.teal.shade700,
        builder: (_) => const SettingsTopicSistemaPage(),
      ),
      _HubCard(
        title: 'Conversores',
        subtitle: 'Excel → JSON / Firebase',
        icon: Icons.table_chart_outlined,
        color: Colors.indigo.shade700,
        builder: (_) => const SettingsTopicConversoresPage(),
      ),
      _HubCard(
        title: 'Migrações & Limpeza',
        subtitle: 'Migrar docs, apagar coleções & campos',
        icon: Icons.sync_alt_outlined,
        color: Colors.deepOrange.shade700,
        builder: (_) => const SettingsTopicMigracoesPage(),
      ),
    ];

    final topSafe = MediaQuery.of(context).padding.top;
    final topPadding = topSafe + 72 + 16; // empurra o grid pra baixo da UpBar

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
        toolbarHeight: 72,
      ),
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final cross = _gridCountForWidth(constraints.maxWidth);
              return GridView.builder(
                scrollDirection: Axis.vertical,
                physics: const AlwaysScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cross,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                ),
                itemCount: cards.length,
                itemBuilder: (context, i) {
                  final c = cards[i];
                  return _TopicCard(
                    title: c.title,
                    subtitle: c.subtitle,
                    icon: c.icon,
                    color: c.color,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: c.builder),
                    ),
                  );
                },
              );
            },
          ),

        ],
      ),
    );
  }
}

class _HubCard {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final WidgetBuilder builder;

  _HubCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.builder,
  });
}

class _TopicCard extends StatelessWidget {
  const _TopicCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: color.withOpacity(0.25),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Icon(icon, size: 42, color: Colors.white70),
              ),
              Align(
                alignment: Alignment.bottomLeft,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
