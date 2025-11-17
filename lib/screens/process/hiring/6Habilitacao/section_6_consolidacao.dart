import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:siged/_blocs/process/hiring/0Stages/hiring_data.dart';
import 'package:siged/_widgets/input/custom_date_field.dart';

import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_utils/formats/mask_class.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';

import 'package:siged/_blocs/process/hiring/6Habilitacao/habilitacao_controller.dart';

class SectionConsolidacao extends StatelessWidget with FormValidationMixin {
  final HabilitacaoController controller;
  SectionConsolidacao({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w3 = inputW3(context, constraints);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle('6) Consolidação e Parecer do Gestor'),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w3,
                  child: DropDownButtonChange(
                    enabled: c.isEditable,
                    labelText: 'Situação da habilitação',
                    controller: c.dgSituacaoHabilitacaoCtrl,
                    items: HiringData.situacaoHabilitacao,
                    onChanged: (v) =>
                    c.dgSituacaoHabilitacaoCtrl.text = v ?? '',
                    validator: validateRequired,
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: CustomDateField(
                    controller: c.dgDataConclusaoCtrl,
                    labelText: 'Data da conclusão',
                    enabled: c.isEditable,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(8),
                      TextInputMask(mask: '99/99/9999'),
                    ],
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: c.dgParecerConclusivoCtrl,
                    labelText: 'Parecer conclusivo do gestor',
                    maxLines: 1,
                    enabled: c.isEditable,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }
}
