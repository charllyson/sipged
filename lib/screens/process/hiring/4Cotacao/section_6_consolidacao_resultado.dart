import 'package:flutter/material.dart';
import 'package:siged/_blocs/process/hiring/0Stages/hiring_data.dart';

import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';

import 'package:siged/_blocs/process/hiring/4Cotacao/cotacao_controller.dart';

class SectionConsolidacaoResultado extends StatelessWidget {
  final CotacaoController controller;
  const SectionConsolidacaoResultado({super.key, required this.controller});

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
            const SectionTitle('5) Consolidação e Resultado'),
            Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: w4,
                    child: DropDownButtonChange(
                      enabled: c.isEditable,
                      labelText: 'Critério de consolidação',
                      controller: c.ctCriterioConsolidacaoCtrl,
                      items: HiringData.criterioConsolidacao,
                      onChanged: (v) =>
                      c.ctCriterioConsolidacaoCtrl.text = v ?? '',
                    ),
                  ),
                  SizedBox(
                    width: w4,
                    child: CustomTextField(
                      controller: c.ctValorConsolidadoCtrl,
                      labelText: 'Valor consolidado (R\$)',
                      enabled: c.isEditable,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  SizedBox(
                    width: w1,
                    child: CustomTextField(
                      controller: c.ctObservacoesCtrl,
                      labelText: 'Observações / exclusões / premissas',
                      maxLines: 3,
                      enabled: c.isEditable,
                    ),
                  ),
                ]),
          ],
        );
      },
    );
  }
}
