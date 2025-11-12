// lib/screens/process/hiring/1Dfd/dfd_sections/section_5_riscos.dart
import 'package:flutter/material.dart';
import 'package:siged/_widgets/input/custom_date_field.dart';
import 'package:siged/_widgets/input/dropdown_yes_no.dart';

import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_blocs/process/hiring/1Dfd/dfd_controller.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart';

class SectionRiscos extends StatelessWidget with FormValidationMixin {
  final DfdController controller;
  SectionRiscos({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('5) Riscos e Impacto'),
        LayoutBuilder(builder: (context, inner) {
          final w2 = inputWidth(context: context, inner: inner, perLine: 2, minItemWidth: 360);
          final w4 = inputWidth(context: context, inner: inner, perLine: 4, minItemWidth: 220);
          return Wrap(spacing: 12, runSpacing: 12, children: [
            SizedBox(
              width: w2,
              child: CustomTextField(
                controller: controller.dfdRiscosPrincipaisCtrl,
                enabled: controller.isEditable,
                labelText: 'Riscos principais',
                maxLines: 3,
              ),
            ),
            SizedBox(
              width: w2,
              child: CustomTextField(
                controller: controller.dfdImpactoNaoContratarCtrl,
                enabled: controller.isEditable,
                labelText: 'Impacto se não contratar',
                maxLines: 3,
              ),
            ),
            SizedBox(
              width: w4,
              child: DropDownButtonChange(
                enabled: controller.isEditable,
                labelText: 'Prioridade',
                controller: TextEditingController(text: controller.dfdPrioridadeValue),
                items: const ['Baixa', 'Média', 'Alta', 'Crítica'],
                onChanged: (v) => controller.dfdPrioridadeValue = v ?? '',
                validator: validateRequired,
              ),
            ),
            SizedBox(
              width: w4,
              child: CustomDateField(
                controller: controller.dfdDataLimiteUrgenciaCtrl,
                enabled: controller.isEditable,
                labelText: 'Data limite/urgência (se houver)',
              ),
            ),
            SizedBox(
              width: w4,
              child: CustomTextField(
                controller: controller.dfdMotivacaoLegalCtrl,
                enabled: controller.isEditable,
                labelText: 'Motivação legal (ex.: decisão judicial)',
              ),
            ),
            SizedBox(
              width: w4,
              child: CustomTextField(
                controller: controller.dfdAmparoNormativoCtrl,
                enabled: controller.isEditable,
                labelText: 'Amparo normativo (lei/artigo)',
              ),
            ),
          ]);
        }),
        const SizedBox(height: 16),
      ],
    );
  }
}
