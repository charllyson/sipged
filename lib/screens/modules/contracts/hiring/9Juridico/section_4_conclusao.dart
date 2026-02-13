// lib/screens/modules/contracts/hiring/9Juridico/section_4_conclusao.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/hiring_data.dart';
import 'package:sipged/_utils/mask/sipged_masks.dart';
import 'package:sipged/_widgets/input/custom_date_field.dart';
import 'package:sipged/_widgets/layout/responsive_utils.dart';
import 'package:sipged/_widgets/input/custom_text_field.dart';
import 'package:sipged/_widgets/input/drop_down_botton_change.dart'
    show DropDownButtonChange;
import 'package:sipged/_widgets/texts/section_text_name.dart';
import 'package:sipged/_utils/validates/sipged_validation.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/9Juridico/parecer_juridico_data.dart';

class SectionConclusao extends StatefulWidget {
  final ParecerJuridicoData data;
  final bool isEditable;
  final void Function(ParecerJuridicoData updated) onChanged;

  const SectionConclusao({
    super.key,
    required this.data,
    required this.isEditable,
    required this.onChanged,
  });

  @override
  State<SectionConclusao> createState() => _SectionConclusaoState();
}

class _SectionConclusaoState extends State<SectionConclusao>
    with SipGedValidation {
  late final TextEditingController _conclusaoCtrl;
  late final TextEditingController _dataAssinaturaCtrl;
  late final TextEditingController _recomendacoesCtrl;
  late final TextEditingController _ajustesObrigatoriosCtrl;

  @override
  void initState() {
    super.initState();
    _conclusaoCtrl =
        TextEditingController(text: widget.data.conclusao ?? '');
    _dataAssinaturaCtrl =
        TextEditingController(text: widget.data.dataAssinatura ?? '');
    _recomendacoesCtrl =
        TextEditingController(text: widget.data.recomendacoes ?? '');
    _ajustesObrigatoriosCtrl =
        TextEditingController(text: widget.data.ajustesObrigatorios ?? '');
  }

  @override
  void didUpdateWidget(covariant SectionConclusao oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _conclusaoCtrl.text = widget.data.conclusao ?? '';
      _dataAssinaturaCtrl.text = widget.data.dataAssinatura ?? '';
      _recomendacoesCtrl.text = widget.data.recomendacoes ?? '';
      _ajustesObrigatoriosCtrl.text =
          widget.data.ajustesObrigatorios ?? '';
    }
  }

  @override
  void dispose() {
    _conclusaoCtrl.dispose();
    _dataAssinaturaCtrl.dispose();
    _recomendacoesCtrl.dispose();
    _ajustesObrigatoriosCtrl.dispose();
    super.dispose();
  }

  void _emitChange() {
    final updated = widget.data.copyWith(
      conclusao: _conclusaoCtrl.text,
      dataAssinatura: _dataAssinaturaCtrl.text,
      recomendacoes: _recomendacoesCtrl.text,
      ajustesObrigatorios: _ajustesObrigatoriosCtrl.text,
    );
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final conclusoes = HiringData.parecerConclusao;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(text: '4) Conclusão do Parecer'),
        LayoutBuilder(
          builder: (context, constraints) {
            final w4 = inputW4(context, constraints);
            final w1 = inputW1(context, constraints);

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w4,
                  child: DropDownButtonChange(
                    enabled: widget.isEditable,
                    labelText: 'Conclusão',
                    controller: _conclusaoCtrl,
                    items: conclusoes,
                    onChanged: (v) {
                      _conclusaoCtrl.text = v ?? '';
                      _emitChange();
                    },
                  ),
                ),
                SizedBox(
                  width: w4,
                  child: CustomDateField(
                    controller: _dataAssinaturaCtrl,
                    labelText: 'Data da assinatura do parecer',
                    enabled: widget.isEditable,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(8),
                      SipGedMasks.dateDDMMYYYY,
                    ],
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w1,
                  child: CustomTextField(
                    controller: _recomendacoesCtrl,
                    labelText: 'Recomendações e/ou condicionantes',
                    maxLines: 3,
                    enabled: widget.isEditable,
                    textAlignVertical: TextAlignVertical.top,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w1,
                  child: CustomTextField(
                    controller: _ajustesObrigatoriosCtrl,
                    labelText: 'Ajustes obrigatórios na minuta/edital',
                    maxLines: 3,
                    enabled: widget.isEditable,
                    textAlignVertical: TextAlignVertical.top,
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
