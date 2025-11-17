import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_utils/formats/mask_class.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';

import 'package:siged/_blocs/process/hiring/7Dotacao/dotacao_controller.dart';

class SectionReserva extends StatelessWidget {
  final DotacaoController controller;

  const SectionReserva({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final c = controller;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('4) Reserva Orçamentária / Planejamento'),
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
                    controller: c.reservaNumeroCtrl,
                    labelText: 'Nº da Reserva',
                    enabled: c.isEditable,
                  ),
                ),
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: c.reservaDataCtrl,
                    labelText: 'Data da Reserva',
                    hintText: 'dd/mm/aaaa',
                    enabled: c.isEditable,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(8),
                      TextInputMask(mask: '99/99/9999'),
                    ],
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: c.reservaValorCtrl,
                    labelText: 'Valor Reservado (R\$)',
                    enabled: c.isEditable,
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: c.reservaObservacoesCtrl,
                    labelText: 'Observações da reserva',
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
