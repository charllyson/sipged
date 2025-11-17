import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:siged/_blocs/process/hiring/0Stages/hiring_data.dart';
import 'package:siged/_blocs/process/hiring/1Dfd/dfd_data.dart';

import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';
import 'package:siged/_blocs/process/hiring/3Tr/tr_controller.dart';

class SectionObjetoFundamentacao extends StatelessWidget
    with FormValidationMixin {
  SectionObjetoFundamentacao({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<TrController>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final w3 = inputW3(context, constraints);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle('1) Objeto e Fundamentação'),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: w3,
                        child: DropDownButtonChange(
                          enabled: c.isEditable,
                          labelText: 'Tipo de contratação',
                          controller: c.trTipoContratacaoCtrl,
                          items: HiringData.tiposDeContratacao,
                          onChanged: (v) => c.trTipoContratacaoCtrl.text = v ?? '',
                          validator: validateRequired,
                        ),
                      ),
                      SizedBox(height: 12),
                      SizedBox(
                        width: w3,
                        child: DropDownButtonChange(
                          enabled: c.isEditable,
                          labelText: 'Regime de execução',
                          controller: c.trRegimeExecucaoCtrl,
                          items: HiringData.regimeDeExecucao,
                          onChanged: (v) => c.trRegimeExecucaoCtrl.text = v ?? '',
                          validator: validateRequired,
                        ),
                      ),
                      ]
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: c.trObjetoCtrl,
                    labelText: 'Objeto do Termo de Referência',
                    maxLines: 4,
                    enabled: c.isEditable,
                    validator: validateRequired,
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: c.trJustificativaCtrl,
                    labelText: 'Justificativa Técnica',
                    maxLines: 4,
                    enabled: c.isEditable,
                    validator: validateRequired,
                  ),
                ),

              ],
            ),
          ],
        );
      },
    );
  }
}
