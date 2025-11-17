import 'package:flutter/material.dart';
import 'package:siged/_blocs/process/hiring/0Stages/hiring_data.dart';

import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';

import 'package:siged/_blocs/process/hiring/7Dotacao/dotacao_controller.dart';

class SectionVinculacaoProgramatica extends StatelessWidget {
  final DotacaoController controller;

  const SectionVinculacaoProgramatica({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final c = controller;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('2) Vinculação Programática'),
        LayoutBuilder(
          builder: (context, constraints) {
            final w6 = inputW6(context, constraints);

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w6,
                  child: DropDownButtonChange(
                    enabled: c.isEditable,
                    labelText: 'Fonte de Recurso',
                    controller: c.fonteRecursoCtrl,
                    items: HiringData.fontsRecuros,
                    onChanged: (v) => c.fonteRecursoCtrl.text = v ?? '',
                  ),
                ),
                SizedBox(
                  width: w6,
                  child: CustomTextField(
                    controller: c.unidadeOrcCtrl,
                    labelText: 'Unidade Orçamentária (UO)',
                    enabled: c.isEditable,
                  ),
                ),
                SizedBox(
                  width: w6,
                  child: CustomTextField(
                    controller: c.ugCtrl,
                    labelText: 'UG (Unidade Gestora)',
                    enabled: c.isEditable,
                  ),
                ),
                SizedBox(
                  width: w6,
                  child: CustomTextField(
                    controller: c.programaCtrl,
                    labelText: 'Programa',
                    enabled: c.isEditable,
                  ),
                ),
                SizedBox(
                  width: w6,
                  child: CustomTextField(
                    controller: c.ptresCtrl,
                    labelText: 'PTRES/PI/OB (quando aplicável)',
                    enabled: c.isEditable,
                  ),
                ),
                SizedBox(
                  width: w6,
                  child: CustomTextField(
                    controller: c.planoOrcCtrl,
                    labelText: 'Plano Orçamentário (PO)',
                    enabled: c.isEditable,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
