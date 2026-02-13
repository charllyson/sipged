// lib/_widgets/schedule/modal/schedule_actions_row.dart
import 'package:flutter/material.dart';

import 'package:sipged/_widgets/schedule/modal/type.dart'; // ⬅️ ScheduleType
import 'package:sipged/_widgets/windows/show_window_dialog.dart';

/// Linha de ações do modal de cronograma.
///
/// Agora é um widget "burro":
/// - NÃO depende mais de ScheduleModalController / Provider.
/// - Recebe flags (picking/saving) e callbacks (onConfirm/onDelete/onClose).
class ScheduleActionsRow extends StatelessWidget {
  final String confirmLabel;
  final IconData confirmIcon;

  /// Tipo do cronograma (civil/rodoviário)
  final ScheduleType type;

  /// Callback para apagar a área (apenas civil mostra o botão quando não for null)
  final VoidCallback? onDelete;

  /// Callback para fechar o modal/bottom sheet
  final VoidCallback? onClose;

  /// Callback para confirmar/salvar.
  ///
  /// Recebe o [BuildContext] e um callback [defaultClose] que fecha o sheet.
  /// Isso permite reusar a mesma lógica em diferentes telas.
  final Future<void> Function(
      BuildContext context,
      VoidCallback defaultClose,
      )? onConfirm;

  /// Flags de estado externo (ex: tirando foto, salvando no Firestore)
  final bool picking;
  final bool saving;

  const ScheduleActionsRow({
    super.key,
    required this.type,
    this.confirmLabel = 'Salvar',
    this.confirmIcon = Icons.done,
    this.onDelete,
    this.onClose,
    this.onConfirm,
    this.picking = false,
    this.saving = false,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = picking || saving;
    final isCivil = type == ScheduleType.civil;

    final showDelete = isCivil && onDelete != null;

    // callback padrão para fechar o sheet se onClose não for passado
    VoidCallback defaultClose = onClose ??
            () {
          Navigator.of(
            context,
            rootNavigator: false,
          ).maybePop();
        };

    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: showDelete
                    ? OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                  onPressed: disabled
                      ? null
                      : () async {
                    final ok = await confirmDialog(
                      context,
                      'Esta ação removerá a área e suas fotos anexadas (se houver).\n'
                          'Deseja continuar?',
                    );
                    if (ok && onDelete != null) {
                      onDelete!();
                    }
                  },
                  child: const Text(
                    'Apagar área',
                    style: TextStyle(color: Colors.red),
                  ),
                )
                    : OutlinedButton(
                  onPressed: disabled ? null : defaultClose,
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: (disabled || onConfirm == null)
                      ? null
                      : () async {
                    // salva SEM dar pop direto; quem fecha é o onConfirm
                    await onConfirm!(
                      context,
                      defaultClose,
                    );
                  },
                  icon: Icon(confirmIcon),
                  label: Text(confirmLabel),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
