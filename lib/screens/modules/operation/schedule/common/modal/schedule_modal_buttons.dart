// lib/screens/modules/operation/schedule/common/modal/schedule_modal_buttons.dart

import 'package:flutter/material.dart';

import 'package:sipged/screens/modules/operation/schedule/common/schedule_type.dart';
import 'package:sipged/_widgets/dialog/show_dialogs/show_window_dialog.dart';

class ScheduleModalButtons extends StatelessWidget {
  final String confirmLabel;
  final IconData confirmIcon;

  final ScheduleType type;

  final VoidCallback? onDelete;

  /// Fecha visualmente o modal.
  ///
  /// Importante:
  /// este callback NÃO deve salvar dados nem disparar notificação.
  final VoidCallback? onClose;

  /// Confirma/salva.
  ///
  /// O fechamento automático deve acontecer dentro do onConfirm
  /// apenas depois do salvamento bem-sucedido.
  final Future<void> Function(
      BuildContext context,
      VoidCallback closeOnly,
      )? onConfirm;

  final bool picking;
  final bool saving;

  const ScheduleModalButtons({
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

    void closeOnly() {
      if (onClose != null) {
        onClose!();
        return;
      }

      Navigator.of(
        context,
        rootNavigator: false,
      ).maybePop();
    }

    return Padding(
      padding: const EdgeInsets.only(
        left: 12,
        right: 12,
        bottom: 20,
      ),
      child: Row(
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
              onPressed: disabled ? null : closeOnly,
              child: const Text('Cancelar'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FilledButton.icon(
              onPressed: disabled || onConfirm == null
                  ? null
                  : () async {
                await onConfirm!(
                  context,
                  closeOnly,
                );
              },
              icon: saving
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
                  : Icon(confirmIcon),
              label: Text(saving ? 'Salvando...' : confirmLabel),
            ),
          ),
        ],
      ),
    );
  }
}