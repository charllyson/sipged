import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_blocs/process/hiring/3Tr/tr_controller.dart';

class SectionLocalPrazosCronograma extends StatelessWidget {
  const SectionLocalPrazosCronograma({super.key});

  double _w(BuildContext ctx, {int itemsPerLine = 3}) =>
      responsiveInputWidth(context: ctx, itemsPerLine: itemsPerLine);

  @override
  Widget build(BuildContext context) {
    final c = context.watch<TrController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('3) Local, Prazos e Cronograma'),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: _w(context),
              child: CustomTextField(
                controller: c.trLocalExecucaoCtrl,
                labelText: 'Local de execução',
                enabled: c.isEditable,
              ),
            ),
            SizedBox(
              width: _w(context),
              child: CustomTextField(
                controller: c.trPrazoExecucaoDiasCtrl,
                labelText: 'Prazo de execução (dias)',
                enabled: c.isEditable,
                keyboardType: TextInputType.number,
              ),
            ),
            SizedBox(
              width: _w(context),
              child: CustomTextField(
                controller: c.trVigenciaMesesCtrl,
                labelText: 'Vigência contratual (meses)',
                enabled: c.isEditable,
                keyboardType: TextInputType.number,
              ),
            ),
            SizedBox(
              width: _w(context, itemsPerLine: 1),
              child: CustomTextField(
                controller: c.trCronogramaFisicoCtrl,
                labelText: 'Cronograma físico preliminar (marcos/etapas)',
                maxLines: 4,
                enabled: c.isEditable,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
