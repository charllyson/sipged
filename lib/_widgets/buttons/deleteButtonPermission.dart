import 'package:flutter/material.dart';
import 'package:sisgeo/_datas/user/user_data.dart';

class PermissionIconDeleteButton extends StatelessWidget {
  final bool Function(UserData userData) hasPermission;
  final Future<void> Function()? onConfirmed;
  final String tooltip;
  final UserData currentUser;
  final bool showConfirmDialog;
  final String confirmTitle;
  final String confirmContent;

  const PermissionIconDeleteButton({
    super.key,
    required this.hasPermission,
    required this.currentUser,
    required this.tooltip,
    this.onConfirmed,
    this.showConfirmDialog = false,
    this.confirmTitle = 'Confirmar ação',
    this.confirmContent = 'Deseja realmente continuar?',
  });

  @override
  Widget build(BuildContext context) {
    final allowed = hasPermission(currentUser);
    return Center(
      child: IconButton(
        tooltip: tooltip,
        icon: Icon(Icons.delete, color: allowed ? Colors.red : Colors.grey),
        onPressed: allowed
            ? () async {
          if (showConfirmDialog) {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: Text(confirmTitle),
                content: Text(confirmContent),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Confirmar'),
                  ),
                ],
              ),
            );
            if (confirm != true) return;
          }

          if (onConfirmed != null) await onConfirmed!();
        }
            : null,
      ),
    );
  }
}



