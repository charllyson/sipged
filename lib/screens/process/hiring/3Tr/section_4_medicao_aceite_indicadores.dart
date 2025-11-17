import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_blocs/process/hiring/3Tr/tr_controller.dart';

class SectionMedicaoAceiteIndicadores extends StatelessWidget {
  const SectionMedicaoAceiteIndicadores({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<TrController>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final w3 = inputW3(context, constraints);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle('4) Medição, Aceite e Indicadores'),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: c.trCriteriosMedicaoCtrl,
                    labelText: 'Critérios de medição',
                    maxLines: 3,
                    enabled: c.isEditable,
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: c.trCriteriosAceiteCtrl,
                    labelText: 'Critérios de aceite',
                    maxLines: 3,
                    enabled: c.isEditable,
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: c.trIndicadoresDesempenhoCtrl,
                    labelText: 'Indicadores de desempenho (SLA/KPI)',
                    maxLines: 3,
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
