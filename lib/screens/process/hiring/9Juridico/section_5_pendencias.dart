import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:siged/_widgets/input/custom_date_field.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_utils/formats/mask_class.dart';
import 'package:siged/_blocs/process/hiring/9Juridico/parecer_juridico_controller.dart';

class SectionPendencias extends StatelessWidget {
  final ParecerJuridicoController controller;

  const SectionPendencias({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final c = controller;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('5) Pendências e Prazos de Saneamento'),
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
                  child: CustomTextField(
                    controller: c.pendenciaDescricaoCtrl,
                    labelText: 'Pendências apontadas (resumo)',
                    maxLines: 2,
                    enabled: c.isEditable,
                    textAlignVertical: TextAlignVertical.top,
                  ),
                ),
                SizedBox(
                  width: w4,
                  child: CustomDateField(
                    controller: c.pendenciaPrazoCtrl,
                    labelText: 'Prazo para saneamento',
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
                    controller: c.pendenciaResponsavelCtrl,
                    labelText: 'Responsável pelo saneamento',
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
