import 'package:flutter/material.dart';

import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/_widgets/buttons/circle_button_change.dart';
import 'package:sipged/_widgets/menu/upBar/up_bar.dart';
import 'package:sipged/screens/common/profile/widgets/modern_card.dart';

class LegalSettingsPage extends StatelessWidget {
  const LegalSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UpBar(
        leading: const Padding(
          padding: EdgeInsets.only(left: 12),
          child: CircleButtonChange(),
        ),
        photoMenu: const SizedBox.shrink(),
      ),
      body: Stack(
        children: [
          const BackgroundChange(),
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: ModernCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _LegalHeader(),
                      const SizedBox(height: 20),
                      _LegalTile(
                        icon: Icons.description_rounded,
                        title: 'Termos de uso',
                        subtitle:
                        'Regras gerais de utilização da plataforma SIPGED.',
                        onTap: () {},
                      ),
                      const SizedBox(height: 10),
                      _LegalTile(
                        icon: Icons.privacy_tip_rounded,
                        title: 'Política de privacidade',
                        subtitle:
                        'Tratamento de dados, privacidade e responsabilidades.',
                        onTap: () {},
                      ),
                      const SizedBox(height: 10),
                      _LegalTile(
                        icon: Icons.assignment_turned_in_rounded,
                        title: 'Consentimentos',
                        subtitle:
                        'Preferências e autorizações vinculadas à conta.',
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalHeader extends StatelessWidget {
  const _LegalHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(Icons.gavel_rounded, color: Colors.deepPurple.shade700, size: 32),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Jurídico',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _LegalTile extends StatelessWidget {
  const _LegalTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: Colors.deepPurple.shade700),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      tileColor: const Color(0xFFF7FAFF),
    );
  }
}