import 'package:flutter/material.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_blocs/process/hiring/7Dotacao/dotacao_controller.dart';

class SectionNaturezaDespesa extends StatelessWidget {
  final DotacaoController controller;
  const SectionNaturezaDespesa({super.key, required this.controller});

  double _w(BuildContext ctx, {int itemsPerLine = 4}) => responsiveInputWidth(
    context: ctx, itemsPerLine: itemsPerLine, spacing: 12, margin: 12, extraPadding: 24,
  );

  @override
  Widget build(BuildContext context) {
    final c = controller;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle('3) Natureza da Despesa'),
        Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(
            width: _w(context),
            child: CustomTextField(
              controller: c.modalidadeAplicacaoCtrl,
              labelText: 'Modalidade de aplicação (ex.: 90)',
              enabled: c.isEditable,
              keyboardType: TextInputType.number,
            ),
          ),
          SizedBox(
            width: _w(context),
            child: CustomTextField(
              controller: c.elementoDespesaCtrl,
              labelText: 'Elemento (ex.: 39, 44)',
              enabled: c.isEditable,
              keyboardType: TextInputType.number,
            ),
          ),
          SizedBox(
            width: _w(context),
            child: CustomTextField(
              controller: c.subelementoCtrl,
              labelText: 'Subelemento (quando houver)',
              enabled: c.isEditable,
            ),
          ),
          SizedBox(
            width: _w(context, itemsPerLine: 1),
            child: CustomTextField(
              controller: c.descricaoNdCtrl,
              labelText: 'Descrição da ND',
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
