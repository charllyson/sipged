import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_blocs/process/hiring/3Tr/tr_controller.dart';

class SectionLocalPrazosCronograma extends StatelessWidget {
  const SectionLocalPrazosCronograma({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<TrController>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final w4 = inputW4(context, constraints);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle('3) Local, Prazos e Cronograma'),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: c.trLocalExecucaoCtrl,
                    labelText: 'Local de execução',
                    enabled: c.isEditable,
                  ),
                ),
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: c.trPrazoExecucaoDiasCtrl,
                    labelText: 'Prazo de execução (dias)',
                    enabled: c.isEditable,
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: c.trVigenciaMesesCtrl,
                    labelText: 'Vigência contratual (meses)',
                    enabled: c.isEditable,
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: c.trCronogramaFisicoCtrl,
                    labelText:
                    'Cronograma físico preliminar (marcos/etapas)',
                    maxLines: 1,
                    enabled: c.isEditable,
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
