import 'package:flutter/material.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_blocs/process/hiring/2Etp/etp_controller.dart';

class SectionCronogramaIndicadores extends StatelessWidget {
  final EtpController controller;
  const SectionCronogramaIndicadores({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w3 = inputW3(context, constraints);
        final w1 = inputW1(context, constraints);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(
              '5) Cronograma, indicadores e aceite (preliminares)',
            ),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        width: w3,
                        child: CustomTextField(
                          controller: c.etpTempoVigenciaMesesCtrl,
                          enabled: c.isEditable,
                          labelText: 'Vigência estimada (meses)',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      SizedBox(height: 12),
                      SizedBox(
                        width: w3,
                        child: CustomTextField(
                          controller: c.etpPrazoExecucaoDiasCtrl,
                          enabled: c.isEditable,
                          labelText: 'Prazo estimado (dias)',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: c.etpCriteriosAceiteCtrl,
                    enabled: c.isEditable,
                    labelText: 'Critérios de medição e aceite',
                    maxLines: 5,
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: c.etpIndicadoresDesempenhoCtrl,
                    enabled: c.isEditable,
                    labelText: 'Indicadores de desempenho',
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
