import 'package:flutter/material.dart';
 import 'package:sipged/screens/common/login/sign_up/sign_up_data.dart';

class SignUpTopBanner extends StatelessWidget {
  const SignUpTopBanner({
    super.key,
    required this.mode,
  });

  final SignUpMode mode;

  bool get isAdminCreateUser => mode == SignUpMode.adminCreateUser;

  bool get isEditUser => mode == SignUpMode.editUser;

  @override
  Widget build(BuildContext context) {
    final title = isEditUser
        ? 'Editar usuário'
        : isAdminCreateUser
        ? 'Novo usuário'
        : 'Criar conta';

    final subtitle = isEditUser
        ? 'Atualização de dados e status do usuário'
        : isAdminCreateUser
        ? 'Cadastro administrativo de usuários do SIPGED'
        : 'Cadastro de acesso ao SIPGED';

    final icon = isEditUser
        ? Icons.manage_accounts_rounded
        : Icons.person_add_alt_1_rounded;

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 18, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1D4ED8),
            Color(0xFF7C3AED),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(19),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.20),
              ),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFFDDE7FF),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}