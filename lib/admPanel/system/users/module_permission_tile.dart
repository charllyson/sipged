import 'package:flutter/material.dart';

import 'package:sipged/_blocs/system/permission/permission_data.dart' as perm;
import 'package:sipged/screens/common/login/sign_up/widgets/permission_check.dart';

import '../../../screens/common/login/sign_up/widgets/module_identity.dart';

class ModulePermissionTile extends StatelessWidget {
  const ModulePermissionTile({
    super.key,
    required this.moduleId,
    required this.title,
    required this.isSuper,
    required this.effective,
    required this.onChanged,
  });

  final String moduleId;
  final String title;
  final bool isSuper;
  final perm.PermissionSet effective;

  final Future<void> Function({
  required String action,
  required bool allow,
  }) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 820;

          final switches = Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              PermissionCheck(
                label: 'Ler',
                icon: Icons.visibility_rounded,
                value: isSuper ? true : effective.read,
                enabled: !isSuper,
                color: const Color(0xFF2563EB),
                onChanged: (v) => onChanged(action: 'read', allow: v),
              ),
              PermissionCheck(
                label: 'Criar',
                icon: Icons.add_circle_rounded,
                value: isSuper ? true : effective.create,
                enabled: !isSuper,
                color: const Color(0xFF059669),
                onChanged: (v) => onChanged(action: 'create', allow: v),
              ),
              PermissionCheck(
                label: 'Editar',
                icon: Icons.edit_rounded,
                value: isSuper ? true : effective.edit,
                enabled: !isSuper,
                color: const Color(0xFFF59E0B),
                onChanged: (v) => onChanged(action: 'edit', allow: v),
              ),
              PermissionCheck(
                label: 'Excluir',
                icon: Icons.delete_rounded,
                value: isSuper ? true : effective.delete,
                enabled: !isSuper,
                color: const Color(0xFFDC2626),
                onChanged: (v) => onChanged(action: 'delete', allow: v),
              ),
              PermissionCheck(
                label: 'Aprovar',
                icon: Icons.fact_check_rounded,
                value: isSuper ? true : effective.approve,
                enabled: !isSuper,
                color: const Color(0xFF7C3AED),
                onChanged: (v) => onChanged(action: 'approve', allow: v),
              ),
            ],
          );

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: ModuleIdentity(
                    title: title,
                    moduleId: moduleId,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: switches,
                  ),
                ),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ModuleIdentity(
                title: title,
                moduleId: moduleId,
              ),
              const SizedBox(height: 10),
              switches,
            ],
          );
        },
      ),
    );
  }
}