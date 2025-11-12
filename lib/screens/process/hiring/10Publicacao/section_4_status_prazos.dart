import 'package:flutter/material.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart' show DropDownButtonChange;
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_blocs/process/hiring/10Publicacao/publicacao_extrato_controller.dart';

class SectionStatusPrazos extends StatefulWidget {
  final PublicacaoExtratoController controller;
  const SectionStatusPrazos({super.key, required this.controller});

  @override
  State<SectionStatusPrazos> createState() => _SectionStatusPrazosState();
}

class _SectionStatusPrazosState extends State<SectionStatusPrazos> {
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
      SectionTitle('4) Status e Controle de Prazos'),
      Wrap(spacing: 12, runSpacing: 12, children: [
        SizedBox(
          width: _w(context),
          child: DropDownButtonChange(
            enabled: c.isEditable,
            labelText: 'Status',
            controller: c.peStatusCtrl,
            items: const ['Rascunho','Enviado','Publicado','Devolvido para ajustes'],
            onChanged: (v) => setState(() => c.peStatusCtrl.text = v ?? ''),
          ),
        ),
        SizedBox(
          width: _w(context),
          child: DropDownButtonChange(
            enabled: c.isEditable,
            labelText: 'Prazo legal atendido?',
            controller: c.pePrazoLegalCtrl,
            items: const ['Sim','Não','N/A'],
            onChanged: (v) => setState(() => c.pePrazoLegalCtrl.text = v ?? ''),
          ),
        ),
        SizedBox(
          width: _w(context, itemsPerLine: 1),
          child: CustomTextField(
            controller: c.peObservacoesCtrl,
            labelText: 'Observações / ajustes solicitados',
            maxLines: 2,
            enabled: c.isEditable,
          ),
        ),
      ]),
      const SizedBox(height: 16),
    ]);
  }
}
