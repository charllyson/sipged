import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart';
import 'package:siged/_utils/formats/mask_class.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_blocs/process/hiring/7Dotacao/dotacao_controller.dart';

class SectionEmpenho extends StatelessWidget {
  final DotacaoController controller;
  const SectionEmpenho({super.key, required this.controller});

  double _w(BuildContext ctx, {int itemsPerLine = 4}) => responsiveInputWidth(
    context: ctx, itemsPerLine: itemsPerLine, spacing: 12, margin: 12, extraPadding: 24,
  );

  @override
  Widget build(BuildContext context) {
    final c = controller;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle('5) Empenho'),
        Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(
            width: _w(context),
            child: DropDownButtonChange(
              enabled: c.isEditable,
              labelText: 'Modalidade de Empenho',
              controller: c.empenhoModalidadeCtrl,
              items: const ['Ordinário', 'Estimativo', 'Global'],
              onChanged: (v) => c.empenhoModalidadeCtrl.text = v ?? '',
            ),
          ),
          SizedBox(width: _w(context), child: CustomTextField(controller: c.empenhoNumeroCtrl, labelText: 'Nº da NE (Nota de Empenho)', enabled: c.isEditable)),
          SizedBox(
            width: _w(context),
            child: CustomTextField(
              controller: c.empenhoDataCtrl,
              labelText: 'Data da NE',
              hintText: 'dd/mm/aaaa',
              enabled: c.isEditable,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(8),
                TextInputMask(mask: '99/99/9999'),
              ],
              keyboardType: TextInputType.number,
            ),
          ),
          SizedBox(
            width: _w(context),
            child: CustomTextField(
              controller: c.empenhoValorCtrl,
              labelText: 'Valor Empenhado (R\$)',
              enabled: c.isEditable,
              keyboardType: TextInputType.number,
            ),
          ),
        ]),
        const SizedBox(height: 16),
      ],
    );
  }
}
