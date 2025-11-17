import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:siged/_blocs/process/hiring/0Stages/hiring_data.dart';
import 'package:siged/_widgets/input/custom_date_field.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart'
    show DropDownButtonChange;
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_utils/formats/mask_class.dart';
import 'package:siged/_blocs/process/hiring/9Juridico/parecer_juridico_controller.dart';

class SectionConclusao extends StatelessWidget {
  final ParecerJuridicoController controller;

  const SectionConclusao({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final c = controller;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('4) Conclusão do Parecer'),
        LayoutBuilder(
          builder: (context, constraints) {
            final w4 = inputW4(context, constraints);
            final w1 = inputW1(context, constraints);

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w4,
                  child: DropDownButtonChange(
                    enabled: c.isEditable,
                    labelText: 'Conclusão',
                    controller: c.pjConclusaoCtrl,
                    items: HiringData.parecerConclusao,
                    onChanged: (v) => c.pjConclusaoCtrl.text = v ?? '',
                  ),
                ),
                SizedBox(
                  width: w4,
                  child: CustomDateField(
                    controller: c.pjDataAssinaturaCtrl,
                    labelText: 'Data da assinatura do parecer',
                    enabled: c.isEditable,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(8),
                      TextInputMask(mask: '99/99/9999'),
                    ],
                  ),
                ),
                SizedBox(
                  width: w1,
                  child: CustomTextField(
                    controller: c.pjRecomendacoesCtrl,
                    labelText: 'Recomendações e/ou condicionantes',
                    maxLines: 3,
                    enabled: c.isEditable,
                    textAlignVertical: TextAlignVertical.top,
                  ),
                ),
                SizedBox(
                  width: w1,
                  child: CustomTextField(
                    controller: c.pjAjustesObrigatoriosCtrl,
                    labelText: 'Ajustes obrigatórios na minuta/edital',
                    maxLines: 3,
                    enabled: c.isEditable,
                    textAlignVertical: TextAlignVertical.top,
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
