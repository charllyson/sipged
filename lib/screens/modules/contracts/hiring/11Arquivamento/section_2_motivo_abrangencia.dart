// lib/screens/modules/contracts/hiring/11Arquivamento/section_2_motivo_abrangencia.dart
import 'package:flutter/material.dart';

import 'package:siged/_blocs/modules/contracts/hiring/0Stages/hiring_data.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart'
    show DropDownButtonChange;
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';

import 'package:siged/_blocs/modules/contracts/hiring/11Arquivamento/termo_arquivamento_data.dart';

class SectionMotivoAbrangenciaTA extends StatefulWidget {
  final TermoArquivamentoData data;
  final bool isEditable;
  final void Function(TermoArquivamentoData updated) onChanged;

  const SectionMotivoAbrangenciaTA({
    super.key,
    required this.data,
    required this.isEditable,
    required this.onChanged,
  });

  @override
  State<SectionMotivoAbrangenciaTA> createState() =>
      _SectionMotivoAbrangenciaTAState();
}

class _SectionMotivoAbrangenciaTAState
    extends State<SectionMotivoAbrangenciaTA> with FormValidationMixin {
  late final TextEditingController _motivoCtrl;
  late final TextEditingController _abrangenciaCtrl;
  late final TextEditingController _descricaoAbrangenciaCtrl;

  @override
  void initState() {
    super.initState();
    final d = widget.data;

    _motivoCtrl =
        TextEditingController(text: d.taMotivo ?? '');
    _abrangenciaCtrl =
        TextEditingController(text: d.taAbrangencia ?? '');
    _descricaoAbrangenciaCtrl =
        TextEditingController(text: d.taDescricaoAbrangencia ?? '');
  }

  @override
  void didUpdateWidget(covariant SectionMotivoAbrangenciaTA oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      final d = widget.data;

      void _sync(TextEditingController c, String? v) {
        final text = v ?? '';
        if (c.text != text) c.text = text;
      }

      _sync(_motivoCtrl, d.taMotivo);
      _sync(_abrangenciaCtrl, d.taAbrangencia);
      _sync(_descricaoAbrangenciaCtrl, d.taDescricaoAbrangencia);
    }
  }

  @override
  void dispose() {
    _motivoCtrl.dispose();
    _abrangenciaCtrl.dispose();
    _descricaoAbrangenciaCtrl.dispose();
    super.dispose();
  }

  void _emitChange() {
    final updated = widget.data.copyWith(
      taMotivo: _motivoCtrl.text,
      taAbrangencia: _abrangenciaCtrl.text,
      taDescricaoAbrangencia: _descricaoAbrangenciaCtrl.text,
    );
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(text: '2) Motivo e Abrangência'),
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
                    enabled: widget.isEditable,
                    labelText: 'Motivo do arquivamento',
                    controller: _motivoCtrl,
                    items: HiringData.motivoArquivamento,
                    onChanged: (v) {
                      _motivoCtrl.text = v ?? '';
                      _emitChange();
                    },
                    validator: validateRequired,
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: DropDownButtonChange(
                    enabled: widget.isEditable,
                    labelText: 'Abrangência',
                    controller: _abrangenciaCtrl,
                    items: HiringData.abrangencia,
                    onChanged: (v) {
                      _abrangenciaCtrl.text = v ?? '';
                      _emitChange();
                    },
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: _descricaoAbrangenciaCtrl,
                    labelText:
                    'Descrição da abrangência (lotes/itens atingidos)',
                    enabled: widget.isEditable,
                    onChanged: (_) => _emitChange(),
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
