import 'package:flutter/material.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart' show DropDownButtonChange;
import 'package:siged/_blocs/process/hiring/2Etp/etp_controller.dart';

class SectionDocumentosEquipe extends StatelessWidget {
  final EtpController controller;
  const SectionDocumentosEquipe({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Title('7) Documentos, evidências e equipe'),
        Wrap(
          spacing: 12, runSpacing: 12,
          children: [
            SizedBox(
              width: _w(context, 2),
              child: DropDownButtonChange(
                enabled: c.isEditable,
                labelText: 'Levantamentos de campo',
                controller: c.etpLevantamentosCampoCtrl,
                items: const ['Sim','Não','Parcial','N/A'],
              ),
            ),
            SizedBox(
              width: _w(context, 2),
              child: DropDownButtonChange(
                enabled: c.isEditable,
                labelText: 'Projeto básico/executivo existente?',
                controller: c.etpProjetoExistenteCtrl,
                items: const ['Sim','Não','Parcial','N/A'],
              ),
            ),
            SizedBox(
              width: _w(context, 1),
              child: CustomTextField(
                controller: c.etpLinksEvidenciasCtrl,
                enabled: c.isEditable,
                labelText: 'Links/Evidências (SEI, Storage, etc.)',
                maxLines: 2,
              ),
            ),
            SizedBox(
              width: _w(context, 1),
              child: CustomTextField(
                controller: c.etpEquipeEnvolvidaCtrl,
                enabled: c.isEditable,
                labelText: 'Equipe envolvida (nomes/cargos)',
                maxLines: 2,
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
