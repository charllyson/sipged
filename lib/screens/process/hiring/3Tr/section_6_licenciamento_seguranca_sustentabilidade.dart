import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_blocs/process/hiring/3Tr/tr_controller.dart';

class SectionLicenciamentoSegurancaSustentabilidade extends StatelessWidget {
  const SectionLicenciamentoSegurancaSustentabilidade({super.key});

  double _w(BuildContext ctx, {int itemsPerLine = 2}) =>
      responsiveInputWidth(context: ctx, itemsPerLine: itemsPerLine);

  @override
  Widget build(BuildContext context) {
    final c = context.watch<TrController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('6) Licenciamento, Segurança e Sustentabilidade'),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: _w(context),
              child: DropDownButtonChange(
                enabled: c.isEditable,
                labelText: 'Licenciamento ambiental',
                controller: c.trLicenciamentoAmbientalCtrl,
                items: const ['Sim', 'Não', 'A confirmar'],
                onChanged: (v) => c.trLicenciamentoAmbientalCtrl.text = v ?? '',
              ),
            ),
            SizedBox(
              width: _w(context),
              child: CustomTextField(
                controller: c.trSegurancaTrabalhoCtrl,
                labelText: 'Segurança do trabalho / Sinalização de obra',
                maxLines: 3,
                enabled: c.isEditable,
              ),
            ),
            SizedBox(
              width: _w(context),
              child: CustomTextField(
                controller: c.trSustentabilidadeCtrl,
                labelText: 'Diretrizes de sustentabilidade e acessibilidade',
                maxLines: 3,
                enabled: c.isEditable,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
