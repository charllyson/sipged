import 'package:flutter/material.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart' show DropDownButtonChange;
import 'package:siged/_blocs/process/hiring/2Etp/etp_controller.dart';

class SectionPremissasRestricoesLicenciamento extends StatelessWidget {
  final EtpController controller;
  const SectionPremissasRestricoesLicenciamento({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Title('6) Premissas, restrições e licenciamento'),
        Wrap(
          spacing: 12, runSpacing: 12,
          children: [
            SizedBox(
              width: _w(context, 1),
              child: CustomTextField(
                controller: c.etpPremissasCtrl,
                enabled: c.isEditable,
                labelText: 'Premissas',
                maxLines: 3,
              ),
            ),
            SizedBox(
              width: _w(context, 1),
              child: CustomTextField(
                controller: c.etpRestricoesCtrl,
                enabled: c.isEditable,
                labelText: 'Restrições',
                maxLines: 3,
              ),
            ),
            SizedBox(
              width: _w(context, 2),
              child: DropDownButtonChange(
                enabled: c.isEditable,
                labelText: 'Licenciamento ambiental necessário?',
                controller: c.etpLicenciamentoAmbientalCtrl,
                items: const ['Sim','Não','A confirmar'],
              ),
            ),
            SizedBox(
              width: _w(context, 1),
              child: CustomTextField(
                controller: c.etpObservacoesAmbientaisCtrl,
                enabled: c.isEditable,
                labelText: 'Observações ambientais',
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
