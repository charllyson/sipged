import 'package:flutter/material.dart';
import 'package:siged/_blocs/process/hiring/0Stages/hiring_data.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart'
    show DropDownButtonChange;
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_blocs/process/hiring/11Arquivamento/termo_arquivamento_controller.dart';

class SectionMotivoAbrangenciaTA extends StatefulWidget {
  final TermoArquivamentoController controller;
  const SectionMotivoAbrangenciaTA({super.key, required this.controller});

  @override
  State<SectionMotivoAbrangenciaTA> createState() =>
      _SectionMotivoAbrangenciaTAState();
}

class _SectionMotivoAbrangenciaTAState
    extends State<SectionMotivoAbrangenciaTA> with FormValidationMixin {
  @override
  Widget build(BuildContext context) {
    final c = widget.controller;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('2) Motivo e Abrangência'),
        LayoutBuilder(
          builder: (context, constraints) {
            final w3 = inputW3(context, constraints);

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w3,
                  child: DropDownButtonChange(
                    enabled: c.isEditable,
                    labelText: 'Motivo do arquivamento',
                    controller: c.taMotivoCtrl,
                    items: HiringData.motivoArquivamento,
                    onChanged: (v) =>
                        setState(() => c.taMotivoCtrl.text = v ?? ''),
                    validator: validateRequired,
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: DropDownButtonChange(
                    enabled: c.isEditable,
                    labelText: 'Abrangência',
                    controller: c.taAbrangenciaCtrl,
                    items: HiringData.abrangencia,
                    onChanged: (v) =>
                        setState(() => c.taAbrangenciaCtrl.text = v ?? ''),
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: c.taDescricaoAbrangenciaCtrl,
                    labelText:
                    'Descrição da abrangência (lotes/itens atingidos)',
                    enabled: c.isEditable,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
