import 'package:flutter/material.dart';
import 'package:siged/_widgets/input/custom_date_field.dart';

import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_blocs/process/hiring/4Cotacao/cotacao_controller.dart';

class SectionConviteDivulgacao extends StatelessWidget {
  final CotacaoController controller;
  const SectionConviteDivulgacao({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w3 = inputW3(context, constraints);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle('3) Convite/Divulgação'),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w3,
                  child: DropDownButtonChange(
                    enabled: c.isEditable,
                    labelText: 'Meio de divulgação',
                    controller: c.ctMeioDivulgacaoCtrl,
                    items: const ['E-mail', 'Portal/Website', 'Telefone', 'Misto'],
                    onChanged: (v) => c.ctMeioDivulgacaoCtrl.text = v ?? '',
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: CustomDateField(
                    controller: c.ctPrazoRespostaCtrl,
                    labelText: 'Prazo para resposta (dd/mm/aaaa hh:mm)',
                    enabled: c.isEditable,
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: c.ctFornecedoresConvidadosCtrl,
                    labelText: 'Fornecedores convidados (nomes/CNPJ/e-mails)',
                    maxLines: 1,
                    enabled: c.isEditable,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
