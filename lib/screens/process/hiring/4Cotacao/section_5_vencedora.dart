import 'package:flutter/material.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';

import 'package:siged/_blocs/process/hiring/4Cotacao/cotacao_controller.dart';
import 'package:siged/_blocs/process/hiring/5Edital/company_data.dart';
import 'package:siged/_blocs/_process/process_controller.dart';

class SectionVencedora extends StatelessWidget {
  final CotacaoController controller;
  final ProcessController contractsController;
  const SectionVencedora({super.key, required this.controller, required this.contractsController});

  double _w(BuildContext ctx, {int itemsPerLine = 4}) =>
      responsiveInputWidth(context: ctx, itemsPerLine: itemsPerLine, spacing: 12, margin: 12, extraPadding: 24);

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Empresa vencedora'),
        Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(
            width: _w(context),
            child: DropDownButtonChange(
              enabled: c.isEditable,
              labelText: 'Empresa líder',
              items: CompanyData.companies,
              controller: contractsController.companyLeaderCtrl,
              onChanged: (v) => c.vEmpresaLiderCtrl.text = v ?? '',
            ),
          ),
          SizedBox(
            width: _w(context),
            child: CustomTextField(
              enabled: c.isEditable,
              labelText: 'Consórcio envolvidas',
              controller: contractsController.companiesInvolvedCtrl,
            ),
          ),
        ]),
      ],
    );
  }
}
