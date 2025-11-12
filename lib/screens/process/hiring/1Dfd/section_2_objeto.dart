import 'package:flutter/material.dart';
import 'package:siged/_blocs/process/hiring/1Dfd/dfd_controller.dart';
import 'package:siged/_blocs/process/hiring/1Dfd/dfd_data.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/dropdown_yes_no.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';

class SectionObjeto extends StatelessWidget with FormValidationMixin {
  final DfdController controller;
  SectionObjeto({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('2) Objeto / Escopo'),
        LayoutBuilder(builder: (context, inner) {
          final w3 = inputWidth(context: context, inner: inner, perLine: 3, minItemWidth: 260);
          final w1 = inputWidth(context: context, inner: inner, perLine: 1, minItemWidth: 400);
          return Wrap(spacing: 12, runSpacing: 12, children: [
            // Tipo de contratação (existente)
            SizedBox(
              width: w3,
              child: DropDownButtonChange(
                enabled: controller.isEditable,
                labelText: 'Tipo de contratação',
                controller: TextEditingController(text: controller.dfdTipoContratacaoValue),
                items: DfdData.tiposDeContratacao,
                onChanged: (v) => controller.dfdTipoContratacaoValue = v ?? '',
                validator: validateRequired,
              ),
            ),
            // Modalidade estimada (existente)
            SizedBox(
              width: w3,
              child: DropDownButtonChange(
                enabled: controller.isEditable,
                labelText: 'Modalidade estimada',
                controller: TextEditingController(text: controller.dfdModalidadeEstimativaValue),
                items: DfdData.modalidadeDeContratacao,
                onChanged: (v) => controller.dfdModalidadeEstimativaValue = v ?? '',
                validator: validateRequired,
              ),
            ),
            // Regime de execução (existente)
            SizedBox(
              width: w3,
              child: DropDownButtonChange(
                enabled: controller.isEditable,
                labelText: 'Regime de execução (opcional)',
                controller: TextEditingController(text: controller.dfdRegimeExecucaoValue),
                items: DfdData.regimeDeExecucao,
                onChanged: (v) => controller.dfdRegimeExecucaoValue = v ?? '',
              ),
            ),
            // (NOVO) Tipo de obra
            SizedBox(
              width: w3,
              child: DropDownButtonChange(
                enabled: controller.isEditable,
                labelText: 'Tipo de obra',
                controller: TextEditingController(text: controller.dfdTipoObraValue),
                items: DfdData.workTypes,
                onChanged: (v) => controller.dfdTipoObraValue = v ?? '',
                validator: validateRequired,
              ),
            ),
            // (ajuste de rótulo) Resumo do objeto
            SizedBox(
              width: w1,
              child: CustomTextField(
                controller: controller.dfdDescricaoObjetoCtrl,
                enabled: controller.isEditable,
                validator: validateRequired,
                labelText: 'Resumo do objeto',
                maxLines: 3,
              ),
            ),
            // Justificativa (inalterado)
            SizedBox(
              width: w1,
              child: CustomTextField(
                controller: controller.dfdJustificativaCtrl,
                enabled: controller.isEditable,
                validator: validateRequired,
                labelText: 'Justificativa da contratação (problema/objetivo)',
                maxLines: 4,
              ),
            ),
          ]);
        }),
        const SizedBox(height: 16),
      ],
    );
  }
}
