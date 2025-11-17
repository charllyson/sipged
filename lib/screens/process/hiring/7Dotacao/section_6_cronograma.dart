import 'package:flutter/material.dart';

import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';

import 'package:siged/_blocs/process/hiring/7Dotacao/dotacao_controller.dart';

class SectionCronograma extends StatelessWidget {
  final DotacaoController controller;

  const SectionCronograma({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final c = controller;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('6) Cronograma de Desembolso (resumo)'),
        LayoutBuilder(
          builder: (context, constraints) {
            final w4 = inputW4(context, constraints);
            final w2 = inputW2(context, constraints);

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w4,
                  child: DropDownButtonChange(
                    enabled: c.isEditable,
                    labelText: 'Periodicidade',
                    controller: c.desembolsoPeriodicidadeCtrl,
                    items: const ['Mensal', 'Bimestral', 'Trimestral', 'Outro'],
                    onChanged: (v) =>
                    c.desembolsoPeriodicidadeCtrl.text = v ?? '',
                  ),
                ),
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: c.desembolsoMesesCtrl,
                    labelText: 'Meses/Marcos (ex.: Jan–Jun)',
                    enabled: c.isEditable,
                  ),
                ),
                SizedBox(
                  width: w2,
                  child: CustomTextField(
                    controller: c.desembolsoObservacoesCtrl,
                    labelText: 'Observações / condicionantes',
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
