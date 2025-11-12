import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_blocs/process/hiring/3Tr/tr_controller.dart';

class SectionMedicaoAceiteIndicadores extends StatelessWidget {
  const SectionMedicaoAceiteIndicadores({super.key});

  double _w(BuildContext ctx, {int itemsPerLine = 2}) =>
      responsiveInputWidth(context: ctx, itemsPerLine: itemsPerLine);

  @override
  Widget build(BuildContext context) {
    final c = context.watch<TrController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('4) Medição, Aceite e Indicadores'),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: _w(context),
              child: CustomTextField(
                controller: c.trCriteriosMedicaoCtrl,
                labelText: 'Critérios de medição',
                maxLines: 3,
                enabled: c.isEditable,
              ),
            ),
            SizedBox(
              width: _w(context),
              child: CustomTextField(
                controller: c.trCriteriosAceiteCtrl,
                labelText: 'Critérios de aceite',
                maxLines: 3,
                enabled: c.isEditable,
              ),
            ),
            SizedBox(
              width: _w(context),
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
  }
}
