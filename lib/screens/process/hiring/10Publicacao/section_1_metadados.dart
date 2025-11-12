import 'package:flutter/material.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart' show DropDownButtonChange;
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_blocs/process/hiring/10Publicacao/publicacao_extrato_controller.dart';

class SectionMetadadosExtrato extends StatefulWidget {
  final PublicacaoExtratoController controller;
  const SectionMetadadosExtrato({super.key, required this.controller});

  @override
  State<SectionMetadadosExtrato> createState() => _SectionMetadadosExtratoState();
}

class _SectionMetadadosExtratoState extends State<SectionMetadadosExtrato>
    with FormValidationMixin {
  double _w(BuildContext ctx, {int itemsPerLine = 4}) => responsiveInputWidth(
    context: ctx,
    itemsPerLine: itemsPerLine,
    spacing: 12,
    margin: 12,
    extraPadding: 24,
  );

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionTitle('1) Metadados do Extrato'),
      Wrap(spacing: 12, runSpacing: 12, children: [
        SizedBox(
          width: _w(context),
          child: DropDownButtonChange(
            enabled: c.isEditable,
            labelText: 'Tipo de extrato',
            controller: c.peTipoExtratoCtrl,
            items: const [
              'Extrato de Contrato',
              'Extrato de ARP',
              'Extrato de Aditivo/Apostilamento'
            ],
            onChanged: (v) => setState(() => c.peTipoExtratoCtrl.text = v ?? ''),
            validator: validateRequired,
          ),
        ),
        SizedBox(
          width: _w(context),
          child: CustomTextField(
            controller: c.peNumeroContratoCtrl,
            labelText: 'Nº do contrato/ARP',
            enabled: c.isEditable,
            validator: validateRequired,
          ),
        ),
        SizedBox(
          width: _w(context),
          child: CustomTextField(
            controller: c.peProcessoCtrl,
            labelText: 'Nº do processo (SEI/Interno)',
            enabled: c.isEditable,
            validator: validateRequired,
          ),
        ),
        SizedBox(
          width: _w(context, itemsPerLine: 1),
          child: CustomTextField(
            controller: c.peObjetoResumoCtrl,
            labelText: 'Objeto (resumo para o extrato)',
            maxLines: 3,
            enabled: c.isEditable,
            validator: validateRequired,
          ),
        ),
      ]),
      const SizedBox(height: 16),
    ]);
  }
}
