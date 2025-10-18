// lib/_widgets/modals/header.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_blocs/sectors/operation/road/schedule_modal_controller.dart';
import 'package:siged/_widgets/modals/type.dart';

class ScheduleHeaderEditable extends StatelessWidget {
  final ScheduleType type;
  const ScheduleHeaderEditable({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ScheduleModalController>();

    // Título: pedido especial p/ rodoviário
    final titleText = (type == ScheduleType.rodoviario)
        ? 'Editando estaca'
        : type.titlePrefix;

    // Se quiser um hint automático quando não vier nome:
    String? hint;
    if (c.nameCtrl.text.trim().isEmpty) {
      if (type == ScheduleType.rodoviario) {
        // Tenta montar um hint a partir do primeiro alvo
        if (c.targets.isNotEmpty) {
          final t = c.targets.first;
          hint = 'E: ${t.estaca}';
        } else {
          hint = 'E: —';
        }
      } else {
        hint = 'Digite o nome…';
      }
    }

    // Bloqueia edição para rodoviário (readOnly) — civil continua editável
    final readOnly = (type == ScheduleType.rodoviario);
    // Mantém enable/disable por estados de picking/saving
    final enabled = !(c.picking || c.saving || readOnly);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Linha do título + botão fechar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      titleText,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      onPressed: (c.picking || c.saving) ? null : () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      tooltip: 'Fechar',
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Campo de nome (bloqueado no rodoviário)
                CustomTextField(
                  controller: c.nameCtrl,
                  enabled: enabled,
                  hintText: hint,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
