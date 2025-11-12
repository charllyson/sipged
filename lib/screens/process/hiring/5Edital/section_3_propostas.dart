import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart' show DropDownButtonChange;
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_utils/formats/mask_class.dart';

import 'package:siged/_blocs/process/hiring/5Edital/edital_julgamento_controller.dart';

class SectionPropostas extends StatelessWidget {
  final EditalJulgamentoController controller;
  final void Function(int index)? onDefinirVencedorEIr;
  const SectionPropostas({super.key, required this.controller, this.onDefinirVencedorEIr});

  double _w(BuildContext ctx, {int itemsPerLine = 4}) =>
      responsiveInputWidth(context: ctx, itemsPerLine: itemsPerLine, spacing: 12, margin: 12, extraPadding: 24);

  @override
  Widget build(BuildContext context) {
    final c = controller;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SectionTitle('Propostas recebidas'),
            OutlinedButton.icon(
              onPressed: c.isEditable ? c.addProposta : null,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar proposta'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...List.generate(c.propostas.length, (i) {
          final p = c.propostas[i];
          final cs = Theme.of(context).colorScheme;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: cs.outlineVariant),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text('Proposta ${i + 1}',
                        style: TextStyle(fontWeight: FontWeight.w600, color: cs.primary)),
                  ),
                  if (c.isEditable) ...[
                    TextButton.icon(
                      onPressed: onDefinirVencedorEIr == null ? null : () => onDefinirVencedorEIr!(i),
                      icon: const Icon(Icons.emoji_events_outlined),
                      label: const Text('Definir vencedor provisório'),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => c.removeProposta(i),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Remover'),
                      style: TextButton.styleFrom(foregroundColor: cs.error),
                    ),
                  ],
                ]),
                const SizedBox(height: 8),
                Wrap(spacing: 12, runSpacing: 12, children: [
                  SizedBox(
                    width: _w(context),
                    child: CustomTextField(
                      controller: p.licitanteCtrl,
                      labelText: 'Licitante',
                      enabled: c.isEditable,
                    ),
                  ),
                  SizedBox(
                    width: _w(context),
                    child: CustomTextField(
                      controller: p.cnpjCtrl,
                      labelText: 'CNPJ',
                      enabled: c.isEditable,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(14),
                        TextInputMask(mask: '99.999.999/9999-99'),
                      ],
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  SizedBox(
                    width: _w(context),
                    child: CustomTextField(
                      controller: p.valorCtrl,
                      labelText: 'Valor (R\$)',
                      enabled: c.isEditable,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  SizedBox(
                    width: _w(context),
                    child: DropDownButtonChange(
                      enabled: c.isEditable,
                      labelText: 'Status',
                      controller: p.statusCtrl,
                      items: const ['classificada','desclassificada'],
                      onChanged: (v) => p.statusCtrl.text = v ?? '',
                    ),
                  ),
                  SizedBox(
                    width: _w(context, itemsPerLine: 1),
                    child: CustomTextField(
                      controller: p.motivoDesclassCtrl,
                      labelText: 'Motivo da desclassificação',
                      enabled: c.isEditable,
                      maxLines: 2,
                    ),
                  ),
                  SizedBox(
                    width: _w(context, itemsPerLine: 1),
                    child: CustomTextField(
                      controller: p.linkCtrl,
                      labelText: 'Link/arquivo da proposta',
                      enabled: c.isEditable,
                    ),
                  ),
                ]),
              ],
            ),
          );
        }),
      ],
    );
  }
}
