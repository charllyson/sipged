import 'package:flutter/material.dart';
import 'package:sipged/_blocs/system/user/user_data.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots.dart';
import 'package:sipged/screens/common/profile/widgets/modern_card.dart';
import 'package:sipged/screens/common/profile/widgets/name_field.dart';
import 'package:sipged/screens/common/profile/widgets/readonly_info_panel.dart';
import 'package:sipged/screens/common/profile/widgets/surname_field.dart';

class ProfileFormCard extends StatelessWidget {
  const ProfileFormCard({
    super.key,
    required this.user,
    required this.saving,
    required this.hasChanges,
    required this.formKey,
    required this.firstCtrl,
    required this.lastCtrl,
    required this.onSave,
  });

  final UserData user;
  final bool saving;
  final bool hasChanges;

  final GlobalKey<FormState> formKey;
  final TextEditingController firstCtrl;
  final TextEditingController lastCtrl;

  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ModernCard(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: formKey,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 680;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF3FF),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.account_circle_rounded,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Informações básicas',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Atualize seus dados principais de identificação.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.blueGrey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: NameField(controller: firstCtrl)),
                      const SizedBox(width: 14),
                      Expanded(child: SurnameField(controller: lastCtrl)),
                    ],
                  )
                else ...[
                  NameField(controller: firstCtrl),
                  const SizedBox(height: 14),
                  SurnameField(controller: lastCtrl),
                ],
                const SizedBox(height: 18),
                ReadonlyInfoPanel(user: user),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: AnimatedOpacity(
                        opacity: hasChanges ? 1 : .55,
                        duration: const Duration(milliseconds: 180),
                        child: Text(
                          hasChanges
                              ? 'Você possui alterações não salvas.'
                              : 'Nenhuma alteração pendente.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: hasChanges
                                ? Colors.orange.shade800
                                : Colors.blueGrey.shade500,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: saving || !hasChanges ? null : onSave,
                      icon: saving
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: LoadingTreeDots(
                          size: 20,
                          centered: false,
                        ),
                      )
                          : const Icon(Icons.save_rounded),
                      label: Text(
                        saving ? 'Salvando...' : 'Salvar alterações',
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
