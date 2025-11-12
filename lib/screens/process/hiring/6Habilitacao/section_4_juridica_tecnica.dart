import 'package:flutter/material.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_blocs/process/hiring/6Habilitacao/habilitacao_controller.dart';

class SectionJuridicaTecnica extends StatelessWidget {
  final HabilitacaoController controller;
  const SectionJuridicaTecnica({super.key, required this.controller});

  double _w(BuildContext ctx, {int itemsPerLine = 4}) => responsiveInputWidth(
    context: ctx, itemsPerLine: itemsPerLine, spacing: 12, margin: 12, extraPadding: 24,
  );

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle('4) Habilitação Jurídica e Técnica'),
        Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(
            width: _w(context),
            child: CustomTextField(
              controller: c.docContratoSocialCtrl,
              labelText: 'Contrato/Estatuto social (link/arquivo)',
              enabled: c.isEditable,
            ),
          ),
          SizedBox(
            width: _w(context),
            child: CustomTextField(
              controller: c.docCnpjCartaoCtrl,
              labelText: 'Cartão CNPJ (link/arquivo)',
              enabled: c.isEditable,
            ),
          ),
          SizedBox(
            width: _w(context),
            child: DropDownButtonChange(
              enabled: c.isEditable,
              labelText: 'Atestados de capacidade técnica',
              controller: c.docAtestadosStatusCtrl,
              items: const ['Apresentados', 'Parciais', 'Não apresentados', 'Dispensados'],
              onChanged: (v) => c.docAtestadosStatusCtrl.text = v ?? '',
            ),
          ),
          SizedBox(
            width: _w(context, itemsPerLine: 1),
            child: CustomTextField(
              controller: c.docAtestadosLinksCtrl,
              labelText: 'Links/observações dos atestados',
              maxLines: 2,
              enabled: c.isEditable,
            ),
          ),
        ]),
        const SizedBox(height: 16),
      ],
    );
  }
}
