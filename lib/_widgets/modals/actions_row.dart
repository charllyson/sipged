import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:siged/_blocs/sectors/operation/road/schedule_modal_controller.dart';
import 'package:siged/_widgets/modals/type.dart'; // ⬅️ precisa do ScheduleType

class ScheduleActionsRow extends StatelessWidget {
  final String confirmLabel;   // ex.: 'Salvar'
  final IconData confirmIcon;  // ex.: Icons.done

  /// Tipo do cronograma (civil/rodoviário)
  final ScheduleType type;

  /// Callback para apagar a área (apenas civil mostra o botão quando não for null)
  final VoidCallback? onDelete;

  /// Callback para fechar SOMENTE o bottom sheet (injetado pelo showModalBottomSheet)
  final VoidCallback? onClose;

  const ScheduleActionsRow({
    super.key,
    required this.type,
    this.confirmLabel = 'Salvar',
    this.confirmIcon = Icons.done,
    this.onDelete,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ScheduleModalController>();
    final disabled = c.picking || c.saving;
    final isCivil = type == ScheduleType.civil;

    // Se for CIVIL E temos onDelete -> mostra "Apagar área" (vermelho)
    // Caso contrário -> mostra "Cancelar"
    final showDelete = isCivil && onDelete != null;

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
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Apagar área?'),
                        content: const Text(
                          'Esta ação removerá a área e suas fotos anexadas (se houver). Deseja continuar?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx, rootNavigator: false).pop(false),
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(ctx, rootNavigator: false).pop(true),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text('Apagar'),
                          ),
                        ],
                      ),
                    );
                    if (ok == true) onDelete!();
                  },
                  child: const Text('Apagar área', style: TextStyle(color: Colors.red)),
                )
                    : OutlinedButton(
                  onPressed: disabled
                      ? null
                      : () {
                    // fecha SOMENTE o sheet
                    if (onClose != null) {
                      onClose!();
                    } else {
                      Navigator.of(context, rootNavigator: false).maybePop();
                    }
                  },
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: disabled
                      ? null
                      : () async {
                    // salva SEM dar pop aqui; quem fecha é o onClose
                    await c.save(
                      context,
                      onClose: onClose ?? () => Navigator.of(context, rootNavigator: false).maybePop(),
                    );
                  },
                  icon: Icon(confirmIcon),
                  label: Text(confirmLabel),
                ),
              ),
            ],
          ),
          if (c.saving)
            const Padding(
              padding: EdgeInsets.only(top: 14),
              child: LinearProgressIndicator(minHeight: 2),
            ),
        ],
      ),
    );
  }
}
