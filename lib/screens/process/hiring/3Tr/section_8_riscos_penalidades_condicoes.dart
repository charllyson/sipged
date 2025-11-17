import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_blocs/process/hiring/3Tr/tr_controller.dart';

class SectionRiscosPenalidadesCondicoes extends StatelessWidget {
  const SectionRiscosPenalidadesCondicoes({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<TrController>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final w3 = inputW3(context, constraints);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle('8) Riscos, Penalidades e Demais Condições'),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: c.trMatrizRiscosCtrl,
                    labelText: 'Matriz de riscos (preliminar)',
                    maxLines: 4,
                    enabled: c.isEditable,
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: c.trPenalidadesCtrl,
                    labelText: 'Penalidades e sanções',
                    maxLines: 4,
                    enabled: c.isEditable,
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: c.trDemaisCondicoesCtrl,
                    labelText:
                    'Demais condições (visita técnica, seguros, interfaces etc.)',
                    maxLines: 4,
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
