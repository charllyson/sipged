import 'package:flutter/material.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart' show DropDownButtonChange;
import 'package:siged/_widgets/layout/responsive_utils.dart';

import 'package:siged/_blocs/process/hiring/5Edital/edital_julgamento_controller.dart';

class SectionParecerRecursos extends StatelessWidget {
  final EditalJulgamentoController controller;
  const SectionParecerRecursos({super.key, required this.controller});

  double _w(BuildContext ctx, {int itemsPerLine = 4}) =>
      responsiveInputWidth(context: ctx, itemsPerLine: itemsPerLine, spacing: 12, margin: 12, extraPadding: 24);

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Julgamento / Ata / Recursos'),
        Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(
            width: _w(context, itemsPerLine: 1),
            child: CustomTextField(
              controller: c.sjParecerCtrl,
              labelText: 'Parecer/Justificativas do julgamento',
              maxLines: 3,
              enabled: c.isEditable,
            ),
          ),
          SizedBox(
            width: _w(context),
            child: DropDownButtonChange(
              enabled: c.isEditable,
              labelText: 'Critério aplicado (confirmação)',
              controller: c.sjCriterioAplicadoCtrl,
              items: const ['Menor preço válido', 'Técnica e preço', 'Maior desconto', 'Outro'],
              onChanged: (v) => c.sjCriterioAplicadoCtrl.text = v ?? '',
            ),
          ),
          SizedBox(
            width: _w(context),
            child: CustomTextField(
              controller: c.sjLinkAtaCtrl,
              labelText: 'Link da Ata da Sessão',
              enabled: c.isEditable,
            ),
          ),
          SizedBox(
            width: _w(context),
            child: DropDownButtonChange(
              enabled: c.isEditable,
              labelText: 'Houve recursos?',
              controller: c.sjRecursosHouveCtrl,
              items: const ['Não', 'Sim'],
              onChanged: (v) => c.sjRecursosHouveCtrl.text = v ?? '',
            ),
          ),
          SizedBox(
            width: _w(context, itemsPerLine: 1),
            child: CustomTextField(
              controller: c.sjDecisaoRecursosCtrl,
              labelText: 'Decisão dos recursos (se houver)',
              maxLines: 2,
              enabled: c.isEditable,
            ),
          ),
          SizedBox(
            width: _w(context, itemsPerLine: 1),
            child: CustomTextField(
              controller: c.sjLinksRecursosCtrl,
              labelText: 'Links dos recursos/decisões',
              maxLines: 2,
              enabled: c.isEditable,
            ),
          ),
        ]),
        const SizedBox(height: 16),
      ],
    );
  }
}
