import 'package:flutter/material.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';
import 'package:siged/_blocs/process/hiring/6Habilitacao/habilitacao_controller.dart';

class SectionLicitacao extends StatelessWidget with FormValidationMixin {
  final HabilitacaoController controller;
  final String contractId;
  SectionLicitacao({super.key, required this.controller, required this.contractId});

  double _w(BuildContext ctx, {int itemsPerLine = 4}) => responsiveInputWidth(
    context: ctx, itemsPerLine: itemsPerLine, spacing: 12, margin: 12, extraPadding: 24,
  );

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle('5) Documentos da Licitação/Adesão'),
        Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(
            width: _w(context),
            child: DropDownButtonChange(
              enabled: c.isEditable,
              labelText: 'Modalidade do processo',
              controller: c.procModalidadeCtrl,
              items: const ['Concorrência', 'Pregão', 'RDC', 'Adesão a ARP', 'Dispensa', 'Inexigibilidade'],
              onChanged: (v) => c.procModalidadeCtrl.text = v ?? '',
              validator: validateRequired,
            ),
          ),
          SizedBox(
            width: _w(context),
            child: CustomTextField(
              controller: c.procNumeroCtrl,
              labelText: 'Nº do processo/edital/ARP',
              enabled: c.isEditable,
            ),
          ),
          SizedBox(
            width: _w(context),
            child: CustomTextField(
              controller: c.procAtaSessaoLinkCtrl,
              labelText: 'Ata da sessão (link/arquivo)',
              enabled: c.isEditable,
            ),
          ),
          SizedBox(
            width: _w(context),
            child: CustomTextField(
              controller: c.procAtaAdjudicacaoLinkCtrl,
              labelText: 'Ata de adjudicação (link/arquivo)',
              enabled: c.isEditable,
            ),
          ),
          SizedBox(
            width: _w(context, itemsPerLine: 1),
            child: CustomTextField(
              controller: c.procEditalLinkCtrl,
              labelText: 'Edital/Termo de Adesão (link/arquivo)',
              enabled: c.isEditable,
            ),
          ),
          SizedBox(
            width: _w(context, itemsPerLine: 1),
            child: CustomTextField(
              controller: c.procOficiosComunicacoesCtrl,
              labelText: 'Ofícios/comunicações (links/arquivos)',
              enabled: c.isEditable,
            ),
          ),
        ]),
        const SizedBox(height: 16),
      ],
    );
  }
}
