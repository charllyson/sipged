import 'package:flutter/material.dart';

import 'package:sipged/_widgets/loading/loading_tree_dots.dart';
 import 'package:sipged/screens/common/login/sign_up/sign_up_data.dart';

class SignUpActions extends StatelessWidget {
  const SignUpActions({
    super.key,
    required this.loading,
    required this.mode,
    required this.onCancel,
    required this.onSubmit,
  });

  final bool loading;
  final SignUpMode mode;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  bool get isAdminCreateUser => mode == SignUpMode.adminCreateUser;

  bool get isEditUser => mode == SignUpMode.editUser;

  String get submitLabel {
    if (loading) {
      if (isEditUser) return 'Salvando...';
      if (isAdminCreateUser) return 'Criando...';
      return 'Cadastrando...';
    }

    if (isEditUser) return 'Salvar alterações';
    if (isAdminCreateUser) return 'Criar usuário';
    return 'Cadastrar';
  }

  IconData get submitIcon {
    if (isEditUser) return Icons.save_rounded;
    return Icons.person_add_alt_1_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 470;

        final cancelButton = OutlinedButton.icon(
          onPressed: loading ? null : onCancel,
          icon: const Icon(Icons.close_rounded),
          label: const Text('Cancelar'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF344054),
            side: const BorderSide(
              color: Color(0xFFD0D5DD),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 15,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
        );

        final submitButton = ElevatedButton.icon(
          onPressed: loading ? null : onSubmit,
          icon: loading
              ? const LoadingTreeDots(
            size: 18,
            strokeWidth: 2,
            color: Colors.white,
            centered: false,
          )
              : Icon(submitIcon),
          label: Text(submitLabel),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFF93C5FD),
            disabledForegroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 15,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w900,
            ),
          ),
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              submitButton,
              const SizedBox(height: 10),
              cancelButton,
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            cancelButton,
            const SizedBox(width: 10),
            submitButton,
          ],
        );
      },
    );
  }
}