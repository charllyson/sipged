import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_blocs/process/hiring/3Tr/tr_controller.dart';

class SectionRiscosPenalidadesCondicoes extends StatelessWidget {
  const SectionRiscosPenalidadesCondicoes({super.key});

  double _w(BuildContext ctx, {int itemsPerLine = 2}) =>
      responsiveInputWidth(context: ctx, itemsPerLine: itemsPerLine);

  @override
  Widget build(BuildContext context) {
    final c = context.watch<TrController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('8) Riscos, Penalidades e Demais Condições'),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: _w(context, itemsPerLine: 1),
              child: CustomTextField(
                controller: c.trMatrizRiscosCtrl,
                labelText: 'Matriz de riscos (preliminar)',
                maxLines: 4,
                enabled: c.isEditable,
              ),
            ),
            SizedBox(
              width: _w(context, itemsPerLine: 1),
              child: CustomTextField(
                controller: c.trPenalidadesCtrl,
                labelText: 'Penalidades e sanções',
                maxLines: 3,
                enabled: c.isEditable,
              ),
            ),
            SizedBox(
              width: _w(context),
              child: CustomTextField(
                controller: c.trDemaisCondicoesCtrl,
                labelText: 'Demais condições (visita técnica, seguros, interfaces etc.)',
                maxLines: 3,
                enabled: c.isEditable,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
