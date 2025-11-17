import 'package:flutter/material.dart';
import 'package:siged/_widgets/buttons/back_circle_button.dart';
import 'package:siged/_widgets/cards/topic_card.dart';
import 'package:siged/_widgets/upBar/up_bar.dart';
import 'package:siged/_widgets/cards/hub_card.dart';

// Páginas por tópico
import 'package:siged/admPanel/system/users/settings_topic_sistema_page.dart';
import 'firebase/settings_topic_firebase_page.dart';
import 'converters/settings_topic_conversores_page.dart';
import 'migrations/settings_topic_migracoes_page.dart';

class SystemHubPage extends StatelessWidget {
  const SystemHubPage({super.key});

  int _gridCountForWidth(double w) {
    if (w >= 1400) return 4;
    if (w >= 1000) return 3;
    if (w >= 650)  return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final cards = <HubCard>[
      HubCard(
        title: 'Firebase',
        subtitle: 'Firestore, Storage, manutenção',
        icon: Icons.cloud_outlined,
        color: Colors.blueGrey.shade700,
        builder: (_) => const SettingsTopicFirebasePage(),
      ),
      HubCard(
        title: 'Sistema',
        subtitle: 'Usuários & permissões',
        icon: Icons.manage_accounts_outlined,
        color: Colors.teal.shade700,
        builder: (_) => const SettingsTopicSistemaPage(),
      ),
      HubCard(
        title: 'Conversores',
        subtitle: 'Excel → JSON / Firebase',
        icon: Icons.table_chart_outlined,
        color: Colors.indigo.shade700,
        builder: (_) => const SettingsTopicConversoresPage(),
      ),
      HubCard(
        title: 'Migrações & Limpeza',
        subtitle: 'Migrar docs, apagar coleções & campos',
        icon: Icons.sync_alt_outlined,
        color: Colors.deepOrange.shade700,
        builder: (_) => const SettingsTopicMigracoesPage(),
      ),
    ];

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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Stack(
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
                    return TopicCard(
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
      ),
    );
  }
}