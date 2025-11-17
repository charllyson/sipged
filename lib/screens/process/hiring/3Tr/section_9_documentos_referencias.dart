import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_blocs/process/hiring/3Tr/tr_controller.dart';

class SectionDocumentosReferencias extends StatelessWidget {
  const SectionDocumentosReferencias({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<TrController>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final w1 = inputW1(context, constraints);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle('9) Documentos / Referências'),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w1,
                  child: CustomTextField(
                    controller: c.trLinksDocumentosCtrl,
                    labelText:
                    'Links / Referências (SEI, projetos, estudos, mapas)',
                    maxLines: 2,
                    enabled: c.isEditable,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
