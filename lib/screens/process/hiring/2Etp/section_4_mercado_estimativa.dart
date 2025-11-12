import 'package:flutter/material.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart' show DropDownButtonChange;
import 'package:siged/_blocs/process/hiring/2Etp/etp_controller.dart';

class SectionMercadoEstimativa extends StatelessWidget {
  final EtpController controller;
  const SectionMercadoEstimativa({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Title('4) Mercado e estimativa de custos/benefícios'),
        Wrap(
          spacing: 12, runSpacing: 12,
          children: [
            SizedBox(
              width: _w(context, 1),
              child: CustomTextField(
                controller: c.etpAnaliseMercadoCtrl,
                enabled: c.isEditable,
                labelText: 'Análise de mercado / fornecedores potenciais',
                maxLines: 4,
              ),
            ),
            SizedBox(
              width: _w(context, 3),
              child: CustomTextField(
                controller: c.etpEstimativaValorCtrl,
                enabled: c.isEditable,
                labelText: 'Estimativa de valor (R\$)',
                keyboardType: TextInputType.number,
              ),
            ),
            SizedBox(
              width: _w(context, 3),
              child: DropDownButtonChange(
                enabled: c.isEditable,
                labelText: 'Metodologia',
                controller: c.etpMetodoEstimativaCtrl,
                items: const ['SINAPI','DER ref.','Cotações','Misto'],
              ),
            ),
            SizedBox(
              width: _w(context, 1),
              child: CustomTextField(
                controller: c.etpBeneficiosEsperadosCtrl,
                enabled: c.isEditable,
                labelText: 'Benefícios esperados',
                maxLines: 3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  double _w(BuildContext ctx, int perLine) =>
      MediaQuery.of(ctx).size.width >= 1200 ? (MediaQuery.of(ctx).size.width - 64) / perLine : 480;
}

class _Title extends StatelessWidget {
  final String text;
  const _Title(this.text);
  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: Theme.of(context).textTheme.titleMedium));
}
