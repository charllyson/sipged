import 'package:flutter/material.dart';

import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';

import 'package:siged/_blocs/process/hiring/0Stages/hiring_data.dart';
import 'package:siged/_blocs/process/hiring/6Habilitacao/habilitacao_controller.dart';

class SectionJuridicaTecnica extends StatelessWidget {
  final HabilitacaoController controller;
  const SectionJuridicaTecnica({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w4 = inputW4(context, constraints);
        final w1 = inputW1(context, constraints);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle('4) Habilitação Jurídica e Técnica'),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: c.docContratoSocialCtrl,
                    labelText: 'Contrato/Estatuto social (link/arquivo)',
                    enabled: c.isEditable,
                  ),
                ),
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: c.docCnpjCartaoCtrl,
                    labelText: 'Cartão CNPJ (link/arquivo)',
                    enabled: c.isEditable,
                  ),
                ),
                SizedBox(
                  width: w4,
                  child: DropDownButtonChange(
                    enabled: c.isEditable,
                    labelText: 'Atestados de capacidade técnica',
                    controller: c.docAtestadosStatusCtrl,
                    items: HiringData.docAtestados,
                    onChanged: (v) =>
                    c.docAtestadosStatusCtrl.text = v ?? '',
                  ),
                ),
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: c.docAtestadosLinksCtrl,
                    labelText: 'Links/observações dos atestados',
                    maxLines: 1,
                    enabled: c.isEditable,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}
