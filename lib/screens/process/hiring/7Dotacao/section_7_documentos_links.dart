import 'package:flutter/material.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_blocs/process/hiring/7Dotacao/dotacao_controller.dart';

class SectionDocumentosLinks extends StatelessWidget {
  final DotacaoController controller;
  const SectionDocumentosLinks({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle('7) Documentos / Links'),
        CustomTextField(
          controller: c.linksComprovacoesCtrl,
          labelText: 'Links (NE, Reserva, prints do SIAF/SIGEF, planilhas)',
          enabled: c.isEditable,
          maxLines: 2,
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
