import 'package:flutter/material.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_blocs/process/hiring/7Dotacao/dotacao_controller.dart';

class SectionCronograma extends StatelessWidget {
  final DotacaoController controller;
  const SectionCronograma({super.key, required this.controller});

  double _w(BuildContext ctx, {int itemsPerLine = 4}) => responsiveInputWidth(
    context: ctx, itemsPerLine: itemsPerLine, spacing: 12, margin: 12, extraPadding: 24,
  );

  @override
  Widget build(BuildContext context) {
    final c = controller;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle('6) Cronograma de Desembolso (resumo)'),
        Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(
            width: _w(context),
            child: DropDownButtonChange(
              enabled: c.isEditable,
              labelText: 'Periodicidade',
              controller: c.desembolsoPeriodicidadeCtrl,
              items: const ['Mensal', 'Bimestral', 'Trimestral', 'Outro'],
              onChanged: (v) => c.desembolsoPeriodicidadeCtrl.text = v ?? '',
            ),
          ),
          SizedBox(width: _w(context), child: CustomTextField(controller: c.desembolsoMesesCtrl, labelText: 'Meses/Marcos (ex.: Jan–Jun)', enabled: c.isEditable)),
          SizedBox(
            width: _w(context, itemsPerLine: 1),
            child: CustomTextField(
              controller: c.desembolsoObservacoesCtrl,
              labelText: 'Observações / condicionantes',
              enabled: c.isEditable,
              maxLines: 2,
            ),
          ),
        ]),
        const SizedBox(height: 16),
      ],
    );
  }
}
