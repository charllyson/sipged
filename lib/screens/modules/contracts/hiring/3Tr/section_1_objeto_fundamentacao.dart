// lib/screens/modules/contracts/hiring/3Tr/section_1_objeto_fundamentacao.dart

import 'package:flutter/material.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/hiring_data.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/3Tr/tr_data.dart';

import 'package:sipged/_widgets/input/custom_text_field.dart';
import 'package:sipged/_widgets/input/drop_down_botton_change.dart';
import 'package:sipged/_widgets/texts/section_text_name.dart';
import 'package:sipged/_widgets/layout/responsive_utils.dart';
import 'package:sipged/_utils/validates/sipged_validation.dart';

class SectionObjetoFundamentacao extends StatefulWidget {
  final bool isEditable;
  final TrData data;

  /// Chamado sempre que algum campo da seção é alterado.
  final void Function(TrData updated) onChanged;

  const SectionObjetoFundamentacao({
    super.key,
    required this.data,
    required this.isEditable,
    required this.onChanged,
  });

  @override
  State<SectionObjetoFundamentacao> createState() =>
      _SectionObjetoFundamentacaoState();
}

class _SectionObjetoFundamentacaoState
    extends State<SectionObjetoFundamentacao>
    with SipGedValidation {
  // Controllers internos (não expostos, padrão Dfd)
  late final TextEditingController _tipoContratacaoCtrl;
  late final TextEditingController _regimeExecucaoCtrl;
  late final TextEditingController _objetoCtrl;
  late final TextEditingController _justificativaCtrl;

  @override
  void initState() {
    super.initState();
    final d = widget.data;

    _tipoContratacaoCtrl =
        TextEditingController(text: d.tipoContratacao ?? '');
    _regimeExecucaoCtrl =
        TextEditingController(text: d.regimeExecucao ?? '');
    _objetoCtrl = TextEditingController(text: d.objeto ?? '');
    _justificativaCtrl =
        TextEditingController(text: d.justificativa ?? '');
  }

  @override
  void didUpdateWidget(covariant SectionObjetoFundamentacao oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      final d = widget.data;

      void sync(TextEditingController c, String? newText) {
        final v = newText ?? '';
        if (c.text != v) {
          c.text = v;
        }
      }

      sync(_tipoContratacaoCtrl, d.tipoContratacao);
      sync(_regimeExecucaoCtrl, d.regimeExecucao);
      sync(_objetoCtrl, d.objeto);
      sync(_justificativaCtrl, d.justificativa);
    }
  }

  @override
  void dispose() {
    _tipoContratacaoCtrl.dispose();
    _regimeExecucaoCtrl.dispose();
    _objetoCtrl.dispose();
    _justificativaCtrl.dispose();
    super.dispose();
  }

  void _emitChange() {
    final updated = widget.data.copyWith(
      tipoContratacao: _tipoContratacaoCtrl.text,
      regimeExecucao: _regimeExecucaoCtrl.text,
      objeto: _objetoCtrl.text,
      justificativa: _justificativaCtrl.text,
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
            const SectionTitle(text: '1) Objeto e Fundamentação'),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                // Coluna com os dois dropdowns
                SizedBox(
                  width: w3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: w3,
                        child: DropDownButtonChange(
                          enabled: widget.isEditable,
                          labelText: 'Tipo de contratação',
                          controller: _tipoContratacaoCtrl,
                          items: HiringData.tiposDeContratacao,
                          validator: validateRequired,
                          onChanged: (v) {
                            _tipoContratacaoCtrl.text = v ?? '';
                            _emitChange();
                            setState(() {});
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: w3,
                        child: DropDownButtonChange(
                          enabled: widget.isEditable,
                          labelText: 'Regime de execução',
                          controller: _regimeExecucaoCtrl,
                          items: HiringData.regimeDeExecucao,
                          validator: validateRequired,
                          onChanged: (v) {
                            _regimeExecucaoCtrl.text = v ?? '';
                            _emitChange();
                            setState(() {});
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Objeto
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: _objetoCtrl,
                    labelText: 'Objeto do Termo de Referência',
                    maxLines: 4,
                    enabled: widget.isEditable,
                    validator: validateRequired,
                    onChanged: (_) => _emitChange(),
                  ),
                ),

                // Justificativa
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: _justificativaCtrl,
                    labelText: 'Justificativa Técnica',
                    maxLines: 4,
                    enabled: widget.isEditable,
                    validator: validateRequired,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
