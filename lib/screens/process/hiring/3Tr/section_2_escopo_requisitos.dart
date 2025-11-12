import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_blocs/process/hiring/3Tr/tr_controller.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';

class SectionEscopoRequisitos extends StatelessWidget with FormValidationMixin {
  SectionEscopoRequisitos({super.key});

  double _w(BuildContext ctx, {int itemsPerLine = 3}) =>
      responsiveInputWidth(context: ctx, itemsPerLine: itemsPerLine);

  @override
  Widget build(BuildContext context) {
    final c = context.watch<TrController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle('2) Escopo / Requisitos'),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: _w(context),
              child: CustomTextField(
                controller: c.trEscopoDetalhadoCtrl,
                labelText: 'Escopo detalhado da contratação',
                maxLines: 6,
                enabled: c.isEditable,
                validator: validateRequired,
              ),
            ),
            SizedBox(
              width: _w(context),
              child: CustomTextField(
                controller: c.trRequisitosTecnicosCtrl,
                labelText: 'Requisitos técnicos mínimos',
                maxLines: 5,
                enabled: c.isEditable,
              ),
            ),
            SizedBox(
              width: _w(context),
              child: CustomTextField(
                controller: c.trEspecificacoesNormasCtrl,
                labelText: 'Especificações / normas aplicáveis (ABNT, DNIT etc.)',
                maxLines: 4,
                enabled: c.isEditable,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
