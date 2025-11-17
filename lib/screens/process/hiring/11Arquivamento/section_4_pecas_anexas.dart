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
  @override
  Widget build(BuildContext context) {
    final c = widget.controller;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('4) Peças Anexas'),
        LayoutBuilder(
          builder: (context, constraints) {
            final w2 = inputW2(context, constraints);

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w2,
                  child: CustomTextField(
                    controller: c.taPecasAnexasCtrl,
                    labelText:
                    'Peças anexas (TR, ETP, pareceres, publicações etc.)',
                    maxLines: 1,
                    enabled: c.isEditable,
                  ),
                ),
                SizedBox(
                  width: w2,
                  child: CustomTextField(
                    controller: c.taLinksCtrl,
                    labelText: 'Links (SEI/Drive/PNCP)',
                    maxLines: 1,
                    enabled: c.isEditable,
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
