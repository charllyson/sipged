import 'package:flutter/material.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart' show DropDownButtonChange;
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_blocs/process/hiring/11Arquivamento/termo_arquivamento_controller.dart';

class SectionMotivoAbrangenciaTA extends StatefulWidget {
  final TermoArquivamentoController controller;
  const SectionMotivoAbrangenciaTA({super.key, required this.controller});

  @override
  State<SectionMotivoAbrangenciaTA> createState() => _SectionMotivoAbrangenciaTAState();
}

class _SectionMotivoAbrangenciaTAState extends State<SectionMotivoAbrangenciaTA>
    with FormValidationMixin {
  double _w(BuildContext ctx, {int itemsPerLine = 4}) => responsiveInputWidth(
    context: ctx, itemsPerLine: itemsPerLine, spacing: 12, margin: 12, extraPadding: 24,
  );

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionTitle('2) Motivo e Abrangência'),
      Wrap(spacing: 12, runSpacing: 12, children: [
        SizedBox(
          width: _w(context),
          child: DropDownButtonChange(
            enabled: c.isEditable,
            labelText: 'Motivo do arquivamento',
            controller: c.taMotivoCtrl,
            items: const [
              'Concluído com êxito (objeto atendido)',
              'Desistência/Perda de objeto',
              'Fracasso/Deserto',
              'Inviabilidade técnica/econômica',
              'Determinação superior',
              'Outros'
            ],
            onChanged: (v) => setState(() => c.taMotivoCtrl.text = v ?? ''),
            validator: validateRequired,
          ),
        ),
        SizedBox(
          width: _w(context),
          child: DropDownButtonChange(
            enabled: c.isEditable,
            labelText: 'Abrangência',
            controller: c.taAbrangenciaCtrl,
            items: const ['Total', 'Parcial (lotes/itens)'],
            onChanged: (v) => setState(() => c.taAbrangenciaCtrl.text = v ?? ''),
          ),
        ),
        SizedBox(
          width: _w(context, itemsPerLine: 1),
          child: CustomTextField(
            controller: c.taDescricaoAbrangenciaCtrl,
            labelText: 'Descrição da abrangência (lotes/itens atingidos)',
            maxLines: 2,
            enabled: c.isEditable,
          ),
        ),
      ]),
      const SizedBox(height: 16),
    ]);
  }
}
