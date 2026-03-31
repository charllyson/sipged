import 'package:flutter/material.dart';
import 'package:sipged/_widgets/buttons/back_circle_button.dart';
import 'package:sipged/_widgets/cards/basic/basic_card.dart';
import 'package:sipged/_widgets/menu/upBar/up_bar.dart';

import 'package:sipged/admPanel/system/settings_system_page.dart';
import 'firebase/settings_firebase_page.dart';
import 'migrations/settings_topic_migracoes_page.dart';

class SystemHubPage extends StatelessWidget {
  const SystemHubPage({super.key});

  int _gridCountForWidth(double w) {
    if (w >= 1400) return 4;
    if (w >= 1000) return 3;
    if (w >= 650) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cards = <BasicCardItem<WidgetBuilder>>[
      BasicCardItem<WidgetBuilder>(
        title: 'Firebase',
        subtitle: 'Firestore, Storage, manutenção',
        icon: Icons.cloud_outlined,
        color: Colors.blueGrey.shade700,
        value: (_) => const SettingsFirebasePage(),
      ),
      BasicCardItem<WidgetBuilder>(
        title: 'Sistema',
        subtitle: 'Usuários & permissões',
        icon: Icons.manage_accounts_outlined,
        color: Colors.teal.shade700,
        value: (_) => const SettingsSystemPage(),
      ),
      BasicCardItem<WidgetBuilder>(
        title: 'Migrações & Limpeza',
        subtitle: 'Migrar docs, apagar coleções & campos',
        icon: Icons.sync_alt_outlined,
        color: Colors.deepOrange.shade700,
        value: (_) => const SettingsTopicMigracoesPage(),
      ),
    ];

    final backgroundColor = isDark ? const Color(0xFF121212) : Colors.white;
    final titleColor = isDark ? Colors.white : Colors.blueGrey.shade900;
    final subtitleColor = isDark
        ? Colors.white.withValues(alpha: 0.72)
        : Colors.blueGrey.shade700;

    return Scaffold(
      backgroundColor: backgroundColor,
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
        child: LayoutBuilder(
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
                final card = cards[i];

                return BasicCard(
                  isDark: isDark,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: card.value),
                  ),
                  borderRadius: 16,
                  padding: const EdgeInsets.all(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                      card.color.withValues(alpha: 0.22),
                      card.color.withValues(alpha: 0.10),
                    ]
                        : [
                      card.color.withValues(alpha: 0.18),
                      card.color.withValues(alpha: 0.08),
                    ],
                  ),
                  borderColor:
                  card.color.withValues(alpha: isDark ? 0.22 : 0.18),
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: Icon(
                          card.icon,
                          size: 42,
                          color: card.color.withValues(
                            alpha: isDark ? 0.85 : 0.78,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              card.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: titleColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              card.subtitle,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                color: subtitleColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}