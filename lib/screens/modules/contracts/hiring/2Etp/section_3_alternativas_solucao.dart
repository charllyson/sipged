// lib/screens/modules/contracts/hiring/2Etp/section_3_alternativas_solucao.dart
import 'package:flutter/material.dart';
import 'package:siged/_blocs/modules/contracts/hiring/0Stages/hiring_data.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart'
    show DropDownButtonChange;
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';
import 'package:siged/_blocs/modules/contracts/hiring/2Etp/etp_data.dart';

class SectionAlternativasSolucao extends StatefulWidget
    with FormValidationMixin {
  final EtpData data;
  final bool isEditable;
  final void Function(EtpData updated) onChanged;

  SectionAlternativasSolucao({
    super.key,
    required this.data,
    required this.isEditable,
    required this.onChanged,
  });

  @override
  State<SectionAlternativasSolucao> createState() =>
      _SectionAlternativasSolucaoState();
}

class _SectionAlternativasSolucaoState
    extends State<SectionAlternativasSolucao> {
  late final TextEditingController _solucaoCtrl;
  late final TextEditingController _complexidadeCtrl;
  late final TextEditingController _nivelRiscoCtrl;
  late final TextEditingController _justificativaCtrl;

  @override
  void initState() {
    super.initState();
    final d = widget.data;
    _solucaoCtrl = TextEditingController(text: d.solucaoRecomendada ?? '');
    _complexidadeCtrl = TextEditingController(text: d.complexidade ?? '');
    _nivelRiscoCtrl = TextEditingController(text: d.nivelRisco ?? '');
    _justificativaCtrl =
        TextEditingController(text: d.justificativaSolucao ?? '');
  }

  @override
  void didUpdateWidget(
      covariant SectionAlternativasSolucao oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      void _sync(TextEditingController c, String? v) {
        final s = v ?? '';
        if (c.text != s) c.text = s;
      }

      final d = widget.data;
      _sync(_solucaoCtrl, d.solucaoRecomendada);
      _sync(_complexidadeCtrl, d.complexidade);
      _sync(_nivelRiscoCtrl, d.nivelRisco);
      _sync(_justificativaCtrl, d.justificativaSolucao);
    }
  }

  @override
  void dispose() {
    _solucaoCtrl.dispose();
    _complexidadeCtrl.dispose();
    _nivelRiscoCtrl.dispose();
    _justificativaCtrl.dispose();
    super.dispose();
  }

  void _emitChange() {
    widget.onChanged(
      widget.data.copyWith(
        solucaoRecomendada: _solucaoCtrl.text,
        complexidade: _complexidadeCtrl.text,
        nivelRisco: _nivelRiscoCtrl.text,
        justificativaSolucao: _justificativaCtrl.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w3 = inputW3(context, constraints);
        final w1 = inputW1(context, constraints);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(text: '3) Alternativas e solução recomendada'),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w3,
                  child: DropDownButtonChange(
                    enabled: widget.isEditable,
                    labelText: 'Solução recomendada',
                    controller: _solucaoCtrl,
                    items: HiringData.tiposDeContratacao,
                    validator: widget.validateRequired,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: DropDownButtonChange(
                    enabled: widget.isEditable,
                    labelText: 'Complexidade',
                    controller: _complexidadeCtrl,
                    items: HiringData.complexibilidade,
                    validator: widget.validateRequired,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: DropDownButtonChange(
                    enabled: widget.isEditable,
                    labelText: 'Risco preliminar',
                    controller: _nivelRiscoCtrl,
                    items: HiringData.complexibilidade,
                    validator: widget.validateRequired,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w1,
                  child: CustomTextField(
                    controller: _justificativaCtrl,
                    enabled: widget.isEditable,
                    labelText: 'Justificativa da solução',
                    validator: widget.validateRequired,
                    maxLines: 3,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}
