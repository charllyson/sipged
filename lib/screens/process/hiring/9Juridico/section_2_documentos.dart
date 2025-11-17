import 'package:flutter/material.dart';

import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_blocs/process/hiring/9Juridico/parecer_juridico_controller.dart';

class SectionDocumentos extends StatelessWidget {
  final ParecerJuridicoController controller;

  const SectionDocumentos({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final c = controller;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('2) Documentos/Peças analisadas'),
        LayoutBuilder(
          builder: (context, constraints) {
            final w3 = inputW3(context, constraints);

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: c.pjRefProcessoCtrl,
                    labelText: 'Referência do processo (SEI/Interno)',
                    enabled: c.isEditable,
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: c.pjDocumentosExaminadosCtrl,
                    labelText:
                    'Documentos examinados (TR, ETP, Minuta, Edital etc.)',
                    enabled: c.isEditable,
                    textAlignVertical: TextAlignVertical.top,
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: c.pjLinksAnexosCtrl,
                    labelText: 'Links/Anexos (SEI/Drive/PNCP)',
                    enabled: c.isEditable,
                    textAlignVertical: TextAlignVertical.top,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
