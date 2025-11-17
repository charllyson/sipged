import 'package:flutter/material.dart';

import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';

import 'package:siged/_blocs/process/hiring/4Cotacao/cotacao_controller.dart';
import 'package:siged/_blocs/_process/process_controller.dart';

class SectionVencedora extends StatelessWidget {
  final CotacaoController controller;
  final ProcessController contractsController;

  const SectionVencedora({
    super.key,
    required this.controller,
    required this.contractsController,
  });

  @override
  Widget build(BuildContext context) {
    final c = controller;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w2 = inputW2(context, constraints);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle('Empresa vencedora'),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w2,
                  child: CustomTextField(
                    enabled: c.isEditable,
                    labelText: 'Empresa líder',
                    controller: contractsController.companyLeaderCtrl,
                    onChanged: (v) => c.vEmpresaLiderCtrl.text = v ?? '',
                  ),
                ),
                SizedBox(
                  width: w2,
                  child: CustomTextField(
                    enabled: c.isEditable,
                    labelText: 'Consórcio envolvidas',
                    controller: contractsController.companiesInvolvedCtrl,
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
