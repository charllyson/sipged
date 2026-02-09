// lib/screens/modules/contracts/hiring/1Dfd/section_5_riscos.dart
import 'package:flutter/material.dart';

import 'package:siged/_blocs/modules/contracts/hiring/1Dfd/dfd_data.dart';
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

class _SectionRiscosState extends State<SectionRiscos> {
  late final TextEditingController _riscosCtrl;
  late final TextEditingController _impactoCtrl;
  late final TextEditingController _dataLimiteCtrl;
  late final TextEditingController _motivacaoLegalCtrl;
  late final TextEditingController _amparoNormativoCtrl;

  late final TextEditingController _prioridadeCtrl; // ✅ fix: não cria no build
  String? _prioridade;

  @override
  void initState() {
    super.initState();
    final d = widget.data;

    _riscosCtrl = TextEditingController(text: d.riscos ?? '');
    _impactoCtrl = TextEditingController(text: d.impactoNaoContratar ?? '');
    _dataLimiteCtrl = TextEditingController(text: _formatDate(d.dataLimite));
    _motivacaoLegalCtrl = TextEditingController(text: d.motivacaoLegal ?? '');
    _amparoNormativoCtrl = TextEditingController(text: d.amparoNormativo ?? '');

    _prioridade = d.prioridade;
    _prioridadeCtrl = TextEditingController(text: _prioridade ?? '');
  }

  @override
  void didUpdateWidget(covariant SectionRiscos oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data == widget.data) return;

    final d = widget.data;

    _sync(_riscosCtrl, d.riscos);
    _sync(_impactoCtrl, d.impactoNaoContratar);
    _sync(_dataLimiteCtrl, _formatDate(d.dataLimite));
    _sync(_motivacaoLegalCtrl, d.motivacaoLegal);
    _sync(_amparoNormativoCtrl, d.amparoNormativo);

    _prioridade = d.prioridade;
    _sync(_prioridadeCtrl, _prioridade);
  }

  void _sync(TextEditingController c, String? newText) {
    final v = newText ?? '';
    if (c.text != v) c.text = v;
  }

  @override
  void dispose() {
    _riscosCtrl.dispose();
    _impactoCtrl.dispose();
    _dataLimiteCtrl.dispose();
    _motivacaoLegalCtrl.dispose();
    _amparoNormativoCtrl.dispose();
    _prioridadeCtrl.dispose();
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
    widget.onChanged(
      widget.data.copyWith(
        riscos: _riscosCtrl.text,
        impactoNaoContratar: _impactoCtrl.text,
        prioridade: _prioridade ?? '',
        dataLimite: _parseBrDate(_dataLimiteCtrl.text),
        motivacaoLegal: _motivacaoLegalCtrl.text,
        amparoNormativo: _amparoNormativoCtrl.text,
      ),
    );
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
                SizedBox(
                  width: w4,
                  child: DropDownButtonChange(
                    enabled: widget.isEditable,
                    labelText: 'Prioridade',
                    controller: _prioridadeCtrl,
                    items: const ['Baixa', 'Média', 'Alta', 'Crítica'],
                    onChanged: (v) {
                      _prioridade = (v ?? '').trim();
                      _prioridadeCtrl.text = _prioridade ?? '';
                      _emitChange();
                      setState(() {});
                    },
                    validator: null,
                  ),
                ),
                SizedBox(
                  width: w4,
                  child: CustomDateField(
                    controller: _dataLimiteCtrl,
                    enabled: widget.isEditable,
                    labelText: 'Data limite/urgência (se houver)',
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: _motivacaoLegalCtrl,
                    enabled: widget.isEditable,
                    labelText: 'Motivação legal (ex.: decisão judicial)',
                    onChanged: (_) => _emitChange(),
                  ),
                ),
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
