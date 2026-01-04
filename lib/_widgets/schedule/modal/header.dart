// lib/_widgets/modals/header.dart
import 'package:flutter/material.dart';

import 'package:siged/_widgets/schedule/modal/type.dart';
// ScheduleApplyTarget normalmente vem do mesmo arquivo de tipos
// (ajuste o import se estiver em outro lugar)

class ScheduleHeaderEditable extends StatelessWidget {
  final ScheduleType type;
  final String name;
  final List<ScheduleApplyTarget> targets;

  const ScheduleHeaderEditable({
    super.key,
    required this.type,
    required this.name,
    required this.targets,
  });

  @override
  Widget build(BuildContext context) {
    // Título: pedido especial p/ rodoviário
    final titleText = (type == ScheduleType.rodoviario)
        ? 'Registrar ocorrência nas estacas:'
        : type.titlePrefix;

    // Subtítulo / “nome” exibido
    String subtitle = name.trim();
    if (subtitle.isEmpty) {
      if (type == ScheduleType.rodoviario && targets.isNotEmpty) {
        final t = targets.first;
        subtitle = 'E: ${t.estaca}';
      } else {
        subtitle = '—';
      }
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Linha do título
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
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
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
