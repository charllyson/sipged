import 'package:flutter/material.dart';
import 'package:siged/_blocs/process/hiring/0Stages/hiring_data.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart'
    show DropDownButtonChange;
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';
import 'package:siged/_blocs/process/hiring/2Etp/etp_controller.dart';

class SectionAlternativasSolucao extends StatelessWidget
    with FormValidationMixin {
  final EtpController controller;
  SectionAlternativasSolucao({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w3 = inputW3(context, constraints);
        final w1 = inputW1(context, constraints);


        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle('3) Alternativas e solução recomendada'),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w3,
                  child: DropDownButtonChange(
                    enabled: c.isEditable,
                    labelText: 'Solução recomendada',
                    controller: c.etpSolucaoRecomendadaCtrl,
                    items: HiringData.tiposDeContratacao,
                    validator: validateRequired,
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: DropDownButtonChange(
                    enabled: c.isEditable,
                    labelText: 'Complexidade',
                    controller: c.etpComplexidadeCtrl,
                    items: HiringData.complexibilidade,
                    validator: validateRequired,
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: DropDownButtonChange(
                    enabled: c.isEditable,
                    labelText: 'Risco preliminar',
                    controller: c.etpNivelRiscoCtrl,
                    items: HiringData.complexibilidade,
                    validator: validateRequired,
                  ),
                ),
                SizedBox(
                  width: w1,
                  child: CustomTextField(
                    controller: c.etpJustificativaSolucaoCtrl,
                    enabled: c.isEditable,
                    labelText: 'Justificativa da solução',
                    validator: validateRequired,
                    maxLines: 3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}
