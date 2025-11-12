import 'package:flutter/material.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_blocs/process/hiring/2Etp/etp_controller.dart';

class SectionCronogramaIndicadores extends StatelessWidget {
  final EtpController controller;
  const SectionCronogramaIndicadores({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Title('5) Cronograma, indicadores e aceite (preliminares)'),
        Wrap(
          spacing: 12, runSpacing: 12,
          children: [
            SizedBox(
              width: _w(context, 2),
              child: CustomTextField(
                controller: c.etpPrazoExecucaoDiasCtrl,
                enabled: c.isEditable,
                labelText: 'Prazo estimado (dias)',
                keyboardType: TextInputType.number,
              ),
            ),
            SizedBox(
              width: _w(context, 2),
              child: CustomTextField(
                controller: c.etpTempoVigenciaMesesCtrl,
                enabled: c.isEditable,
                labelText: 'Vigência estimada (meses)',
                keyboardType: TextInputType.number,
              ),
            ),
            SizedBox(
              width: _w(context, 1),
              child: CustomTextField(
                controller: c.etpCriteriosAceiteCtrl,
                enabled: c.isEditable,
                labelText: 'Critérios de medição e aceite',
                maxLines: 3,
              ),
            ),
            SizedBox(
              width: _w(context, 1),
              child: CustomTextField(
                controller: c.etpIndicadoresDesempenhoCtrl,
                enabled: c.isEditable,
                labelText: 'Indicadores de desempenho',
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
