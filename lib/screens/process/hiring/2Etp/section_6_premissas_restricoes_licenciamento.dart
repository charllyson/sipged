import 'package:flutter/material.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart'
    show DropDownButtonChange;
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_blocs/process/hiring/2Etp/etp_controller.dart';

class SectionPremissasRestricoesLicenciamento extends StatelessWidget {
  final EtpController controller;
  const SectionPremissasRestricoesLicenciamento({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final c = controller;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w3 = inputW3(context, constraints);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle('6) Premissas, restrições e licenciamento'),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: w3,
                      child: DropDownButtonChange(
                        enabled: c.isEditable,
                        labelText: 'Licenciamento ambiental necessário?',
                        controller: c.etpLicenciamentoAmbientalCtrl,
                        items: const ['Sim', 'Não', 'A confirmar'],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: w3,
                      child: CustomTextField(
                        controller: c.etpObservacoesAmbientaisCtrl,
                        enabled: c.isEditable,
                        labelText: 'Observações ambientais',
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: c.etpPremissasCtrl,
                    enabled: c.isEditable,
                    labelText: 'Premissas',
                    maxLines: 5,
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: c.etpRestricoesCtrl,
                    enabled: c.isEditable,
                    labelText: 'Restrições',
                    maxLines: 5,
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
