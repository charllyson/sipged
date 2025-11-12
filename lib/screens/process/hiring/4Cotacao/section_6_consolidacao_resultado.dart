import 'package:flutter/material.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_blocs/process/hiring/4Cotacao/cotacao_controller.dart';

class SectionConsolidacaoResultado extends StatelessWidget {
  final CotacaoController controller;
  const SectionConsolidacaoResultado({super.key, required this.controller});

  double _w(BuildContext ctx, {int itemsPerLine = 4}) =>
      responsiveInputWidth(context: ctx, itemsPerLine: itemsPerLine, spacing: 12, margin: 12, extraPadding: 24);

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('5) Consolidação e Resultado'),
        Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(
            width: _w(context),
            child: DropDownButtonChange(
              enabled: c.isEditable,
              labelText: 'Critério de consolidação',
              controller: c.ctCriterioConsolidacaoCtrl,
              items: const ['Média simples', 'Mediana', 'Menor preço válido', 'Outros'],
              onChanged: (v) => c.ctCriterioConsolidacaoCtrl.text = v ?? '',
            ),
          ),
          SizedBox(
            width: _w(context),
            child: CustomTextField(
              controller: c.ctValorConsolidadoCtrl,
              labelText: 'Valor consolidado (R\$)',
              enabled: c.isEditable,
              keyboardType: TextInputType.number,
            ),
          ),
          SizedBox(
            width: _w(context, itemsPerLine: 1),
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
  }
}
