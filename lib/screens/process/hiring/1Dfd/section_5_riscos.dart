// lib/screens/process/hiring/1Dfd/dfd_sections/section_5_riscos.dart
import 'package:flutter/material.dart';

import 'package:siged/_blocs/process/hiring/1Dfd/dfd_data.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';

import 'package:siged/_widgets/input/custom_date_field.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';

class SectionRiscos extends StatefulWidget {
  final bool isEditable;
  final DfdData data;
  final void Function(DfdData updated) onChanged;

  const SectionRiscos({
    super.key,
    required this.isEditable,
    required this.data,
    required this.onChanged,
  });

  @override
  State<SectionRiscos> createState() => _SectionRiscosState();
}

class _SectionRiscosState extends State<SectionRiscos>
    with FormValidationMixin {
  late final TextEditingController _riscosCtrl;
  late final TextEditingController _impactoCtrl;
  late final TextEditingController _dataLimiteCtrl;
  late final TextEditingController _motivacaoLegalCtrl;
  late final TextEditingController _amparoNormativoCtrl;

  String? _prioridade;

  @override
  void initState() {
    super.initState();
    final d = widget.data;

    _riscosCtrl          = TextEditingController(text: d.riscos);
    _impactoCtrl         =
        TextEditingController(text: d.impactoNaoContratar);
    _dataLimiteCtrl      = TextEditingController(text: d.dataLimite);
    _motivacaoLegalCtrl  =
        TextEditingController(text: d.motivacaoLegal);
    _amparoNormativoCtrl =
        TextEditingController(text: d.amparoNormativo);

    _prioridade = d.prioridade;
  }

  @override
  void didUpdateWidget(covariant SectionRiscos oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      final d = widget.data;
      _riscosCtrl.text          = d.riscos;
      _impactoCtrl.text         = d.impactoNaoContratar;
      _dataLimiteCtrl.text      = d.dataLimite;
      _motivacaoLegalCtrl.text  = d.motivacaoLegal;
      _amparoNormativoCtrl.text = d.amparoNormativo;
      _prioridade               = d.prioridade;
    }
  }

  @override
  void dispose() {
    _riscosCtrl.dispose();
    _impactoCtrl.dispose();
    _dataLimiteCtrl.dispose();
    _motivacaoLegalCtrl.dispose();
    _amparoNormativoCtrl.dispose();
    super.dispose();
  }

  void _emitChange() {
    final updated = widget.data.copyWith(
      riscos:             _riscosCtrl.text,
      impactoNaoContratar: _impactoCtrl.text,
      prioridade:         _prioridade ?? '',
      dataLimite:         _dataLimiteCtrl.text,
      motivacaoLegal:     _motivacaoLegalCtrl.text,
      amparoNormativo:    _amparoNormativoCtrl.text,
    );
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('5) Riscos e Impacto'),
        LayoutBuilder(
          builder: (context, inner) {
            final w2 = inputW2(context, inner);
            final w4 = inputW4(context, inner);

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                // Riscos principais
                SizedBox(
                  width: w2,
                  child: CustomTextField(
                    controller: _riscosCtrl,
                    enabled: widget.isEditable,
                    labelText: 'Riscos principais',
                    maxLines: 3,
                    onChanged: (_) => _emitChange(),
                  ),
                ),

                // Impacto se não contratar
                SizedBox(
                  width: w2,
                  child: CustomTextField(
                    controller: _impactoCtrl,
                    enabled: widget.isEditable,
                    labelText: 'Impacto se não contratar',
                    maxLines: 3,
                    onChanged: (_) => _emitChange(),
                  ),
                ),

                // Prioridade
                SizedBox(
                  width: w4,
                  child: DropDownButtonChange(
                    enabled: widget.isEditable,
                    labelText: 'Prioridade',
                    controller: TextEditingController(
                      text: _prioridade ?? '',
                    ),
                    items: const ['Baixa', 'Média', 'Alta', 'Crítica'],
                    onChanged: (v) {
                      _prioridade = v ?? '';
                      _emitChange();
                      setState(() {});
                    },
                    validator: validateRequired,
                  ),
                ),

                // Data limite / urgência
                SizedBox(
                  width: w4,
                  child: CustomDateField(
                    controller: _dataLimiteCtrl,
                    enabled: widget.isEditable,
                    labelText: 'Data limite/urgência (se houver)',
                    onChanged: (_) => _emitChange(),
                  ),
                ),

                // Motivação legal
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: _motivacaoLegalCtrl,
                    enabled: widget.isEditable,
                    labelText: 'Motivação legal (ex.: decisão judicial)',
                    onChanged: (_) => _emitChange(),
                  ),
                ),

                // Amparo normativo
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: _amparoNormativoCtrl,
                    enabled: widget.isEditable,
                    labelText: 'Amparo normativo (lei/artigo)',
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
