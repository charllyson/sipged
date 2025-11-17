import 'package:flutter/material.dart';
import 'package:siged/_blocs/process/hiring/0Stages/hiring_data.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart'
    show DropDownButtonChange;
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_blocs/process/hiring/2Etp/etp_controller.dart';

class SectionMercadoEstimativa extends StatelessWidget {
  final EtpController controller;
  const SectionMercadoEstimativa({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w3 = inputW3(context, constraints);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle('4) Mercado e estimativa de custos/benefícios'),
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
                        child: DropDownButtonChange(
                          enabled: c.isEditable,
                          labelText: 'Metodologia',
                          controller: c.etpMetodoEstimativaCtrl,
                          items: HiringData.metodologia,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: w3,
                        child: CustomTextField(
                          controller: c.etpEstimativaValorCtrl,
                          enabled: c.isEditable,
                          labelText: 'Estimativa de valor (R\$)',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: c.etpAnaliseMercadoCtrl,
                    enabled: c.isEditable,
                    labelText: 'Análise de mercado / fornecedores potenciais',
                    maxLines: 5,
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: c.etpBeneficiosEsperadosCtrl,
                    enabled: c.isEditable,
                    labelText: 'Benefícios esperados',
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
