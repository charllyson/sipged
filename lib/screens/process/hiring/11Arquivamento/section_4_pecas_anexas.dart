import 'package:flutter/material.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_blocs/process/hiring/11Arquivamento/termo_arquivamento_controller.dart';

class SectionPecasAnexasTA extends StatefulWidget {
  final TermoArquivamentoController controller;
  const SectionPecasAnexasTA({super.key, required this.controller});

  @override
  State<SectionPecasAnexasTA> createState() => _SectionPecasAnexasTAState();
}

class _SectionPecasAnexasTAState extends State<SectionPecasAnexasTA> {
  double _w(BuildContext ctx, {int itemsPerLine = 1}) => responsiveInputWidth(
    context: ctx, itemsPerLine: itemsPerLine, spacing: 12, margin: 12, extraPadding: 24,
  );

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionTitle('4) Peças Anexas'),
      Wrap(spacing: 12, runSpacing: 12, children: [
        SizedBox(
          width: _w(context),
          child: CustomTextField(
            controller: c.taPecasAnexasCtrl,
            labelText: 'Peças anexas (TR, ETP, pareceres, publicações etc.)',
            maxLines: 2,
            enabled: c.isEditable,
          ),
        ),
        SizedBox(
          width: _w(context),
          child: CustomTextField(
            controller: c.taLinksCtrl,
            labelText: 'Links (SEI/Drive/PNCP)',
            maxLines: 2,
            enabled: c.isEditable,
          ),
        ),
      ]),
      const SizedBox(height: 16),
    ]);
  }
}
