import 'package:flutter/material.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart' show DropDownButtonChange;
import 'package:siged/_utils/validates/form_validation_mixin.dart';
import 'package:siged/_blocs/process/hiring/2Etp/etp_controller.dart';

class SectionAlternativasSolucao extends StatelessWidget with FormValidationMixin {
  final EtpController controller;
  SectionAlternativasSolucao({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Title('3) Alternativas e solução recomendada'),
        Wrap(
          spacing: 12, runSpacing: 12,
          children: [
            SizedBox(
              width: _w(context, 3),
              child: DropDownButtonChange(
                enabled: c.isEditable,
                labelText: 'Solução recomendada',
                controller: c.etpSolucaoRecomendadaCtrl,
                items: const ['Obra de engenharia','Serviço de engenharia','Serviço comum','Aquisição'],
                validator: validateRequired,
              ),
            ),
            SizedBox(
              width: _w(context, 3),
              child: DropDownButtonChange(
                enabled: c.isEditable,
                labelText: 'Complexidade',
                controller: c.etpComplexidadeCtrl,
                items: const ['Baixa','Média','Alta'],
                validator: validateRequired,
              ),
            ),
            SizedBox(
              width: _w(context, 3),
              child: DropDownButtonChange(
                enabled: c.isEditable,
                labelText: 'Risco preliminar',
                controller: c.etpNivelRiscoCtrl,
                items: const ['Baixo','Moderado','Alto','Crítico'],
                validator: validateRequired,
              ),
            ),
            SizedBox(
              width: _w(context, 1),
              child: CustomTextField(
                controller: c.etpJustificativaSolucaoCtrl,
                enabled: c.isEditable,
                labelText: 'Justificativa da solução',
                validator: validateRequired,
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
