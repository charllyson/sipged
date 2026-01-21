// lib/screens/modules/contracts/hiring/3Tr/section_3_local_prazos_cronograma.dart
import 'package:flutter/material.dart';

import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_blocs/modules/contracts/hiring/3Tr/tr_data.dart';

class SectionLocalPrazosCronograma extends StatefulWidget {
  final bool isEditable;
  final TrData data;
  final void Function(TrData updated) onChanged;

  const SectionLocalPrazosCronograma({
    super.key,
    required this.isEditable,
    required this.data,
    required this.onChanged,
  });

  @override
  State<SectionLocalPrazosCronograma> createState() =>
      _SectionLocalPrazosCronogramaState();
}

class _SectionLocalPrazosCronogramaState
    extends State<SectionLocalPrazosCronograma> {
  late final TextEditingController _localCtrl;
  late final TextEditingController _prazoDiasCtrl;
  late final TextEditingController _vigenciaMesesCtrl;
  late final TextEditingController _cronogramaCtrl;

  @override
  void initState() {
    super.initState();
    final d = widget.data;
    _localCtrl = TextEditingController(text: d.localExecucao ?? '');
    _prazoDiasCtrl =
        TextEditingController(text: d.prazoExecucaoDias ?? '');
    _vigenciaMesesCtrl =
        TextEditingController(text: d.vigenciaMeses ?? '');
    _cronogramaCtrl =
        TextEditingController(text: d.cronogramaFisico ?? '');
  }

  @override
  void didUpdateWidget(
      covariant SectionLocalPrazosCronograma oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      final d = widget.data;
      void _sync(TextEditingController c, String? v) {
        final nv = v ?? '';
        if (c.text != nv) c.text = nv;
      }

      _sync(_localCtrl, d.localExecucao);
      _sync(_prazoDiasCtrl, d.prazoExecucaoDias);
      _sync(_vigenciaMesesCtrl, d.vigenciaMeses);
      _sync(_cronogramaCtrl, d.cronogramaFisico);
    }
  }

  @override
  void dispose() {
    _localCtrl.dispose();
    _prazoDiasCtrl.dispose();
    _vigenciaMesesCtrl.dispose();
    _cronogramaCtrl.dispose();
    super.dispose();
  }

  void _emitChange() {
    final updated = widget.data.copyWith(
      localExecucao: _localCtrl.text,
      prazoExecucaoDias: _prazoDiasCtrl.text,
      vigenciaMeses: _vigenciaMesesCtrl.text,
      cronogramaFisico: _cronogramaCtrl.text,
    );
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w4 = inputW4(context, constraints);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(text: '3) Local, Prazos e Cronograma'),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: _localCtrl,
                    labelText: 'Local de execução',
                    enabled: widget.isEditable,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: _prazoDiasCtrl,
                    labelText: 'Prazo de execução (dias)',
                    enabled: widget.isEditable,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: _vigenciaMesesCtrl,
                    labelText: 'Vigência contratual (meses)',
                    enabled: widget.isEditable,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: _cronogramaCtrl,
                    labelText:
                    'Cronograma físico preliminar (marcos/etapas)',
                    maxLines: 1,
                    enabled: widget.isEditable,
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
