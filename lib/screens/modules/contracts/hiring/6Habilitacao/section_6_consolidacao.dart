import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/hiring_data.dart';
import 'package:sipged/_utils/mask/sipged_masks.dart';
import 'package:sipged/_widgets/input/date_field_change.dart';
import 'package:sipged/_widgets/input/text_field_change.dart';
import 'package:sipged/_widgets/input/drop_down_change.dart';
import 'package:sipged/_widgets/texts/section_text_name.dart';
import 'package:sipged/_widgets/layout/responsive_utils.dart';
import 'package:sipged/_utils/validates/sipged_validation.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/6Habilitacao/habilitacao_data.dart';

class SectionConsolidation extends StatefulWidget with SipGedValidation {
  final HabilitacaoData data;
  final bool isEditable;
  final void Function(HabilitacaoData updated) onChanged;

  SectionConsolidation({
    super.key,
    required this.data,
    required this.isEditable,
    required this.onChanged,
  });

  @override
  State<SectionConsolidation> createState() => _SectionConsolidationState();
}

class _SectionConsolidationState extends State<SectionConsolidation> {
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
  void didUpdateWidget(covariant SectionConsolidation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      final d = widget.data;

      void sync(TextEditingController c, String? v) {
        final text = v ?? '';
        if (c.text != text) c.text = text;
      }

      sync(_situacaoCtrl, d.situacaoHabilitacao);
      sync(_dataConclusaoCtrl, d.dataConclusao);
      sync(_parecerCtrl, d.parecerConclusivo);
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
                  child: DropDownChange(
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
                  child: DateFieldChange(
                    controller: _dataConclusaoCtrl,
                    labelText: 'Data da conclusão',
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
