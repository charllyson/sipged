import 'package:flutter/material.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_blocs/process/hiring/4Cotacao/cotacao_controller.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';

class SectionObjetoItens extends StatelessWidget with FormValidationMixin {
  final CotacaoController controller;
  SectionObjetoItens({super.key, required this.controller});

  double _w(BuildContext ctx, {int itemsPerLine = 4}) =>
      responsiveInputWidth(context: ctx, itemsPerLine: itemsPerLine, spacing: 12, margin: 12, extraPadding: 24);

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('2) Objeto/Itens (resumo)'),
        Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(
            width: _w(context, itemsPerLine: 1),
            child: CustomTextField(
              controller: c.ctObjetoCtrl,
              labelText: 'Objeto/escopo resumido da cotação',
              maxLines: 3,
              enabled: c.isEditable,
              validator: validateRequired,
            ),
          ),
          SizedBox(
            width: _w(context),
            child: CustomTextField(
              controller: c.ctUnidadeMedidaCtrl,
              labelText: 'Unidade de medida',
              enabled: c.isEditable,
            ),
          ),
          SizedBox(
            width: _w(context),
            child: CustomTextField(
              controller: c.ctQuantidadeCtrl,
              labelText: 'Quantidade estimada',
              enabled: c.isEditable,
              keyboardType: TextInputType.number,
            ),
          ),
          SizedBox(
            width: _w(context, itemsPerLine: 1),
            child: CustomTextField(
              controller: c.ctEspecificacoesCtrl,
              labelText: 'Especificações técnicas relevantes',
              maxLines: 3,
              enabled: c.isEditable,
            ),
          ),
        ]),
      ],
    );
  }
}
