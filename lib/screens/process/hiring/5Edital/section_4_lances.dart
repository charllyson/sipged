import 'package:flutter/material.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';

import 'package:siged/_blocs/process/hiring/5Edital/edital_julgamento_controller.dart';

class SectionLances extends StatelessWidget {
  final EditalJulgamentoController controller;
  const SectionLances({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SectionTitle('Lances / Negociação (se aplicável)'),
            OutlinedButton.icon(
              onPressed: c.isEditable ? c.addLance : null,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar lance'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...List.generate(c.lances.length, (i) {
          final l = c.lances[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: cs.outlineVariant),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              Expanded(
                flex: 3,
                child: CustomTextField(
                  controller: l.licitanteCtrl,
                  labelText: 'Licitante',
                  enabled: c.isEditable,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: CustomTextField(
                  controller: l.valorCtrl,
                  labelText: 'Valor do lance (R\$)',
                  enabled: c.isEditable,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: CustomTextField(
                  controller: l.dataHoraCtrl,
                  labelText: 'Data/Hora',
                  hintText: 'dd/mm/aaaa hh:mm',
                  enabled: c.isEditable,
                ),
              ),
              const SizedBox(width: 12),
              if (c.isEditable)
                IconButton(
                  onPressed: () => c.removeLance(i),
                  icon: const Icon(Icons.delete_outline),
                  color: cs.error,
                  tooltip: 'Remover lance',
                ),
            ]),
          );
        }),
      ],
    );
  }
}
