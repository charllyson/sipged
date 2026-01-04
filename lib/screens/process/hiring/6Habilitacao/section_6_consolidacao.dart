import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:siged/_blocs/process/hiring/0Stages/hiring_data.dart';
import 'package:siged/_widgets/input/custom_date_field.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_utils/formats/mask_class.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';

import 'package:siged/_blocs/process/hiring/6Habilitacao/habilitacao_data.dart';

class SectionConsolidacao extends StatefulWidget with FormValidationMixin {
  final HabilitacaoData data;
  final bool isEditable;
  final void Function(HabilitacaoData updated) onChanged;

  SectionConsolidacao({
    super.key,
    required this.data,
    required this.isEditable,
    required this.onChanged,
  });

  @override
  State<SectionConsolidacao> createState() => _SectionConsolidacaoState();
}

class _SectionConsolidacaoState extends State<SectionConsolidacao> {
  late final TextEditingController _situacaoCtrl;
  late final TextEditingController _dataConclusaoCtrl;
  late final TextEditingController _parecerCtrl;

  @override
  void initState() {
    super.initState();
    final d = widget.data;

    _situacaoCtrl =
        TextEditingController(text: d.situacaoHabilitacao ?? '');
    _dataConclusaoCtrl =
        TextEditingController(text: d.dataConclusao ?? '');
    _parecerCtrl =
        TextEditingController(text: d.parecerConclusivo ?? '');
  }

  @override
  void didUpdateWidget(covariant SectionConsolidacao oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      final d = widget.data;

      void _sync(TextEditingController c, String? v) {
        final text = v ?? '';
        if (c.text != text) c.text = text;
      }

      _sync(_situacaoCtrl, d.situacaoHabilitacao);
      _sync(_dataConclusaoCtrl, d.dataConclusao);
      _sync(_parecerCtrl, d.parecerConclusivo);
    }
  }

  @override
  void dispose() {
    _situacaoCtrl.dispose();
    _dataConclusaoCtrl.dispose();
    _parecerCtrl.dispose();
    super.dispose();
  }

  void _emitChange() {
    final updated = widget.data.copyWith(
      situacaoHabilitacao: _situacaoCtrl.text,
      dataConclusao: _dataConclusaoCtrl.text,
      parecerConclusivo: _parecerCtrl.text,
    );
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w3 = inputW3(context, constraints);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(text: '6) Consolidação e Parecer do Gestor'),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w3,
                  child: DropDownButtonChange(
                    enabled: widget.isEditable,
                    labelText: 'Situação da habilitação',
                    controller: _situacaoCtrl,
                    items: HiringData.situacaoHabilitacao,
                    onChanged: (v) {
                      _situacaoCtrl.text = v ?? '';
                      _emitChange();
                    },
                    validator: widget.validateRequired,
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: CustomDateField(
                    controller: _dataConclusaoCtrl,
                    labelText: 'Data da conclusão',
                    enabled: widget.isEditable,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(8),
                      TextInputMask(mask: '99/99/9999'),
                    ],
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: _parecerCtrl,
                    labelText: 'Parecer conclusivo do gestor',
                    maxLines: 1,
                    enabled: widget.isEditable,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }
}
