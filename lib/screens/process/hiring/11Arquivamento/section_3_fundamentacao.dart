import 'package:flutter/material.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_blocs/process/hiring/11Arquivamento/termo_arquivamento_controller.dart';

class SectionFundamentacaoTA extends StatefulWidget {
  final TermoArquivamentoController controller;
  const SectionFundamentacaoTA({super.key, required this.controller});

  @override
  State<SectionFundamentacaoTA> createState() => _SectionFundamentacaoTAState();
}

class _SectionFundamentacaoTAState extends State<SectionFundamentacaoTA>
    with FormValidationMixin {
  double _w(BuildContext ctx, {int itemsPerLine = 1}) => responsiveInputWidth(
    context: ctx, itemsPerLine: itemsPerLine, spacing: 12, margin: 12, extraPadding: 24,
  );

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionTitle('3) Fundamentação'),
      Wrap(spacing: 12, runSpacing: 12, children: [
        SizedBox(
          width: _w(context),
          child: CustomTextField(
            controller: c.taFundamentosLegaisCtrl,
            labelText: 'Fundamentos legais (ex.: Lei 14.133/2021, art. ...)',
            maxLines: 3,
            enabled: c.isEditable,
            validator: validateRequired,
          ),
        ),
        SizedBox(
          width: _w(context),
          child: CustomTextField(
            controller: c.taJustificativaCtrl,
            labelText: 'Justificativa (resumo técnico/jurídico)',
            maxLines: 3,
            enabled: c.isEditable,
          ),
        ),
      ]),
      const SizedBox(height: 16),
    ]);
  }
}
