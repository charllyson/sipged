import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/_widgets/buttons/circle_button_change.dart';
import 'package:sipged/_widgets/menu/upBar/up_bar.dart';
import 'package:sipged/screens/common/profile/widgets/modern_card.dart';

class LoginSecuritySettingsPage extends StatelessWidget {
  const LoginSecuritySettingsPage({super.key});

  Future<void> _sendPasswordReset(BuildContext context) async {
    final email = FirebaseAuth.instance.currentUser?.email;

    if (email == null || email.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('E-mail do usuário não encontrado.'),
        ),
      );
      return;
    }

    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Link de redefinição enviado para $email.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: UpBar(
        leading: const Padding(
          padding: EdgeInsets.only(left: 12),
          child: CircleButtonChange(),
        ),
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
                      const _SecurityHeader(),
                      const SizedBox(height: 20),
                      ListTile(
                        leading: Icon(
                          Icons.email_rounded,
                          color: Colors.green.shade700,
                        ),
                        title: const Text('E-mail de acesso'),
                        subtitle: Text(authUser?.email ?? 'Não informado'),
                      ),
                      const Divider(height: 24),
                      ListTile(
                        leading: Icon(
                          Icons.password_rounded,
                          color: Colors.green.shade700,
                        ),
                        title: const Text('Alterar senha'),
                        subtitle: const Text(
                          'Enviar link de redefinição para o e-mail cadastrado.',
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => _sendPasswordReset(context),
                      ),
                      const SizedBox(height: 10),
                      ListTile(
                        leading: Icon(
                          Icons.devices_rounded,
                          color: Colors.green.shade700,
                        ),
                        title: const Text('Sessões e dispositivos'),
                        subtitle: const Text(
                          'Controle futuro de acessos ativos à conta.',
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
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

class _SecurityHeader extends StatelessWidget {
  const _SecurityHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(Icons.lock_rounded, color: Colors.green.shade700, size: 32),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Login e segurança',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}