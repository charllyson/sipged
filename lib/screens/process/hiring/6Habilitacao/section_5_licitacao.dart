import 'package:flutter/material.dart';
import 'package:siged/_blocs/process/hiring/0Stages/hiring_data.dart';

import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';

import 'package:siged/_blocs/process/hiring/6Habilitacao/habilitacao_controller.dart';

class SectionLicitacao extends StatelessWidget with FormValidationMixin {
  final HabilitacaoController controller;
  final String contractId;
  SectionLicitacao({
    super.key,
    required this.controller,
    required this.contractId,
  });

  @override
  Widget build(BuildContext context) {
    final c = controller;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w6 = inputW6(context, constraints);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle('5) Documentos da Licitação/Adesão'),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w6,
                  child: DropDownButtonChange(
                    enabled: c.isEditable,
                    labelText: 'Modalidade do processo',
                    controller: c.procModalidadeCtrl,
                    items: HiringData.modalidadeDeContratacao,
                    onChanged: (v) => c.procModalidadeCtrl.text = v ?? '',
                    validator: validateRequired,
                  ),
                ),
                SizedBox(
                  width: w6,
                  child: CustomTextField(
                    controller: c.procNumeroCtrl,
                    labelText: 'Nº do processo/edital/ARP',
                    enabled: c.isEditable,
                  ),
                ),
                SizedBox(
                  width: w6,
                  child: CustomTextField(
                    controller: c.procAtaSessaoLinkCtrl,
                    labelText: 'Ata da sessão (link/arquivo)',
                    enabled: c.isEditable,
                  ),
                ),
                SizedBox(
                  width: w6,
                  child: CustomTextField(
                    controller: c.procAtaAdjudicacaoLinkCtrl,
                    labelText: 'Ata de adjudicação (link/arquivo)',
                    enabled: c.isEditable,
                  ),
                ),
                SizedBox(
                  width: w6,
                  child: CustomTextField(
                    controller: c.procEditalLinkCtrl,
                    labelText: 'Edital/Termo de Adesão (link/arquivo)',
                    enabled: c.isEditable,
                  ),
                ),
                SizedBox(
                  width: w6,
                  child: CustomTextField(
                    controller: c.procOficiosComunicacoesCtrl,
                    labelText:
                    'Ofícios/comunicações (links/arquivos)',
                    enabled: c.isEditable,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}
