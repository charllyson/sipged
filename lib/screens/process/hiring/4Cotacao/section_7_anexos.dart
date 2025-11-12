import 'package:flutter/material.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_blocs/process/hiring/4Cotacao/cotacao_controller.dart';

class SectionAnexos extends StatelessWidget {
  final CotacaoController controller;
  const SectionAnexos({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('6) Evidências/Anexos'),
        CustomTextField(
          controller: c.ctLinksAnexosCtrl,
          labelText: 'Links (SEI, propostas, planilhas, prints do Painel etc.)',
          maxLines: 2,
          enabled: c.isEditable,
        ),
      ],
    );
  }
}
