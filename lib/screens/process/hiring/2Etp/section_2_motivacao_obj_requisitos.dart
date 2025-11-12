import 'package:flutter/material.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';
import 'package:siged/_blocs/process/hiring/2Etp/etp_controller.dart';

class SectionMotivacaoObjRequisitos extends StatelessWidget with FormValidationMixin {
  final EtpController controller;
  SectionMotivacaoObjRequisitos({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Title('2) Motivação, objetivos e requisitos'),
        Wrap(
          spacing: 12, runSpacing: 12,
          children: [
            SizedBox(
              width: _w(context, 1),
              child: CustomTextField(
                controller: c.etpMotivacaoCtrl,
                enabled: c.isEditable,
                labelText: 'Motivação / Problema',
                validator: validateRequired,
                maxLines: 3,
              ),
            ),
            SizedBox(
              width: _w(context, 1),
              child: CustomTextField(
                controller: c.etpObjetivosCtrl,
                enabled: c.isEditable,
                labelText: 'Objetivos',
                validator: validateRequired,
                maxLines: 3,
              ),
            ),
            SizedBox(
              width: _w(context, 1),
              child: CustomTextField(
                controller: c.etpRequisitosMinimosCtrl,
                enabled: c.isEditable,
                labelText: 'Requisitos mínimos / escopo preliminar',
                maxLines: 4,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  double _w(BuildContext ctx, int items) =>
      MediaQuery.of(ctx).size.width >= 1200 ? (MediaQuery.of(ctx).size.width - 64) / items : 720;
}

class _Title extends StatelessWidget {
  final String text;
  const _Title(this.text);
  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: Theme.of(context).textTheme.titleMedium));
}
