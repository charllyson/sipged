import 'package:flutter/material.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_blocs/process/hiring/7Dotacao/dotacao_controller.dart';

class SectionVinculacaoProgramatica extends StatelessWidget {
  final DotacaoController controller;
  const SectionVinculacaoProgramatica({super.key, required this.controller});

  double _w(BuildContext ctx, {int itemsPerLine = 4}) => responsiveInputWidth(
    context: ctx, itemsPerLine: itemsPerLine, spacing: 12, margin: 12, extraPadding: 24,
  );

  @override
  Widget build(BuildContext context) {
    final c = controller;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle('2) Vinculação Programática'),
        Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(
            width: _w(context),
            child: CustomTextField(
              controller: c.unidadeOrcCtrl,
              labelText: 'Unidade Orçamentária (UO)',
              enabled: c.isEditable,
            ),
          ),
          SizedBox(
            width: _w(context),
            child: CustomTextField(
              controller: c.ugCtrl,
              labelText: 'UG (Unidade Gestora)',
              enabled: c.isEditable,
            ),
          ),
          SizedBox(width: _w(context), child: CustomTextField(controller: c.programaCtrl, labelText: 'Programa', enabled: c.isEditable)),
          SizedBox(width: _w(context), child: CustomTextField(controller: c.acaoCtrl, labelText: 'Ação', enabled: c.isEditable)),
          SizedBox(width: _w(context), child: CustomTextField(controller: c.ptresCtrl, labelText: 'PTRES/PI/OB (quando aplicável)', enabled: c.isEditable)),
          SizedBox(width: _w(context), child: CustomTextField(controller: c.planoOrcCtrl, labelText: 'Plano Orçamentário (PO)', enabled: c.isEditable)),
          SizedBox(
            width: _w(context),
            child: DropDownButtonChange(
              enabled: c.isEditable,
              labelText: 'Fonte de Recurso',
              controller: c.fonteRecursoCtrl,
              items: const ['0100 - Tesouro', '0120 - Convênios', '0150 - Vinculados', 'Outros'],
              onChanged: (v) => c.fonteRecursoCtrl.text = v ?? '',
            ),
          ),
        ]),
        const SizedBox(height: 16),
      ],
    );
  }
}
