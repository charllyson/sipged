import 'package:flutter/material.dart';

import 'package:siged/_blocs/modules/contracts/hiring/1Dfd/dfd_data.dart';
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

    _riscosCtrl = TextEditingController(text: d.riscos ?? '');
    _impactoCtrl =
        TextEditingController(text: d.impactoNaoContratar ?? '');
    _dataLimiteCtrl =
        TextEditingController(text: _formatDate(d.dataLimite));
    _motivacaoLegalCtrl =
        TextEditingController(text: d.motivacaoLegal ?? '');
    _amparoNormativoCtrl =
        TextEditingController(text: d.amparoNormativo ?? '');

    _prioridade = d.prioridade;
  }

  @override
  void didUpdateWidget(covariant SectionRiscos oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      final d = widget.data;

      final riscos = d.riscos ?? '';
      final impacto = d.impactoNaoContratar ?? '';
      final dataLim = _formatDate(d.dataLimite);
      final mot = d.motivacaoLegal ?? '';
      final amp = d.amparoNormativo ?? '';

      if (_riscosCtrl.text != riscos) _riscosCtrl.text = riscos;
      if (_impactoCtrl.text != impacto) _impactoCtrl.text = impacto;
      if (_dataLimiteCtrl.text != dataLim) _dataLimiteCtrl.text = dataLim;
      if (_motivacaoLegalCtrl.text != mot) _motivacaoLegalCtrl.text = mot;
      if (_amparoNormativoCtrl.text != amp) _amparoNormativoCtrl.text = amp;

      _prioridade = d.prioridade;
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

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString().padLeft(4, '0');
    return '$d/$m/$y';
  }

  DateTime? _parseBrDate(String text) {
    final t = text.trim();
    if (t.isEmpty) return null;
    try {
      final parts = t.split('/');
      if (parts.length == 3) {
        final d = int.parse(parts[0]);
        final m = int.parse(parts[1]);
        final y = int.parse(parts[2]);
        return DateTime(y, m, d);
      }
      return DateTime.parse(t);
    } catch (_) {
      return null;
    }
  }

  void _emitChange() {
    final updated = widget.data.copyWith(
      riscos: _riscosCtrl.text,
      impactoNaoContratar: _impactoCtrl.text,
      prioridade: _prioridade ?? '',
      dataLimite: _parseBrDate(_dataLimiteCtrl.text),
      motivacaoLegal: _motivacaoLegalCtrl.text,
      amparoNormativo: _amparoNormativoCtrl.text,
    );
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(text: '5) Riscos e Impacto'),
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
                    validator: null,
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
