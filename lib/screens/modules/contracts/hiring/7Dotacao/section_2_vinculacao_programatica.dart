import 'package:flutter/material.dart';

import 'package:siged/_blocs/modules/contracts/hiring/0Stages/hiring_data.dart';

import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';

import 'package:siged/_blocs/modules/contracts/hiring/7Dotacao/dotacao_data.dart';

class SectionVinculacaoProgramatica extends StatefulWidget {
  final DotacaoData data;
  final bool isEditable;
  final void Function(DotacaoData updated) onChanged;

  const SectionVinculacaoProgramatica({
    super.key,
    required this.data,
    required this.isEditable,
    required this.onChanged,
  });

  @override
  State<SectionVinculacaoProgramatica> createState() =>
      _SectionVinculacaoProgramaticaState();
}

class _SectionVinculacaoProgramaticaState
    extends State<SectionVinculacaoProgramatica> {
  late final TextEditingController _fonteRecursoCtrl;
  late final TextEditingController _uoCtrl;
  late final TextEditingController _ugCtrl;
  late final TextEditingController _programaCtrl;
  late final TextEditingController _acaoCtrl;
  late final TextEditingController _ptresCtrl;
  late final TextEditingController _planoOrcCtrl;

  @override
  void initState() {
    super.initState();
    final d = widget.data;

    _fonteRecursoCtrl =
        TextEditingController(text: d.fonteRecurso ?? '');
    _uoCtrl = TextEditingController(text: d.uo ?? '');
    _ugCtrl = TextEditingController(text: d.ug ?? '');
    _programaCtrl = TextEditingController(text: d.programa ?? '');
    _acaoCtrl = TextEditingController(text: d.acao ?? '');
    _ptresCtrl = TextEditingController(text: d.ptres ?? '');
    _planoOrcCtrl =
        TextEditingController(text: d.planoOrc ?? '');
  }

  @override
  void didUpdateWidget(
      covariant SectionVinculacaoProgramatica oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      final d = widget.data;

      void sync(TextEditingController c, String? v) {
        final text = v ?? '';
        if (c.text != text) c.text = text;
      }

      sync(_fonteRecursoCtrl, d.fonteRecurso);
      sync(_uoCtrl, d.uo);
      sync(_ugCtrl, d.ug);
      sync(_programaCtrl, d.programa);
      sync(_acaoCtrl, d.acao);
      sync(_ptresCtrl, d.ptres);
      sync(_planoOrcCtrl, d.planoOrc);
    }
  }

  @override
  void dispose() {
    _fonteRecursoCtrl.dispose();
    _uoCtrl.dispose();
    _ugCtrl.dispose();
    _programaCtrl.dispose();
    _acaoCtrl.dispose();
    _ptresCtrl.dispose();
    _planoOrcCtrl.dispose();
    super.dispose();
  }

  void _emitChange() {
    final updated = widget.data.copyWith(
      fonteRecurso: _fonteRecursoCtrl.text,
      uo: _uoCtrl.text,
      ug: _ugCtrl.text,
      programa: _programaCtrl.text,
      acao: _acaoCtrl.text,
      ptres: _ptresCtrl.text,
      planoOrc: _planoOrcCtrl.text,
    );
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final itemsFonte = HiringData.fontsRecuros;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(text: '2) Vinculação Programática'),
        LayoutBuilder(
          builder: (context, constraints) {
            final w6 = inputW6(context, constraints);

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w6,
                  child: DropDownButtonChange(
                    enabled: widget.isEditable,
                    labelText: 'Fonte de Recurso',
                    controller: _fonteRecursoCtrl,
                    items: itemsFonte,
                    onChanged: (v) {
                      _fonteRecursoCtrl.text = v ?? '';
                      _emitChange();
                    },
                  ),
                ),
                SizedBox(
                  width: w6,
                  child: CustomTextField(
                    controller: _uoCtrl,
                    labelText: 'Unidade Orçamentária (UO)',
                    enabled: widget.isEditable,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w6,
                  child: CustomTextField(
                    controller: _ugCtrl,
                    labelText: 'UG (Unidade Gestora)',
                    enabled: widget.isEditable,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w6,
                  child: CustomTextField(
                    controller: _programaCtrl,
                    labelText: 'Programa',
                    enabled: widget.isEditable,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w6,
                  child: CustomTextField(
                    controller: _acaoCtrl,
                    labelText: 'Ação',
                    enabled: widget.isEditable,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w6,
                  child: CustomTextField(
                    controller: _ptresCtrl,
                    labelText: 'PTRES/PI/OB (quando aplicável)',
                    enabled: widget.isEditable,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w6,
                  child: CustomTextField(
                    controller: _planoOrcCtrl,
                    labelText: 'Plano Orçamentário (PO)',
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
