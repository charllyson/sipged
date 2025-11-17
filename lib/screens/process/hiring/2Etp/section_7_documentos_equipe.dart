import 'package:flutter/material.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart'
    show DropDownButtonChange;
import 'package:siged/_widgets/input/dropdown_yes_no.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_blocs/process/hiring/2Etp/etp_controller.dart';

class SectionDocumentosEquipe extends StatelessWidget {
  final EtpController controller;
  const SectionDocumentosEquipe({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w3 = inputW3(context, constraints);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle('7) Documentos, evidências e equipe'),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w3,
                  child: YesNoDrop(
                    controller: (value) => c.etpLevantamentosCampoCtrl,
                    enabled: c.isEditable,
                    labelText: 'Levantamentos de campo',
                    value: c.etpLevantamentosCampoCtrl.text,
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: YesNoDrop(
                    controller: (value) => c.etpProjetoExistenteCtrl,
                    enabled: c.isEditable,
                    labelText: 'Projeto básico/executivo existente?',
                    value: c.etpProjetoExistenteCtrl.text,
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: YesNoDrop(
                    controller: (value) => c.etpEquipeEnvolvidaCtrl,
                    enabled: c.isEditable,
                    labelText: 'Equipe envolvida (nomes/cargos)',
                    value: c.etpEquipeEnvolvidaCtrl.text,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}
